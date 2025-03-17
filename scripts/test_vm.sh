#!/bin/bash
log_file="/install.log"

# Install Redis Cli
install {
  sudo touch $${log_file} && \
  echo "Installing Redis cli..." >> $${log_file}
  sudo apt-get update && \
  sudo apt-get install redis-tools -y && \
  echo "Redis cli installed successfully" >> $${log_file} 
  # To get the health of the cluster
  #curl -s -k -u admin@example.com:admin https://10.0.0.4:9443/v1/bootstrap
}

main() {
  install
}

# Execute the main function
main