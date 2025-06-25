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

# Proper SSH setup with privilege separation user
RUN mkdir -p /var/run/sshd && \
    groupadd -r sshd && \
    useradd -r -g sshd -d /nonexistent -s /bin/false sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "root:kaal" | chpasswd

# Install bore.pub
RUN wget -O bore.tar.gz https://github.com/ekzhang/bore/releases/download/v0.5.0/bore-v0.5.0-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf bore.tar.gz && \
    mv bore /usr/local/bin/ && \
    rm bore.tar.gz

# Start script
RUN echo '#!/bin/bash' > /start && \
    echo 'mkdir -p /var/run/sshd' >> /start && \
    echo 'chmod 755 /var/run/sshd' >> /start && \
    echo 'bore local 22 --to bore.pub &' >> /start && \
    echo 'python3 -m http.server ${PORT:-10000} --bind 0.0.0.0 &' >> /start && \
    echo 'exec /usr/sbin/sshd -D -e' >> /start && \
    chmod 755 /start

EXPOSE 22 10000
CMD ["/start"]
