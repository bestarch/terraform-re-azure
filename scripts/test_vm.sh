#!/bin/bash
log_file="/install.log"

# Install Redis Cli
install {
  sudo touch $${log_file} && \
  echo "Installing Redis cli..." >> $${log_file}
  sudo apt-get update && \
  sudo apt-get install redis-tools -y && \
  echo "Redis cli installed successfully" >> $${log_file} 
}

main() {
  install
}

# Execute the main function
main