FROM ubuntu:22.04

# Install dependencies with cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash curl ffmpeg git locales nano openssh-server python3 python3-pip screen unzip wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up proper shell environment
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    ln -sf /bin/bash /bin/sh && \
    mkdir -p /root && \
    chown root:root /root && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo 'export TERM=xterm' >> /root/.bashrc && \
    echo 'cd ~' >> /root/.bashrc && \
    echo 'echo "Welcome to SSH session"' >> /root/.bashrc

ENV LANG en_US.utf8

# Configure SSH properly
RUN mkdir -p /var/run/sshd && \
    groupadd -r sshd && \
    useradd -r -g sshd -d /nonexistent -s /bin/false sshd && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "root:kaal" | chpasswd

# Install bore.pub
RUN wget -O bore.tar.gz https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf bore.tar.gz && \
    mv bore /usr/local/bin/ && \
    rm bore.tar.gz

# Start script with proper environment
RUN echo '#!/bin/bash' > /start && \
    echo 'mkdir -p /var/run/sshd' >> /start && \
    echo 'chmod 755 /var/run/sshd' >> /start && \
    echo 'bore local 22 --to bore.pub &' >> /start && \
    echo 'python3 -m http.server ${PORT:-10000} --bind 0.0.0.0 &' >> /start && \
    echo 'exec /usr/sbin/sshd -D -e' >> /start && \
    chmod 755 /start

EXPOSE 22 10000
CMD ["/start"]
