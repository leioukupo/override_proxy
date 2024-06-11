中文 | [English](./README.md)

# GitHub Copilot 代理工具

此工具作为 GitHub Copilot 请求的代理层，确保您的 IP 地址保持私密并管理遥测数据以减少数据上传。它还有助于避免被 GitHub 错误地标记为风险用户。以下是针对 Visual Studio Code 和 IntelliJ IDEA 插件的设置指南。

## 特点

- **隐私保护**：防止您的 IP 地址泄露给 GitHub。
- **减少数据遥测**：最小化发送到 GitHub 的数据量。
- **避免账户被标记**：帮助防止您的账户被错误地标记为风险。

## IDE登录配置

### 对于 Visual Studio Code

1. **安装 GitHub Copilot 插件**（如果尚未安装）。
2. **修改 VSCode 设置**，通过在您的 `settings.json` 文件中添加以下配置来使用此代理：

    ```json5
    {
        "github.copilot.advanced": {
            "authProvider": "github-enterprise",
            // 设置代理 copilot 提示请求时
            "debug.overrideProxyUrl": "https://api.your.domain",
            // 设置代理 copilot 聊天提示请求时
            "debug.overrideCAPIUrl": "https://api.your.domain",
            // 使用 GPT-4 模型进行 copilot-chat，无需代理服务器即可使用
            "debug.overrideChatEngine": "gpt-4",
        },
        "github-enterprise.uri": "https://your.domain",
    }
    ```

### 对于 IntelliJ IDEA

1. **设置环境变量**：在您的系统上配置以下环境变量：

    ```plaintext
    GH_COPILOT_OVERRIDE_PROXY_URL=https://api.your.domain
    GH_COPILOT_OVERRIDE_CAPI_URL=https://api.your.domain
    ```

2. **配置 IntelliJ IDEA 中的 GitHub Copilot 插件**：
    - 转到 `设置` > `语言与框架` > `GitHub Copilot` > `认证`。
    - 将 `认证提供者` 设置为 `your.domain`。

确保所有指向 api.your.domain 和 your.domain 的请求都通过此代理程序进行路由，以确保功能正常并增强安全措施。

> 如果你不需要部署代理服务器，就不用继续往下看了。

## 部署配置

默认情况下，工具从当前运行目录读取配置文件。您也可以在启动工具时使用 `--config` 或 `-c` 选项指定配置文件。确保配置文件遵循本文档前面提到的 JSON 结构。

### 配置文件格式

以下是工具的示例配置：

```json5
{
   "listenIp": "0.0.0.0", // 监听的IP地址
   "listenPort": 8080, // 监听的端口
   "targetList": [
      {
         "authUrl": "https://api.github.com/copilot_internal/v2/token", // 获取令牌的URL
         "authToken": "gho_Fr0Xcd07iishNhaJuxOvvkwa6dzHKg2nrJeQ", // 用于认证的令牌
         "type": "copilot", // 目标的类型
         "httpProxyAddr": "127.0.0.1:9090", // HTTP代理的地址
         "codexUrl": "https://copilot-proxy.githubusercontent.com/v1/engines/copilot-codex/completions", // Copilot Codex端点的URL
         "chatUrl": "https://api.githubcopilot.com/chat/completions" // Copilot聊天端点的URL
      },
      {
         "authToken": "sk-xxx", // 用于认证的令牌
         "type": "openai", // 目标的类型
         "priority": 1, // 优先级 越小越高
         "httpProxyAddr": "127.0.0.1:9090", // HTTP代理的地址
         "concurrency": 2,// 同时请求上限数量
         "codexUrl": "https://api-proxy.oaipro.com/v1/completions", // Copilot Codex端点的URL
         "chatUrl": "https://api-proxy.oaipro.com/v1/chat/completions" // Copilot聊天端点的URL
      }
   ],
   "tokenSalt": "default_salt", // 用于令牌生成的盐值
   "adminToken": "default_admin_token", // 用于管理员认证的令牌
   "copilotDebounce": 1000, // Copilot请求的防抖时间
   "defaultBaseUrl": "https://api.your.domain",// 默认的基础URL 与IDE配置中的debug.overrideProxyUrl和debug.overrideCAPIUrl对应 为空则不启用新版token请求结果
   "apiBaseUrl": "https://api.your.domain",// API的基础URL 可空 与IDE配置中的debug.overrideCAPIUrl对应 优先级比defaultBaseUrl高
   "originTrackerBaseUrl": "https://origin-tracker.your.domain",// Origin Tracker的基础URL 可空 作用未知 优先级比apiBaseUrl高
   "proxyBaseUrl": "https://api.your.domain",// 代理的基础URL 可空 与IDE配置中的debug.overrideProxyUrl对应 优先级比defaultBaseUrl高
   "telemetryBaseUrl": "https://copilot-telemetry-service.your.domain"// 遥测的基础URL 用于接收遥控数据 为空则使用defaultBaseUrl
}
```

