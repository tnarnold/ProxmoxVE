#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pjasicek/OpenClaw

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc git cmake build-essential \
  libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libsdl2-gfx-dev python3
msg_ok "Installed Dependencies"

msg_info "Compiling OpenClaw (This may take a while)"
cd /tmp || exit
git clone --depth 1 https://github.com/pjasicek/OpenClaw.git
cd OpenClaw || exit
mkdir build
cd build || exit
cmake ..
make -j$(nproc)
msg_ok "Compiled OpenClaw"

msg_info "Installing OpenClaw"
mkdir -p /opt/openclaw
cp openclaw /opt/openclaw/
# OpenClaw expects assets in the same dir or specific paths.
# We prepare the directory.
msg_ok "Installed OpenClaw"

msg_info "Cleaning up"
cd /
rm -rf /tmp/OpenClaw
cleanup_lxc
msg_ok "Cleaned"

motd_ssh
customize

msg_info "Important Instructions"
echo -e "${YW}To play the game, you MUST upload the original game assets:${CL}"
echo -e "  1. Upload ${GN}CLAW.REZ${CL} to ${GN}/opt/openclaw/CLAW.REZ${CL}"
echo -e "  2. Upload ${GN}ASSETS.ZIP${CL} to ${GN}/opt/openclaw/ASSETS.ZIP${CL} (optional, from Build_Release/ASSETS if needed)"
echo -e "${YW}Then run the game with:${CL} ${GN}cd /opt/openclaw && ./openclaw${CL}"
