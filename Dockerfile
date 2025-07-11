FROM debian:stable-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y proftpd-basic python3 jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create directories
RUN mkdir -p /etc/container-config /run/secret

# Default config file copy
COPY proftpd.conf /etc/proftpd/proftpd.conf

EXPOSE 21

ENTRYPOINT ["/entrypoint.sh"]
