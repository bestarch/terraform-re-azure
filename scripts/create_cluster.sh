#!/bin/bash
log_file="/startup.log"

# Log debugging variables
log_debug_info() {
  echo "Debugging Variables:" > $${log_file}
  echo "Redis Tar file location: ${redis_tar_file_location}" >> $${log_file}
  echo "Redis Cluster Admin: ${cluster_admin_username}" >> $${log_file}
  echo "Redis Cluster Password: ${cluster_admin_password}" >> $${log_file}
  echo "First Node Internal IP: ${first_node_internal_ip}" >> $${log_file}
  echo "Node External IPs: ${node_external_ips}" >> $${log_file}
  echo "Redis Cluster FQDN: ${cluster_name}" >> $${log_file}
  echo "Enable public IP address for nodes ${enable_public_ip}" >> $${log_file}
  echo "Create DR cluster : ${create_dr_cluster}" >> $${log_file}
}

# Install Redis
install_redis() {
  echo "Installing Redis..." >> $${log_file}
  sudo yum install wget dnsutils net-tools -y && \
  echo "net.ipv4.ip_local_port_range = 30000 65535" | sudo tee -a /etc/sysctl.conf && \
  echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf && \
  sudo mv /etc/resolv.conf /etc/resolv.conf.orig && \
  sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf && \
  sudo service systemd-resolved restart && \
  sudo wget -O "/opt/redis_enterprise" "${redis_tar_file_location}" && \
  sudo tar -xvf "/opt/redis_enterprise" -C /opt/ && \
  cd /opt && \
  sudo ./install.sh -y 
  #rm /opt/redis_enterprise && \
  #sudo usermod -aG redislabs ${redis_user}
}

# Wait for Redis services to start
wait_for_services() {
  echo "Checking node bootstrap status and address..." >> $${log_file}
  echo "curl: https://${first_node_internal_ip}:9443/v1/bootstrap" >> $${log_file}
  while true; do
    # Get the JSON response
    response=$(curl -s -k -u "${cluster_admin_username}:${cluster_admin_password}" https://${first_node_internal_ip}:9443/v1/bootstrap)
    echo "Reponse: $${response}" >> $${log_file}
    
    # Parse the JSON to check for state and address
    state_idle=$(echo "$${response}" | jq -e '.bootstrap_status.state == "idle"' 2>/dev/null)
    address_available=$(echo "$${response}" | jq -e '.local_node_info.available_addresses[] | select(.address == "${first_node_internal_ip}")' 2>/dev/null)

    if [[ "$${state_idle}" == "true" && -n "$${address_available}" ]]; then
      echo "Node bootstrap is completed and address ${first_node_internal_ip} is available." >> $${log_file}
      break
    else
      echo "Bootstrap state or address not ready. Retrying in 5 seconds..." >> $${log_file}
    fi
    sleep 5
  done
}


# Create Redis cluster
create_redis_cluster() {
  echo "Creating Redis cluster:" >> $${log_file}
  if [[ "${enable_public_ip}" == "true" ]]; then
    echo "sudo /opt/redislabs/bin/rladmin cluster create addr ${node_internal_ip} \
      external_addr ${node_external_ips} \
      name ${cluster_name} register_dns_suffix \
      username ${cluster_admin_username} password '\"${cluster_admin_password}\"'" >> $${log_file}

    sudo /opt/redislabs/bin/rladmin cluster create addr ${node_internal_ip} \
      external_addr ${node_external_ips} \
      name ${cluster_name} register_dns_suffix \
      username ${cluster_admin_username} password ${cluster_admin_password}
  else
    echo "sudo /opt/redislabs/bin/rladmin cluster create addr ${node_internal_ip} \
      name ${cluster_name} register_dns_suffix \
      username ${cluster_admin_username} password '\"${cluster_admin_password}\"'" >> $${log_file}

    sudo /opt/redislabs/bin/rladmin cluster create addr ${node_internal_ip} \
      name ${cluster_name} register_dns_suffix \
      username ${cluster_admin_username} password ${cluster_admin_password}
  fi
  
  echo "Cluster created." >> $${log_file}
}

# Main function
main() {
  log_debug_info
  install_redis
  wait_for_services
  create_redis_cluster
}

# Execute the main function
main
