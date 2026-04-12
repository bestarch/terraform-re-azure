#!/bin/bash


log_info() {
  local file="$1"
  local message="$2"
  echo "$(date -u +'%Y-%m-%d %H:%M:%S') ${message}" >> "${file}"
}

readonly logger="/test_vm.log"

sudo touch $${log_file} && \
log_info "$logger" "Installing Redis cli..."
sudo apt-get update && \
sudo apt-get install redis-tools -y && \
log_info "$logger" "Redis cli installed successfully"
