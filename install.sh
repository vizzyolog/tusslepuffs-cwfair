#!/bin/bash
# Tusslepuffs self-host installer.
# Usage: sudo ./install.sh [install-dir]   (default: /opt/tusslepuffs)
set -euo pipefail

PREFIX="${1:-/opt/tusslepuffs}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script installs systemd units and needs root. Re-run with sudo." >&2
    exit 1
fi

echo "Installing Tusslepuffs to $PREFIX ..."
mkdir -p "$PREFIX"
cp -r "$SCRIPT_DIR/server" "$SCRIPT_DIR/rapier-server" "$SCRIPT_DIR/dist" "$PREFIX/"
chmod +x "$PREFIX/server" "$PREFIX/rapier-server"

if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    cp "$SCRIPT_DIR/config.env" "$PREFIX/config.env"
else
    cp "$SCRIPT_DIR/config.example.env" "$PREFIX/config.env"
    echo "Created $PREFIX/config.env from the example — review it before going live."
fi

install -m 0644 "$SCRIPT_DIR/deploy/tusslepuffs-rapier.service" /etc/systemd/system/tusslepuffs-rapier.service
install -m 0644 "$SCRIPT_DIR/deploy/tusslepuffs-backend.service" /etc/systemd/system/tusslepuffs-backend.service

systemctl daemon-reload
systemctl enable --now tusslepuffs-rapier
systemctl enable --now tusslepuffs-backend

cat <<EOF

Tusslepuffs installed.

  Backend:        http://localhost:8181
  Physics health: http://localhost:50053/health
  Logs:           journalctl -u tusslepuffs-backend -f

To put nginx in front, adapt deploy/nginx.example.conf to your domain.
EOF
