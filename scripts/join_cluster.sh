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
  echo "Time Zone: ${time_zone}" >> $${log_file}
  echo "Join cluster : ${create_cluster}" >> $${log_file}
}

# Install Redis
install_redis() {
#  echo "Setting time zone..." >> $${log_file} && \
#  sudo timedatectl set-timezone "${time_zone}" && \
#  timedatectl >> $${log_file} && \
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
  echo "Curl: https://${first_node_internal_ip}:9443/v1/bootstrap" >> $${log_file}
  while true; do
    # Get the JSON response
    response=$(curl -s -k -u "${cluster_admin_username}:${cluster_admin_password}" https://${first_node_internal_ip}:9443/v1/bootstrap)
    echo "Reponse: $${response}" >> $${log_file}
    
    # Parse the JSON to check for state and address
    state_completed=$(echo "$${response}" | jq -e '.bootstrap_status.state == "completed"' 2>/dev/null)
    address_present=$(echo "$${response}" | jq -e '.local_node_info.available_addresses[] | select(.address == "${first_node_internal_ip}")' 2>/dev/null)

    if [[ "$${state_completed}" == "true" && -n "$${address_present}" ]]; then
      echo "Node bootstrap is completed and address ${first_node_internal_ip} is available." >> $${log_file}
      break
    else
      echo "Bootstrap state or address not ready. Retrying in 5 seconds..." >> $${log_file}
    fi
    sleep 5
  done
}


# Create Redis cluster
join_redis_cluster() {
  echo "Waiting for Master node to create Redis Cluster..." >> $${log_file}
  URL="https://${first_node_internal_ip}:9443/v1/cluster/check"
  CREDENTIALS="${cluster_admin_username}:${cluster_admin_password}"

  while true; do
    # Send the curl request and store the response
    RESPONSE=$(curl -s -k -u "$CREDENTIALS" "$URL")
    echo "$RESPONSE" >> $${log_file}

    # Check if the response contains the expected JSON structure
    if echo "$RESPONSE" | jq -e '.cluster_test_result == true and .nodes[0].node_uid == 1 and .nodes[0].result == true' > /dev/null 2>&1; then
      echo "Joining cluster..." >> $${log_file}
      echo "sudo /opt/redislabs/bin/rladmin cluster join nodes ${first_node_internal_ip} \
            external_addr ${node_external_ips} \
            username ${cluster_admin_username} password '\"${cluster_admin_password}\"'" >> $${log_file}

      sudo /opt/redislabs/bin/rladmin cluster join nodes ${first_node_internal_ip} \
            external_addr ${node_external_ips} \
            username ${cluster_admin_username} password ${cluster_admin_password} >> $${log_file} 2>&1
      break
    else
      echo "Master node is not ready. Retrying in 3 seconds..." >> $${log_file}
    fi

    # Wait for 3 seconds before retrying
    sleep 3
  done
  echo "Cluster joined." >> $${log_file}
}

# Main function to orchestrate the script execution
main() {
  log_debug_info
  install_redis
  wait_for_services
  join_redis_cluster
}

# Execute the main function
main
