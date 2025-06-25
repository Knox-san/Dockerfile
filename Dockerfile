FROM ubuntu:22.04
RUN apt-get -y update && apt-get -y upgrade && apt-get install -y sudo
RUN sudo apt-get install -y curl ffmpeg git locales nano python3-pip screen ssh unzip wget
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash -
RUN sudo apt-get install -y nodejs
ENV LANG en_US.utf8
# Install bore
RUN wget -O bore.tar.gz https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz
RUN tar -xzf bore.tar.gz
RUN chmod +x bore
# Setup SSH
RUN mkdir -p /run/sshd
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config 
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo root:choco|chpasswd
# Create a startup script
RUN echo '#!/bin/bash' > /start
RUN echo 'echo "Starting bore tunnel..."' >> /start
RUN echo './bore local 22 --to bore.pub > bore.log 2>&1 &' >> /start
RUN echo 'sleep 3' >> /start
RUN echo 'echo "=== BORE TUNNEL INFO ==="' >> /start
RUN echo 'cat bore.log' >> /start
RUN echo 'echo "======================="' >> /start
RUN echo '/usr/sbin/sshd' >> /start
# Simple HTTP server to keep the container running and respond to Render's health checks
RUN echo 'python3 -m http.server ${PORT:-8080} --bind 0.0.0.0' >> /start
RUN chmod 755 /start
# Expose ports
EXPOSE 22 80 443 3306 5130 5131 5132 5133 5134 5135 8080 8888
# Set the PORT environment variable with a default value
ENV PORT=8080
CMD ["/start"]
