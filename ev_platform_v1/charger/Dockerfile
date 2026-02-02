FROM ubuntu:22.04

# Install dependencies for the script
RUN apt-get update && apt-get install -y \
    coreutils \
    sed \
    libwebsockets16 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy all files from the charger directory
COPY . .

# Ensure the script and all device binaries are executable
RUN chmod +x run_all.sh dev*

# Execute the run_all script
CMD ["./run_all.sh"]
