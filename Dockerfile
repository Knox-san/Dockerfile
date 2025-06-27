FROM ubuntu:22.04

# Install all dependencies with cleanup
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

# Configure SSH (using existing sshd user)
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
    echo 'root:choco' | chpasswd

# Startup script
RUN echo '#!/bin/sh\n\
set -e\n\
/usr/sbin/sshd -D &\n\
./bore local 22 --to bore.pub > bore.log 2>&1 &\n\
tail -f /dev/null' > /start.sh && \
    chmod +x /start.sh

EXPOSE 22
CMD ["/start.sh"]
