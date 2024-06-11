English | [中文](./README_zh.md)

# GitHub Copilot Proxy Tool

This tool serves as a proxy layer for GitHub Copilot requests, ensuring that your IP address remains private and managing telemetry to reduce data uploads. It also helps avoid mistakenly being flagged as a risky user by GitHub. Below, you will find setup instructions for both Visual Studio Code and IntelliJ IDEA plugins.

## Features

- **Privacy Protection**: Prevents the leakage of your IP address to GitHub.
- **Reduced Data Telemetry**: Minimizes the amount of data sent to GitHub.
- **Avoids Account Flagging**: Helps prevent your account from being incorrectly marked as risky.

## IDE Login Configuration

### For Visual Studio Code

1. **Install the GitHub Copilot Plugin** if it's not already installed.
2. **Modify the VSCode settings** to use this proxy by adding the following configuration to your `settings.json` file:

    ```json5
    {
        "github.copilot.advanced": {
            "authProvider": "github-enterprise",
            // Set when proxying copilot prompt requests
            "debug.overrideProxyUrl": "https://api.your.domain",
            // Set when proxying copilot chat prompt requests
            "debug.overrideCAPIUrl": "https://api.your.domain",
            // Use the GPT-4 model for copilot-chat, can be used without a proxy server
            "debug.overrideChatEngine": "gpt-4",
        },
        "github-enterprise.uri": "https://your.domain",
    }
    ```

### For IntelliJ IDEA

1. **Set Environment Variables**: Configure the following environment variables on your system:

    ```plaintext
    GH_COPILOT_OVERRIDE_PROXY_URL=https://api.your.domain
    GH_COPILOT_OVERRIDE_CAPI_URL=https://api.your.domain
    ```

2. **Configure the GitHub Copilot Plugin** in IntelliJ IDEA:
    - Go to `Settings` > `Languages & Frameworks` > `GitHub Copilot` > `Authentication`.
    - Set the `Authentication Provider` to `your.domain`.

Ensure that all requests to api.your.domain and your.domain are routed through this proxy program to ensure proper functionality and enhance security measures.

> If you do not need to deploy a proxy server, you can stop reading here.

## Deployment Configuration

By default, the tool reads the configuration file from the current running directory. You can also specify a configuration file using the `--config` or `-c` option when starting the tool. Ensure the configuration file follows the provided JSON structure mentioned earlier in this document.

### Configuration File Format

Here is a sample configuration for the tool:

```json5
{
   "listenIp": "0.0.0.0",// The IP address to listen on
   "listenPort": 8080,// The port to listen on
   "targetList": [
      {
         "authUrl": "https://api.github.com/copilot_internal/v2/token",// The URL to obtain the token
         "authToken": "gho_Fr0Xcd07iishNhaJuxOvvkwa6dzHKg2nrJeQ",// The token to use for authentication
         "type": "copilot",// The type of target
         "httpProxyAddr": "127.0.0.1:9090",// The address of the HTTP proxy
         "codexUrl": "https://copilot-proxy.githubusercontent.com/v1/engines/copilot-codex/completions",// The URL for the Copilot Codex endpoint
         "chatUrl": "https://api.githubcopilot.com/chat/completions"// The URL for the Copilot chat endpoint
      },
      {
         "authToken": "sk-xxx",// The token to use for authentication
         "type": "openai",// The type of target
         "priority": 1, // The priority, the smaller, the higher
         "httpProxyAddr": "127.0.0.1:9090",// The address of the HTTP proxy
         "concurrency": 2,// requests limit at the same time
         "codexUrl": "https://api-proxy.oaipro.com/v1/completions",// The URL for the Copilot Codex endpoint
         "chatUrl": "https://api-proxy.oaipro.com/v1/chat/completions"// The URL for the Copilot chat endpoint
      }
   ],
   "tokenSalt": "default_salt",// The salt to use for token generation
   "adminToken": "default_admin_token",// The token to use for admin authentication
   "copilotDebounce": 1000, // The debounce time for Copilot requests
   "defaultBaseUrl": "https://api.your.domain",// The default base URL corresponding to debug.overrideProxyUrl and debug.overrideCAPIUrl in IDE configuration, empty will not use the new token request result
   "apiBaseUrl": "https://api.your.domain",// The base URL of the API can be empty, corresponding to debug.overrideCAPIUrl in IDE configuration, with higher priority than defaultBaseUrl
   "originTrackerBaseUrl": "https://origin-tracker.your.domain",// The base URL of the Origin Tracker can be empty, the purpose is unknown, with higher priority than apiBaseUrl
   "proxyBaseUrl": "https://api.your.domain",// The base URL of the proxy can be empty, corresponding to debug.overrideProxyUrl in IDE configuration, with higher priority than defaultBaseUrl
   "telemetryBaseUrl": "https://copilot-telemetry-service.your.domain"// The base URL of telemetry for receiving telemetry data, empty will use defaultBaseUrl
}
```

