# Use a specific version of Ubuntu as the base image
FROM ubuntu:22.04

# Set environment variables to make installation non-interactive and set timezone
ENV DEBIAN_FRONTEND=noninteractive \
    TZ="Etc/UTC" \
    PATH="/root/.local/bin/:$PATH"

# Combine all apt-get related commands to reduce layers and avoid multiple updates
RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-dev \
        python3-pip \
        postgresql-client \
        software-properties-common \
        build-essential \
        cmake \
        tzdata \
        ffmpeg \
        curl \
        unzip \
        git && \
    # Add the PPA and install audiowaveform
    add-apt-repository ppa:chris-needham/ppa && \
    apt-get update && \
    apt-get install -y audiowaveform && \
    # Install UV
    curl -sSL https://astral.sh/uv/install.sh -o /uv-installer.sh && \
    sh /uv-installer.sh && \
    rm /uv-installer.sh && \
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs && \
    # Clean up to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy and install Python dependencies first to leverage caching
COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Copy package.json and package-lock.json separately to cache npm install
COPY package*.json ./
RUN npm ci

# Now copy the rest of the application code
COPY . .

# Build the frontend application
RUN npm run build

# Copy the entrypoint script and ensure it has execute permissions
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set NODE_ENV to production after building to avoid installing dev dependencies
ENV NODE_ENV=production

# Expose the desired port
EXPOSE 3000

# Define the default command
CMD ["/usr/local/bin/docker-entrypoint.sh"]