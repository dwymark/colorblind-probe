#!/usr/bin/env bash
# Usage: ./deploy.sh <user@host> [port]
set -euo pipefail

TARGET="${1:?Usage: $0 <user@host> [port]}"
PORT="${2:-8000}"
REMOTE_DIR="/opt/colorblind-probe"
SERVICE="colorblind-probe"
SERVICE_FILE="${SERVICE}.service"

# Rewrite the service file with the chosen port before uploading
sed "s/8000/$PORT/" "$SERVICE_FILE" | ssh "$TARGET" bash -c "
  sudo tee /etc/systemd/system/$SERVICE_FILE > /dev/null
"

ssh "$TARGET" bash -s <<EOF
  set -euo pipefail
  sudo mkdir -p $REMOTE_DIR
  sudo chown www-data:www-data $REMOTE_DIR
EOF

scp index.html "$TARGET:$REMOTE_DIR/index.html"

ssh "$TARGET" bash -s <<EOF
  set -euo pipefail
  sudo chmod 644 $REMOTE_DIR/index.html
  sudo systemctl daemon-reload
  sudo systemctl enable --now $SERVICE_FILE
  sudo systemctl restart $SERVICE
  sudo systemctl status $SERVICE --no-pager
EOF

echo "Deployed to $TARGET on port $PORT"