The `type` field now supports `copilot` and `openai`, corresponding to GitHub Copilot and OpenAI request methods respectively. For the `copilot` method, the `authToken` is used to obtain the copilotToken for subsequent requests, while for the `openai` method, the `authToken` is used directly for requests.

### User Authentication

The default `admin` account is created with the username admin and the password `default_admin_password`. Administrators must use basic authentication for API access.

For example, to use `curl` to access the `/user/add` route, you can use the following command:

```bash
curl -X POST -u admin:default_admin_password -d '{"username": "your_username", "password": "your_password"}' https://api.your.domain/user/add
```

### Persistence

Upon exit, the tool saves several JSON files in the same directory as the configuration file for data persistence:

- `header.json`: Stores headers.
- `data.db`: Stores user information.

### Logging

Logging is enabled by default, generating a `copilot_proxy.log` file in the running path. Use the `--no-log` option to disable logging if preferred.

## Usage

To start the proxy server with a specific configuration, use the following command:

```bash
copilot_proxy --config /path/to/your_config.json
```

Replace `/path/to/your_config.json` with the actual path to your configuration file. This command initializes the proxy server using the settings defined in your configuration file.

## API Routes

The GitHub Copilot Proxy Tool sets up various routes to handle authentication, user data requests, and telemetry, among others. Here’s a breakdown of the available routes and their functionalities:

### Authentication Routes

- **POST `/login/device/code`**: Initiates the device code login process.
- **GET `/login/device`**: Retrieves the status of a device code login attempt.
- **POST `/login/oauth/access_token`**: Exchanges a device code for an OAuth access token. Requires device code authorization.

### User Data Routes

- **GET `/api/v3/user` and GET `/user`**: Fetches user details. Requires access token authorization.
- **GET `/api/v3/meta`**: Retrieves metadata related to GitHub API services. Requires access token authorization.
- **GET `/copilot_internal/v2/token`**: Obtains a token for internal use within the Copilot services. Requires access token authorization.

### Copilot Request Proxies

- **POST `/v1/engines/copilot-codex/completions`**: Proxies completion requests to the official Copilot Codex endpoint. Requires Copilot token authorization.
- **POST `/chat/completions`**: Proxies chat completion requests to the official GitHub Copilot chat API. Requires Copilot token authorization.
- **GET `/models`**: Proxies model requests to the official Copilot model API. Requires Copilot token authorization.
- **GET `/_ping`**: Health check endpoint.

### Telemetry

- **POST `/telemetry`**: Handles the posting of telemetry data without processing the body.

### Admin Routes

- **DELETE `/header/upload_token`**: Clear Header provider access token. Requires admin token authorization. Requires admin token authorization.
- **POST `/github/upload_token`**: Permits uploading GitHub user tokens for use with proxy requests. Requires admin token authorization.
- **POST `/json/save`**: Saves configuration or state information in JSON format. Requires admin token authorization.
- **POST `/user/add`**: Adds a user to the database. Requires admin token authorization.

