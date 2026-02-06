#!/bin/bash

# Setup script to install open-webui in /tmp

# Configure Python to use /tmp for virtual environment
export VENV_DIR=/tmp/open-webui-venv

# Create a virtual environment
python3 -m venv $VENV_DIR

# Activate the virtual environment
source $VENV_DIR/bin/activate

# Install open-webui dependencies (backend requirements)
if [ -f /workspaces/open-webui/requirements.txt ]; then
	pip install -r /workspaces/open-webui/requirements.txt
elif [ -f /workspaces/open-webui/backend/requirements.txt ]; then
	pip install -r /workspaces/open-webui/backend/requirements.txt
elif [ -f /workspaces/open-webui/backend/requirements-min.txt ]; then
	pip install -r /workspaces/open-webui/backend/requirements-min.txt
else
	echo "WARNING: no requirements file found; skipping pip install"
fi

# Configure npm to install dependencies in /tmp
mkdir -p /tmp/open-webui-npm
cd /workspaces/open-webui
npm config set prefix /tmp/open-webui-npm
# Install node deps allowing older peer deps to avoid @tiptap conflict
npm install --legacy-peer-deps

# Start the application (use `dev` script if `start` is not defined)
if npm run | grep -q " start"; then
	npm start
else
	npm run dev
fi
