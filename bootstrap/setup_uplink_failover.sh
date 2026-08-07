#!/usr/bin/env bash
#
# 上流の転送遮断からの自動復旧（uplink_recover.sh）と証拠ロガー（uplink_watch.sh）を
# systemd サービスとして設置する。
#
# 対象とする障害: リンク・IP・デフォルト経路は正常なのにゲートウェイより先だけが
# 不通になり、L2/DHCP の再アタッチでしか復旧しない型。詳細は各スクリプト冒頭を参照。
#
# 冪等: 何度実行しても安全。設定は /etc/uplink-failover.conf に置かれ、
# 既存ファイルは上書きしない（値は環境ごとに違うため）。
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR=/usr/local/sbin
CONF=/etc/uplink-failover.conf

echo "=== uplink failover setup ==="

echo "--- スクリプト設置 ---"
for s in uplink_recover.sh uplink_watch.sh; do
  sudo install -m 0755 "$SRC_DIR/$s" "$BIN_DIR/$s"
  echo "  $BIN_DIR/$s"
done

echo "--- 設定ファイル ---"
if [ -e "$CONF" ]; then
  echo "  $CONF は既存のため触らない"
else
  # 空にしておけばスクリプト側がデフォルト経路から自動判定する。
  # 副回線を使う場合だけ BACKUP_IFACE を明示すればよい。
  sudo tee "$CONF" >/dev/null <<'EOF'
# uplink_recover.sh / uplink_watch.sh の共通設定。
# 空欄の項目はデフォルト経路から自動判定される。

#PRIMARY_IFACE=
#BACKUP_IFACE=
#GATEWAY=

# off-link 到達性の確認先（外向き ICMP を落とす環境があるため TCP で見る）
#PROBES="1.1.1.1:443 8.8.8.8:443 9.9.9.9:443"

# 段1発火までの連続失敗回数（既定 30s x 6 = 3分）
#FAIL_THRESHOLD=6
# 段1を何回試して駄目なら段2（副回線への退避）へ移るか
#MAX_BOUNCE=2
# 段2で主回線の回復を確認する間隔（秒）
#RETEST_INTERVAL=1800
EOF
  sudo chmod 0644 "$CONF"
  echo "  $CONF を作成"
fi

echo "--- systemd ユニット ---"
for u in uplink-recover uplink-watch; do
  case "$u" in
    uplink-recover) desc="Recover from upstream forwarding blackout"; exe="$BIN_DIR/uplink_recover.sh";;
    uplink-watch)   desc="Log which network layer is failing";        exe="$BIN_DIR/uplink_watch.sh";;
  esac
  sudo tee "/etc/systemd/system/$u.service" >/dev/null <<EOF
[Unit]
Description=$desc
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/env bash $exe
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
  echo "  /etc/systemd/system/$u.service"
done

sudo systemctl daemon-reload
sudo systemctl enable --now uplink-recover.service uplink-watch.service

echo
echo "=== 完了 ==="
systemctl --no-pager --lines=0 status uplink-recover.service uplink-watch.service || true
cat <<'EOF'

NOTE:
  - 副回線（無線等）を使う場合は netplan-dual-uplink.yaml.example を参照して
    2本立てにしておくこと。副回線にデフォルト経路が無いうちは段2に移らず、
    段1（リンクの down/up）だけを試す。
  - ログ:
      sudo tail -f /var/log/uplink-recover.log   # 復旧動作
      sudo tail -f /var/log/uplink-watch.log     # 障害時の層別の証拠
  - 撤去:
      sudo systemctl disable --now uplink-recover uplink-watch
      sudo rm /etc/systemd/system/uplink-{recover,watch}.service /etc/uplink-failover.conf
      sudo rm /usr/local/sbin/uplink_{recover,watch}.sh
      sudo systemctl daemon-reload
EOF
