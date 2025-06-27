FROM ubuntu:22.04

# Install all dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo curl ffmpeg git locales nano python3-pip \
        screen openssh-server unzip wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install Bore
RUN wget -O bore.tar.gz https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf bore.tar.gz && \
    chmod +x bore && \
    rm bore.tar.gz

# Configure SSH
RUN mkdir -p /run/sshd /var/run/sshd && \
    ssh-keygen -A && \
    echo 'Port 22\n\
PermitRootLogin yes\n\
PasswordAuthentication yes\n\
ChallengeResponseAuthentication no\n\
UsePAM yes\n\
X11Forwarding yes\n\
PrintMotd no\n\
AcceptEnv LANG LC_*\n\
Subsystem sftp /usr/lib/openssh/sftp-server\n\
ClientAliveInterval 60\n\
ClientAliveCountMax 3' > /etc/ssh/sshd_config && \
    echo 'root:kaal' | chpasswd

# Startup script that shows Bore connection info
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Start SSH\n\
/usr/sbin/sshd -D &\n\
\n\
# Start Bore tunnel and show connection info\n\
echo "Starting Bore tunnel to bore.pub..."\n\
./bore local 22 --to bore.pub > bore.log 2>&1 &\n\
sleep 3  # Wait for connection\n\
\n\
# Display connection information\n\
echo -e "\n\033[1;36m=== BORE SSH CONNECTION INFO ===\033[0m"\n\
cat bore.log | grep --color=always -E "tunnel established|$"\n\
echo -e "\n\033[1;36mConnect using:\033[0m"\n\
echo -e "\033[1;33mssh root@[bore-address] -p [bore-port]\033[0m"\n\
echo -e "\033[1;36mPassword: kaal\033[0m"\n\
echo -e "\033[1;36m===============================\033[0m\n"\n\
\n\
# Keep container running\n\
tail -f /dev/null' > /start.sh && \
    chmod +x /start.sh

EXPOSE 22
CMD ["/start.sh"]
