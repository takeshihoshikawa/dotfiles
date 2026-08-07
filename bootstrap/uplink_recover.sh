#!/usr/bin/env bash
#
# 「リンクは生きているのに上流が転送してくれない」型の障害からの自動復旧デーモン。
#
# 想定する障害の署名:
#   - キャリアは UP、IP アドレスもデフォルト経路も保持されたまま
#   - ゲートウェイまでは ping が通る（同一セグメントは正常）
#   - にもかかわらずゲートウェイより先が全滅（off-link 宛が EHOSTUNREACH / timeout）
#   - ネットワーク管理デーモンは異常を検知しないため何のログも出さない
#   - L2/DHCP を再アタッチする（ケーブル抜き差し等）と復旧する
#
# この形の障害では「リンクが生きて見える」ため、経路メトリックによる自動
# フェイルオーバは働かない。副回線へ逃がすには主回線を明示的に落とす必要がある。
#
# 二段構え:
#   段1  主回線のリンクを down/up する（＝抜き差し相当）
#   段2  それでも直らなければ主回線を down のまま保持し、副回線へ退避する。
#        一定間隔で主回線を上げ直して回復を確認し、直っていれば戻る
#
# 設定は /etc/uplink-failover.conf（無ければデフォルト経路から自動判定）。
set -uo pipefail

CONF="${UPLINK_CONF:-/etc/uplink-failover.conf}"
# shellcheck disable=SC1090
[ -r "$CONF" ] && . "$CONF"

# --- 設定（conf または env で上書き可） ---------------------------------------
PRIMARY_IFACE="${PRIMARY_IFACE:-}"     # 主回線。空ならデフォルト経路から自動判定
BACKUP_IFACE="${BACKUP_IFACE:-}"       # 副回線。空なら段2を行わない
GATEWAY="${GATEWAY:-}"                 # 主回線のGW。空なら自動判定
PROBES="${PROBES:-1.1.1.1:443 8.8.8.8:443 9.9.9.9:443}"   # off-link 到達性の確認先
INTERVAL="${INTERVAL:-30}"             # 判定間隔（秒）
FAIL_THRESHOLD="${FAIL_THRESHOLD:-6}"  # 連続失敗回数。既定は 30s x 6 = 3分で段1発火
BOUNCE_WAIT="${BOUNCE_WAIT:-60}"       # bounce 後に復旧を待つ秒数
MAX_BOUNCE="${MAX_BOUNCE:-2}"          # 段1を何回試して駄目なら段2へ移るか
RETEST_INTERVAL="${RETEST_INTERVAL:-1800}"  # 段2で主回線の回復を確認する間隔（秒）
LOG="${LOG:-/var/log/uplink-recover.log}"
# -----------------------------------------------------------------------------

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') $*" >> "$LOG"; }

# 外向き ICMP を落とすネットワークが珍しくないため、到達性判定は TCP で行う
offlink_alive() {
  local p
  for p in $PROBES; do
    timeout 4 bash -c "</dev/tcp/${p%:*}/${p#*:}" 2>/dev/null && return 0
  done
  return 1
}

autodetect() {
  local line
  if [ -z "$PRIMARY_IFACE" ] || [ -z "$GATEWAY" ]; then
    line=$(ip route show default | head -1)
    [ -z "$PRIMARY_IFACE" ] && PRIMARY_IFACE=$(awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' <<<"$line")
    [ -z "$GATEWAY" ]       && GATEWAY=$(awk '{for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}' <<<"$line")
  fi
  if [ -z "$BACKUP_IFACE" ]; then
    BACKUP_IFACE=$(ip route show default | awk -v p="$PRIMARY_IFACE" \
      '{for(i=1;i<=NF;i++) if($i=="dev" && $(i+1)!=p) print $(i+1)}' | head -1)
  fi
}

# 障害の署名に合致するか。合致しない異常（本当の断線・IP喪失）では何もしない
blackout_signature() {
  [ "$(cat "/sys/class/net/$PRIMARY_IFACE/carrier" 2>/dev/null)" = "1" ] || return 1
  ip -4 -br addr show "$PRIMARY_IFACE" | grep -q '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/' || return 1
  ip route show default dev "$PRIMARY_IFACE" | grep -q . || return 1
  ping -c1 -W2 "$GATEWAY" >/dev/null 2>&1 || return 1
  ! offlink_alive
}

backup_usable() {
  [ -n "$BACKUP_IFACE" ] && ip route show default dev "$BACKUP_IFACE" 2>/dev/null | grep -q .
}

wait_recovery() {
  local i
  for i in $(seq 1 $((BOUNCE_WAIT / 2))); do
    sleep 2
    offlink_alive && { log "  -> 復旧 ($((i * 2))s)"; return 0; }
  done
  return 1
}

autodetect
if [ -z "$PRIMARY_IFACE" ] || [ -z "$GATEWAY" ]; then
  log "起動中止: 主回線を特定できない（PRIMARY_IFACE/GATEWAY を $CONF に書くこと）"
  exit 1
fi
log "started (primary=$PRIMARY_IFACE backup=${BACKUP_IFACE:-none} gw=$GATEWAY)"

fails=0
bounces=0
failover=0
failover_since=0

while true; do
  sleep "$INTERVAL"

  # --- 段2: 主回線を落として副回線で凌いでいる状態 ---
  if [ "$failover" -eq 1 ]; then
    [ $(( $(date +%s) - failover_since )) -lt "$RETEST_INTERVAL" ] && continue
    log "主回線の回復を確認する"
    ip link set "$PRIMARY_IFACE" up
    if wait_recovery; then
      log "=== 主回線が回復。通常運用へ戻る ==="
      failover=0; fails=0; bounces=0
    else
      log "  -> まだ遮断中。主回線を落として副回線での退避を継続"
      ip link set "$PRIMARY_IFACE" down
      failover_since=$(date +%s)
    fi
    continue
  fi

  # --- 通常監視 ---
  if ! blackout_signature; then
    [ "$fails" -gt 0 ] && log "自然復旧（連続失敗 ${fails} 回で終了）"
    fails=0; bounces=0
    continue
  fi

  fails=$((fails + 1))
  log "off-link 不通 (${fails}/${FAIL_THRESHOLD}) carrier=up gw=ok neigh=[$(ip neigh show "$GATEWAY")]"
  [ "$fails" -lt "$FAIL_THRESHOLD" ] && continue

  bounces=$((bounces + 1))
  log "=== 段1: link bounce 実行 (${bounces}/${MAX_BOUNCE}) ==="
  ip link set "$PRIMARY_IFACE" down; sleep 5; ip link set "$PRIMARY_IFACE" up
  fails=0
  wait_recovery && { bounces=0; continue; }

  [ "$bounces" -lt "$MAX_BOUNCE" ] && continue

  if backup_usable; then
    log "=== 段2: 主回線を落として $BACKUP_IFACE へ退避する ==="
    ip link set "$PRIMARY_IFACE" down
    failover=1
    failover_since=$(date +%s)
  else
    log "=== 段2に移れない: 副回線にデフォルト経路がない。主回線のまま監視を続ける ==="
    bounces=0
  fi
done
