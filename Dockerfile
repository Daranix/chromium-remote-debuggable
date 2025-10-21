FROM lscr.io/linuxserver/chromium:latest

# Install socat for port forwarding
RUN apt-get update && \
    apt-get install -y socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a startup script
RUN echo '#!/bin/bash' > /custom-init.sh && \
    echo 'socat TCP-LISTEN:9223,fork,reuseaddr TCP:127.0.0.1:9222 &' >> /custom-init.sh && \
    echo 'exec /init' >> /custom-init.sh && \
    chmod +x /custom-init.sh

ENTRYPOINT ["/custom-init.sh"]