`type`字段现在支持`copilot`和`openai`，分别对应 GitHub Copilot 和 OpenAI 的请求方式。`copilot`方式的`authToken`用于获取copilotToken进行后续请求，`openai`方式的`authToken`直接用于请求。

### 用户认证

默认的 `admin` 账户创建时使用用户名 `admin` 和密码 `default_admin_password`。管理员必须使用 Basic 认证来访问 API。

例如，要使用 `curl` 访问 `/user/add` 路由，您可以使用以下命令：

```bash
curl -X POST -u admin:default_admin_password -d '{"username": "your_username", "password": "your_password"}' https://api.your.domain/user/add
```

### 持久性

在退出时，工具会在配置文件所在目录保存几个 JSON 文件，以便数据持久化：

- `header.json`：存储头信息。
- `data.db`：存储用户信息

### 日志

默认启用日志记录，在运行路径生成 `copilot_proxy.log` 文件。如果偏好，可使用 `--no-log` 选项禁用日志记录。

## 使用

要使用特定配置启动代理服务器，请使用以下命令：

```bash
copilot_proxy --config /path/to/your_config.json
```

将 `/path/to/your_config.json` 替换为您的配置文件的实际路径。此命令使用您在配置文件中定义的设置初始化代理服务器。

## API 路由

GitHub Copilot 代理工具设置了多个路由以处理认证、用户数据请求和遥测等功能。以下是可用路由及其功能的细分：

### 认证路由

- **POST `/login/device/code`**：启动设备代码登录流程。
- **GET `/login/device`**：检索设备代码登录尝试的状态。
- **POST `/login/oauth/access_token`**：将设备代码交换为 OAuth 访问令牌。需要设备代码授权。

### 用户数据路由

- **GET `/api/v3/user` 和 GET `/user`**：获取用户详情。需要访问令牌授权。
- **GET `/api/v3/meta`**：检索与 GitHub API 服务相关的元数据。需要访问令牌授权。
- **GET `/copilot_internal/v2/token`**：获取 Copilot 服务内部使用的令牌。需要访问令牌授权。

### Copilot 请求代理

- **POST `/v1/engines/copilot-codex/completions`**：代理完成请求到官方 Copilot Codex 端点。需要 Copilot 令牌授权。
- **POST `/chat/completions`**：代理聊天完成请求到官方 GitHub Copilot 聊天 API。需要 Copilot 令牌授权。
- **GET `/models`**：代理模型请求到官方 Copilot 模型 API。需要 Copilot 令牌授权。
- **GET `/_ping`**：用于健康检查的 ping 路由。

### 遥测

- **POST `/telemetry`**：处理遥测数据的发布，不处理正文。

### 管理路由

- **DELETE `/header/upload_token`**：清空Header提供者accessToken。需要管理员令牌授权。
- **POST `/github/upload_token`**：允许上传 GitHub 用户令牌以用于代理请求。需要管理员令牌授权。
- **POST `/json/save`**：以 JSON 格式保存配置或状态信息。需要管理员令牌授权。
- **POST `/user/add`**：添加用户账号和密码。需要管理员令牌授权。

