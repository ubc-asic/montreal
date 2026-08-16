#!/bin/sh

# Copyright 2026 Project Montreal contributors.
# SPDX-License-Identifier: CERN-OHL-P-2.0
#
# Author: Warrick Lo <wlo@warricklo.net>
#
# This script sets up the environment for Tiny Tapeout hardening.
#
# Superuser access is required to install packages. The script should
# be run inside of the project directory.

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

mkdir -p "$XDG_DATA_HOME/pdk"

sudo apt install util-linux-extra software-properties-common \
	libffi-dev libqhull-dev libcurl4-openssl-dev libpng-dev \
	librsvg2-bin pngquant docker.io docker-buildx \
	python3-pip pipx python-is-python3

# Install Python 3.11.
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 python3.11-venv

sudo usermod -aG docker "$(whoami)"

# Clone the tt-support-tools repository. Needs to be in
# the 'tt' directory inside the project.
git clone https://github.com/TinyTapeout/tt-support-tools tt

# Patch tt-support-tools to use yowasp-yosys 0.66.
sed -i 's/wasmtime==35.0.0/wasmtime==45.0.0/' tt/requirements.txt
sed -i 's/yowasp-runtime==1.78/yowasp-runtime==1.94/' tt/requirements.txt
sed -i 's/yowasp-yosys==0.55.0.0.post944/yowasp-yosys==0.66.0.0.post1165/' \
	tt/requirements.txt

# Set up virtual environment.
python3.11 -m venv "$XDG_DATA_HOME/tt-support-tools"
. "$XDG_DATA_HOME/tt-support-tools/bin/activate"

pip3.11 install -r tt/requirements.txt
pipx install librelane yowasp-yosys

# Create the user config.
python3.11 tt/tt_tool.py --create-user-config
# Run LibreLane with the docker group.
sg docker -c "python3.11 tt/tt_tool.py --harden"
