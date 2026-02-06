#!/usr/bin/env bash
set -euo pipefail

# Production starter: build frontend to `build/` and run backend (single port)
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

echo "Setting up Python venv and backend dependencies..."
# Ensure Python and backend dependencies are ready (delegate to run-aleon.sh)
if [ -x ./run-aleon.sh ]; then
  bash ./run-aleon.sh setup_python || echo "Warning: Python setup via run-aleon.sh had issues; continuing anyway"
else
  echo "Warning: run-aleon.sh not found; assuming Python/venv is correctly set up"
fi

# Activate the venv if it was just created
if [ -f /tmp/aleon-venv/bin/activate ]; then
  source /tmp/aleon-venv/bin/activate
  export VENV_DIR=/tmp/aleon-venv
fi

echo ""
echo "Building frontend (production)..."
# Ensure Node is properly set up (delegate to run-aleon.sh)
if [ -x ./run-aleon.sh ]; then
  bash ./run-aleon.sh setup_nodejs || echo "Warning: Node setup via run-aleon.sh had issues; continuing anyway"
else
  echo "Warning: run-aleon.sh not found; assuming Node is correctly installed"
fi

# Install dependencies (npm ci enforces engine check; use install with --force for Node v24 workaround)
npm install --legacy-peer-deps --force --no-audit --no-fund
npm run build

echo ""
echo "Starting backend (production) on single port..."
# Export ENV=prod so backend knows it's production
export ENV=prod
# Default port and host
PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"

exec ./backend/start.sh
