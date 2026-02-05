#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pjasicek/OpenClaw

APP="OpenClaw"
var_tags="game"
var_cpu="1"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/openclaw ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} (Recompiling)"
  apt-get update
  apt-get install -y git cmake build-essential libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libsdl2-gfx-dev
  
  cd /tmp
  rm -rf OpenClaw
  git clone https://github.com/pjasicek/OpenClaw.git
  cd OpenClaw
  mkdir build
  cd build
  cmake ..
  make
  
  msg_info "Stopping any running instances (if applicable)"
  # No service by default, but good practice to kill if running manual
  pkill -f openclaw || true

  cp -f openclaw /opt/openclaw/openclaw
  msg_ok "Updated successfully"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} You must manually upload CLAW.REZ and ASSETS.ZIP to /opt/openclaw${CL}"
echo -e "${INFO}${YW} Run the game with: /opt/openclaw/openclaw${CL}"
