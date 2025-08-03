# Pure Bliss Frontend Dockerfile
FROM node:20-slim

# Install required system dependencies for React Native
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk android-sdk adb git python3 make g++ && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json* yarn.lock* ./
RUN npm install --legacy-peer-deps || yarn install --frozen-lockfile
RUN npm install expo json-server --legacy-peer-deps

# Copy the rest of the app
COPY . .

# Expose Metro bundler port
EXPOSE 8081

# Default command: start static (expo web)
CMD ["npm", "run", "static"]
