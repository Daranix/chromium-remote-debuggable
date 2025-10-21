FROM lscr.io/linuxserver/chromium:latest

# Install socat for port forwarding
RUN apt-get update && \
    apt-get install -y socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create startup script that forwards port 9222 to 9223
RUN echo '#!/bin/bash' > /etc/cont-init.d/99-socat && \
    echo 'socat TCP-LISTEN:9223,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:9222 &' >> /etc/cont-init.d/99-socat && \
    chmod +x /etc/cont-init.d/99-socat