#!/bin/bash

# Detect if script is being sourced (dot) or executed (POSIX-safe)
sourced=0
# `return` succeeds only when script is sourced; run in subshell to test
if (return 0 2>/dev/null); then
	sourced=1
fi

# If not running under bash, re-exec under bash unless sourced
if [ "$sourced" -eq 0 ] && [ -z "${BASH_VERSION:-}" ]; then
	if command -v bash >/dev/null 2>&1; then
		# When invoked as `sh script.sh` the positional parameters differ
		# If $0 is a file, use it; otherwise the script path is $1
		if [ -f "$0" ]; then
			exec bash "$0" "$@"
		else
			script="$1"
			shift || true
			exec bash "$script" "$@"
		fi
	else
		echo "Warning: bash not found; continuing with sh (pipefail disabled)"
		set -eu
	fi
fi

set -euo pipefail

# Common env vars and npm prefix
TMP_NPM_DIR=/tmp/open-webui-npm
export TMP_NPM_DIR
export VENV_DIR=/tmp/open-webui-venv

# If sourced, only export variables and set npm prefix so external callers
# can reuse the same env; do not perform installations or start the app.
if [ "$sourced" -eq 1 ]; then
	mkdir -p "$TMP_NPM_DIR"
	npm config set prefix "$TMP_NPM_DIR" || true
	echo "aleon.sh sourced: exported TMP_NPM_DIR=$TMP_NPM_DIR and VENV_DIR=$VENV_DIR"
	return 0 2>/dev/null || exit 0
fi

# Executed directly: run full setup and launcher
chmod +x aleon-run.sh

mkdir -p "$TMP_NPM_DIR"
cd "$(dirname "$0")"

# Ensure npm uses /tmp prefix for global installs (and where binaries go)
npm config set prefix "$TMP_NPM_DIR"
# Override engine-strict check for Node v24 (workaround until v20 installed)
npm config set engine-strict false || true

# Delegate node installation/validation to `run-aleon.sh` (centralized)
ensure_node() {
	if command -v node >/dev/null 2>&1; then
		NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
	else
		NODE_MAJOR=0
	fi

	if [ "$NODE_MAJOR" -eq 0 ] || [ "$NODE_MAJOR" -lt 18 ] || [ "$NODE_MAJOR" -gt 22 ]; then
		echo "Node not present or version unsupported (found: $(node -v 2>/dev/null || echo 'none')). Delegating setup to run-aleon.sh"
		if [ -x ./run-aleon.sh ]; then
			bash ./run-aleon.sh setup_nodejs || echo "run-aleon.sh failed to setup node; you may need to install node 18..22 manually"
		else
			echo "run-aleon.sh not found or not executable; please install Node 18..22 manually"
		fi
	else
		echo "Node version $(node -v) is within supported range"
	fi
}

# Ensure Node is ready (best effort)
ensure_node || true

# Install node deps into project using the /tmp prefix
if [ -d node_modules ] || [ -d "$TMP_NPM_DIR/lib/node_modules" ]; then
	echo "Node packages already installed; skipping npm install"
else
	npm install --legacy-peer-deps --force
fi

# Run main installer/launcher
./aleon-run.sh