## Docker 设置说明

### 前提条件

确保你的系统上已安装 Docker。如果没有，你可以从[官方 Docker 网站](https://www.docker.com/get-started)下载并安装。

### 构建 Docker 镜像

1. **克隆仓库**：克隆包含 Dockerfile 和项目文件的仓库。

    ```bash
    git clone https://gitlab.com/LaelLuo/copilot_proxy.git
    cd copilot_proxy
    ```

2. **构建 Docker 镜像**：运行以下命令来构建 Docker 镜像。

    ```bash
    docker build -t copilot_proxy:latest .
    ```
   
> tips: 你可以修改`Dockerfile`的编译镜像，直接使用`dart:latest`镜像编译，然后删除下载dart sdk的步骤，加快构建速度。

### 运行 Docker 容器

1. **准备配置**：确保在项目目录中准备好 `config.json` 文件。该文件应遵循文档中指定的格式。

2. **运行 Docker 容器**：使用以下命令运行 Docker 容器。

    ```bash
    docker run -d --name copilot_proxy_container \
        -v $(pwd)/config.json:/config/config.json \
        -e DART_VERSION=3.4.1 \
        --network host \
        copilot_proxy:latest
    ```

   - `-d`：以分离模式运行容器。
   - `--name copilot_proxy_container`：为容器命名。
   - `-v $(pwd)/config.json:/config/config.json`：将配置文件映射到容器中。
   - `-e DART_VERSION=3.4.1`：设置 Dart 版本环境变量。
   - `--network host`：使用主机的网络配置。

### 停止和删除容器

要停止正在运行的容器，使用：

```bash
docker stop copilot_proxy_container
```

要删除容器，使用：

```bash
docker rm copilot_proxy_container
```

### Docker Compose

你也可以使用 Docker Compose 来管理容器。确保已安装 `docker-compose`，然后在修改项目目录中的 `docker-compose.yml` 文件，内容如下：

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
      - .:/config  # 确保目录中有 config.json
    environment:
      - DART_VERSION=3.4.1
    network_mode: host
```

使用以下命令通过 Docker Compose 启动容器：

```bash
docker-compose up -d
```

要停止并删除容器，使用：

```bash
docker-compose down
```

### 验证设置

容器运行后，你可以通过检查日志来验证其是否正常运行：

```bash
docker logs copilot_proxy_container
```

确保代理服务器在指定的 IP 和端口上监听，并且日志中没有错误。

按照这些步骤，你应该能够在 Docker 容器中设置并使用 GitHub Copilot Proxy Tool，从而确保你的隐私并有效管理遥测数据。

## FAQ

### 什么是your.domain？

`your.domain` 是一个占位符，用于表示您的域名。在配置文件中，您应该将其替换为您的实际域名。例如，如果您的域名是 `example.com`，则应将 `your.domain` 替换为 `example.com`。

#### 以下内容仅 Visual Studio Code 用可用

如果你没有域名，但你有公网 IP 地址，你可以使用nip.io服务，例如，如果你的公网 IP 地址是 `1.1.1.1`，你可以使用 `1-1-1-1.nip.io` 作为你的域名。

如果你没有公网 IP 地址，你可以尝试使用 `your.domain:{listenPort}` 作为你的域名，并修改你的 hosts 文件，将 `your.domain` 和 `api.your.domain` 指向 `127.0.0.1`。

## 支持

如有问题、疑问或希望贡献，请参考 [GitLab 上的项目仓库](https://gitlab.com/LaelLuo/copilot_proxy) 或在那里提出问题。Linux AMD64 版本的构建可作为 CI 工件下载。

欢迎提交问题和建议还有PR（特别是文档，因为我不是很擅长写文档）。

## 许可

[MIT 许可证](LICENSE) - 您可以根据 MIT 许可证条款自由使用、修改和分发。