#!/usr/bin/env bash
#
# ネットワーク障害の「層」を切り分けるための証拠ロガー。
#
# 体感の「ネットが切れる」は、L1（リンク断）・L3（経路・上流の転送遮断）・DNS の
# どれでも同じに見える。事後に journal から再構成するのは手間なので、10秒間隔で
# 各層を個別に確認し、失敗したときだけ記録する（正常時は1時間ごとに heartbeat）。
#
# 失敗時は GW の ARP 状態・デフォルト経路・IP も併記する。
# 「GW は REACHABLE でデフォルト経路もあるのに off-link だけ死ぬ」が残れば、
# それは自ホストではなく上流側の問題だと確定でき、そのままIT窓口への材料になる。
#
# 設定は /etc/uplink-failover.conf（uplink_recover.sh と共用）。
set -uo pipefail

CONF="${UPLINK_CONF:-/etc/uplink-failover.conf}"
# shellcheck disable=SC1090
[ -r "$CONF" ] && . "$CONF"

PRIMARY_IFACE="${PRIMARY_IFACE:-}"
GATEWAY="${GATEWAY:-}"
PROBES="${PROBES:-1.1.1.1:443 8.8.8.8:443 9.9.9.9:443}"
RESOLVE_NAME="${RESOLVE_NAME:-www.debian.org}"   # 名前解決の実地確認に使う外部ドメイン
WATCH_INTERVAL="${WATCH_INTERVAL:-10}"
HEARTBEAT="${HEARTBEAT:-3600}"
WATCH_LOG="${WATCH_LOG:-/var/log/uplink-watch.log}"

line=$(ip route show default | head -1)
[ -z "$PRIMARY_IFACE" ] && PRIMARY_IFACE=$(awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' <<<"$line")
[ -z "$GATEWAY" ]       && GATEWAY=$(awk '{for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}' <<<"$line")

# 上流の DNS は resolved が握っているものをそのまま使う（環境固有値を持たないため）
dns_servers() {
  resolvectl status "$PRIMARY_IFACE" 2>/dev/null |
    awk -F': ' '/DNS Servers/{print $2; exit}'
}

last_beat=0
while true; do
  sleep "$WATCH_INTERVAL"
  now=$(date '+%Y-%m-%dT%H:%M:%S')
  fail=""

  ip link show "$PRIMARY_IFACE" | grep -q LOWER_UP || fail+=" LINK_DOWN"
  ping -c1 -W2 "$GATEWAY" >/dev/null 2>&1 || fail+=" GW_UNREACH"

  # 外向き ICMP を落とすネットワークが珍しくないため、外部到達性は TCP で見る
  alive=1
  for p in $PROBES; do
    timeout 4 bash -c "</dev/tcp/${p%:*}/${p#*:}" 2>/dev/null && { alive=0; break; }
  done
  [ "$alive" -eq 0 ] || fail+=" INET_UNREACH"

  for s in $(dns_servers); do
    case "$s" in *:*) continue;; esac   # IPv6 はスキップ
    dig +time=2 +tries=1 "@$s" "$RESOLVE_NAME" A +short >/dev/null 2>&1 || fail+=" DNS_FAIL($s)"
  done
  # --cache=no にしないと resolved のキャッシュに隠されて障害を取り逃がす
  timeout 6 resolvectl query --cache=no "$RESOLVE_NAME" >/dev/null 2>&1 || fail+=" RESOLVED_FAIL"

  if [ -n "$fail" ]; then
    cur=$(resolvectl status "$PRIMARY_IFACE" 2>/dev/null | awk -F': ' '/Current DNS Server/{print $2}')
    {
      echo "$now FAIL:$fail (resolved=$cur)"
      echo "  neigh: $(ip neigh show "$GATEWAY")"
      echo "  route: $(ip route show default)"
      echo "  addr:  $(ip -br addr show "$PRIMARY_IFACE")"
    } >> "$WATCH_LOG"
  elif [ $(( $(date +%s) - last_beat )) -ge "$HEARTBEAT" ]; then
    echo "$now ok" >> "$WATCH_LOG"
    last_beat=$(date +%s)
  fi
done
