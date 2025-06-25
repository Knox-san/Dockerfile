FROM ubuntu:22.04

# Install dependencies with cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash curl ffmpeg git locales nano python3 python3-pip screen ssh unzip wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up locale and shell
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    ln -sf /bin/bash /bin/sh && \
    echo 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd && \
    mkdir -p /root && chown root:root /root

ENV LANG en_US.utf8

# Proper SSH setup with privilege separation user and host keys
RUN mkdir -p /var/run/sshd /var/log && \
    groupadd -r sshd && \
    useradd -r -g sshd -d /var/empty -s /bin/false sshd && \
    mkdir -p /var/empty && \
    chown root:sys /var/empty && \
    chmod 755 /var/empty && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config && \
    echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config && \
    echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config && \
    echo "LogLevel INFO" >> /etc/ssh/sshd_config && \
    echo "SyslogFacility AUTHPRIV" >> /etc/ssh/sshd_config && \
    echo "LoginGraceTime 120" >> /etc/ssh/sshd_config && \
    echo "StrictModes no" >> /etc/ssh/sshd_config && \
    ssh-keygen -A && \
    echo "root:kaal" | chpasswd

# Install bore.pub
RUN wget -O bore.tar.gz https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf bore.tar.gz && \
    mv bore /usr/local/bin/ && \
    rm bore.tar.gz

# Start script with proper initialization
RUN echo '#!/bin/bash' > /start && \
    echo 'set -e' >> /start && \
    echo 'mkdir -p /var/run/sshd /var/log' >> /start && \
    echo 'chmod 755 /var/run/sshd' >> /start && \
    echo '# Generate host keys if they do not exist' >> /start && \
    echo 'if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then' >> /start && \
    echo '    ssh-keygen -A' >> /start && \
    echo 'fi' >> /start && \
    echo '# Start bore tunnel in background' >> /start && \
    echo 'echo "Starting bore tunnel..."' >> /start && \
    echo 'bore local 22 --to bore.pub &' >> /start && \
    echo 'BORE_PID=$!' >> /start && \
    echo '# Start HTTP server in background' >> /start && \
    echo 'echo "Starting HTTP server on port ${PORT:-10000}..."' >> /start && \
    echo 'python3 -m http.server ${PORT:-10000} --bind 0.0.0.0 &' >> /start && \
    echo 'HTTP_PID=$!' >> /start && \
    echo '# Wait a moment for services to start' >> /start && \
    echo 'sleep 2' >> /start && \
    echo '# Start SSH daemon in foreground' >> /start && \
    echo 'echo "Starting SSH daemon..."' >> /start && \
    echo 'exec /usr/sbin/sshd -D -e' >> /start && \
    chmod 755 /start

EXPOSE 22 10000

CMD ["/start"]
