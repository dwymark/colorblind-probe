#!/usr/bin/env bash
# Usage: ./deploy.sh <user@host> [port]
set -euo pipefail

TARGET="${1:?Usage: $0 <user@host> [port]}"
PORT="${2:-8000}"
REMOTE_DIR="/opt/colorblind-probe"
SERVICE="colorblind-probe"
SERVICE_FILE="${SERVICE}.service"

# Rewrite the service file with the chosen port and upload via sudo tee
sed "s/8000/$PORT/" "$SERVICE_FILE" | ssh "$TARGET" "sudo tee /etc/systemd/system/$SERVICE_FILE > /dev/null"

ssh "$TARGET" "sudo mkdir -p $REMOTE_DIR && sudo chown www-data:www-data $REMOTE_DIR"

# scp to a temp path (writable by SSH user), then sudo move into place
scp index.html "$TARGET:/tmp/colorblind-probe-index.html"

ssh "$TARGET" bash -s <<EOF
  set -euo pipefail
  sudo mv /tmp/colorblind-probe-index.html $REMOTE_DIR/index.html
  sudo chown www-data:www-data $REMOTE_DIR/index.html
  sudo chmod 644 $REMOTE_DIR/index.html
  sudo systemctl daemon-reload
  sudo systemctl enable --now $SERVICE_FILE
  sudo systemctl restart $SERVICE
  sudo systemctl status $SERVICE --no-pager
EOF

echo "Deployed to $TARGET on port $PORT"
