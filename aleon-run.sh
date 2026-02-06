#!/bin/bash

# Setup script to install open-webui in /tmp

# Configure Python to use /tmp for virtual environment
export VENV_DIR=/tmp/open-webui-venv

# Create a virtual environment
python3 -m venv $VENV_DIR

# Activate the virtual environment
source $VENV_DIR/bin/activate

# Install open-webui dependencies
pip install -r /path/to/open-webui/requirements.txt

# Configure npm to install dependencies in /tmp
mkdir -p /tmp/open-webui-npm
cd /path/to/open-webui
npm config set prefix /tmp/open-webui-npm
npm install

# Start the application
npm start