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

set -e

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

cat << EOF >> "$HOME/.profile"

# SkyWater 130 nm PDK.
export PDK_ROOT="$XDG_DATA_HOME/pdk"
export PDK="sky130A"
EOF

# shellcheck source=/dev/null
. "$HOME/.profile"

mkdir -p "$PDK_ROOT"

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
# shellcheck source=/dev/null
. "$XDG_DATA_HOME/tt-support-tools/bin/activate"

pip3.11 install -r tt/requirements.txt
pipx install librelane yowasp-yosys

# Create the user config.
python3.11 tt/tt_tool.py --create-user-config
# Run LibreLane with the docker group.
sg docker -c "python3.11 tt/tt_tool.py --harden"

printf "\n=================================================================\n\n"
printf "%s: Setup has finished\n" "$0"

printf "\n=================================================================\n\n"
printf "Before running tt_tool.py, activate the environment by running\n"
printf "\t%s/tt-support-tools/bin/activate\n\n" "$XDG_DATA_HOME"
printf "If this is your first time running the script, please log out of\n"
printf "this shell session and relogin.\n\n"
printf "To regenerate the LibreLane configuration file, run:\n"
printf "\tpython3.11 tt/tt_tool.py --create-user-config\n\n"
printf "To reharden, run:\n"
printf "\tpython3.11 tt/tt_tool.py --harden\n\n"