## Docker Setup Instructions

### Prerequisites

Ensure you have Docker installed on your system. If not, you can download and install it from the [official Docker website](https://www.docker.com/get-started).

### Building the Docker Image

1. **Clone the Repository**: Clone the repository containing the Dockerfile and project files.

    ```bash
    git clone https://gitlab.com/LaelLuo/copilot_proxy.git
    cd copilot_proxy
    ```

2. **Build the Docker Image**: Run the following command to build the Docker image.

    ```bash
    docker build -t copilot_proxy:latest .
    ```
   
> tips: You can modify the `Dockerfile` to compile the image directly using the `dart:latest` image and then delete the step to download the Dart SDK to speed up the build process.

### Running the Docker Container

1. **Prepare Configuration**: Ensure you have the `config.json` file ready in the project directory. This file should follow the format specified in the documentation.

2. **Run the Docker Container**: Use the following command to run the Docker container.

    ```bash
    docker run -d --name copilot_proxy_container \
        -v $(pwd)/config.json:/config/config.json \
        -e DART_VERSION=3.4.1 \
        --network host \
        copilot_proxy:latest
    ```

   - `-d`: Runs the container in detached mode.
   - `--name copilot_proxy_container`: Names the container.
   - `-v $(pwd)/config.json:/config/config.json`: Maps the configuration file to the container.
   - `-e DART_VERSION=3.4.1`: Sets the Dart version environment variable.
   - `--network host`: Uses the host's network configuration.

### Stopping and Removing the Container

To stop the running container, use:

```bash
docker stop copilot_proxy_container
```

To remove the container, use:

```bash
docker rm copilot_proxy_container
```

### Docker Compose

You can also use Docker Compose to manage the container. Ensure you have `docker-compose` installed, then modify the `docker-compose.yml` file in the project directory with the following content:

```yaml
version: '3.8'

services:
  copilot_proxy:
    build:
      context: .
      dockerfile: Dockerfile
    image: copilot_proxy:latest
    container_name: copilot_proxy_container
    volumes:
      - .:/config  # Ensure config.json is in the directory
    environment:
      - DART_VERSION=3.4.1
    network_mode: host
```

Run the following command to start the container using Docker Compose:

```bash
docker-compose up -d
```

To stop and remove the container, use:

```bash
docker-compose down
```

### Verifying the Setup

Once the container is running, you can verify that it is functioning correctly by checking the logs:

```bash
docker logs copilot_proxy_container
```

Ensure that the proxy server is listening on the specified IP and port, and that there are no errors in the logs.

By following these steps, you should be able to set up and use the GitHub Copilot Proxy Tool in a Docker container, ensuring your privacy and managing telemetry effectively.

## FAQ

### What is `your.domain`?

`your.domain` is a placeholder used to represent your domain name. In configuration files, you should replace it with your actual domain name. For example, if your domain name is `example.com`, you should replace `your.domain` with `example.com`.

#### The following content is only available for Visual Studio Code

If you do not have a domain name, but you have a public IP address, you can use the nip.io service. For instance, if your public IP address is `1.1.1.1`, you can use `1-1-1-1.nip.io` as your domain name.

If you do not have a public IP address, you can try using `your.domain:{listenPort}` as your domain name and modify your hosts file to point `your.domain` and `api.your.domain` to `127.0.0.1`.

## Support

For issues, questions, or contributions, please refer to the [project repository on GitLab](https://gitlab.com/LaelLuo/copilot_proxy) or raise an issue there. The Linux AMD64 version of the build is available as a CI artifact for download.

Welcome to submit issues, suggestions, and PRs (especially for documentation, as I'm not very good at writing documentation).

## License

[MIT License](LICENSE) - Feel free to use, modify, and distribute as per the MIT License terms.