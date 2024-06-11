# Stage 1: Build the Dart application
FROM debian:buster-slim as build

# Set the Dart version
ARG DART_VERSION=3.4.1

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Download and install Dart SDK
RUN curl -sSL https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip -o dart-sdk.zip && \
    unzip dart-sdk.zip -d /usr/local && \
    rm dart-sdk.zip

# Update PATH
ENV PATH="$PATH:/usr/local/dart-sdk/bin"

# Set working directory
WORKDIR /build

# Copy the application source code
COPY . .

# Get Dart dependencies
RUN dart pub get

# Compile the Dart application
RUN dart compile exe bin/copilot_proxy.dart -o ./copilot_proxy_linux

# Stage 2: Create the runtime image
FROM debian:buster-slim

# Create directory for the application
RUN mkdir /app

# Copy the compiled Dart application from the build stage
COPY --from=build /build/copilot_proxy_linux /app/copilot_proxy_linux

# Set the working directory for the application
WORKDIR /config

# Define the entrypoint
ENTRYPOINT ["/app/copilot_proxy_linux"]
