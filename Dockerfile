FROM ubuntu:22.04

# Install all dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y sudo curl ffmpeg git locales nano python3-pip screen ssh unzip wget nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash -

# Install Bore
RUN wget -O bore.tar.gz https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    tar -xzf bore.tar.gz && \
    chmod +x bore

# Setup SSH
RUN mkdir -p /run/sshd && \
    ssh-keygen -A && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'root:choco' | chpasswd

# Startup script
RUN echo '#!/bin/bash\n\
service ssh start\n\
./bore local 22 --to bore.pub > bore.log 2>&1 &\n\
tail -f /dev/null' > /start.sh && \
    chmod +x /start.sh

EXPOSE 22
CMD ["/start.sh"]
