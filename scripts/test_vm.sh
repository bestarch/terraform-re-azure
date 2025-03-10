#!/bin/bash
log_file="/install.log"

# Install Redis Cli & Docker
install {
  sudo touch $${log_file} && \
  echo "Installing Redis cli..." >> $${log_file}
  sudo yum update -y && \
  wget http://download.redis.io/redis-stable.tar.gz && \
  tar xvzf redis-stable.tar.gz && \
  cd redis-stable && \
  make redis-cli && \
  sudo cp src/redis-cli /usr/local/bin/ && \
  echo "Redis cli installed successfully" >> $${log_file} && \

  sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms && \
  sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
  sudo dnf install pass -y && \
  



  sudo dnf install -y redis-tools && \
  echo "Redis cli installed successfully" >> $${log_file} && \
  sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
  sudo dnf install -y docker-ce docker-ce-cli containerd.io && \
  sudo dnf install -y docker-ce --allowerasing && \
  sudo systemctl start docker && \
  sudo systemctl enable docker && \
  echo "Docker installed successfully" >> $${log_file}
}

main() {
  install
}

# Execute the main function
main