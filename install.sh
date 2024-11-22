#!/bin/bash

# Main menu function
main_menu() {
    echo -e "\nSelect an option / 选择一个选项:"
    echo -e "\033[1mUse number keys to select an option / 使用数字键选择选项:\033[0m"
    PS3="Please enter your choice / 请输入您的选择: "
    options=("Server Installation / 服务端安装" "Admin Web Installation / 管理端 Web 安装" "User Web Installation / 用户端 Web 安装")
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                server_installation_menu
                break
                ;;
            2)
                admin_web_install
                break
                ;;
            3)
                user_web_install
                break
                ;;
            *)
                echo "Invalid option / 无效选项"
                ;;
        esac
    done
}

# Server installation method selection function
server_installation_menu() {
    echo -e "\nSelect installation method / 选择安装方法:"
    echo -e "\033[1mUse number keys to select an option / 使用数字键选择选项:\033[0m"
    PS3="Please enter your choice / 请输入您的选择: "
    options=("Command-line installation / 命令行安装" "Web installation / Web 安装")
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                command_line_install
                break
                ;;
            2)
                web_install
                break
                ;;
            *)
                echo "Invalid option / 无效选项"
                ;;
        esac
    done
}

# Admin Web installation function
admin_web_install() {
    echo -e "\nStarting Admin Web Installation / 开始管理端 Web 安装"

    # Check if Docker is installed
    check_docker

    # Prompt user to input environment variables
    echo -e "\nEnter the following information / 请输入以下信息:"
    read -p "Enter NEXT_PUBLIC_API_URL (e.g., https://api.example.com): " NEXT_PUBLIC_API_URL

    # Optional
    read -p "Enter NEXT_PUBLIC_DEFAULT_LANGUAGE (Optional, e.g., zh-CN or en-US): " NEXT_PUBLIC_DEFAULT_LANGUAGE

    # Build Docker run command
    docker_cmd="docker run -d -p 3000:3000 \
      --restart=always --log-opt max-size=10m --log-opt max-file=3 \
      --env NEXT_PUBLIC_API_URL=\"$NEXT_PUBLIC_API_URL\""

    if [ -n "$NEXT_PUBLIC_DEFAULT_LANGUAGE" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_DEFAULT_LANGUAGE=\"$NEXT_PUBLIC_DEFAULT_LANGUAGE\""
    fi

    docker_cmd="$docker_cmd --name ppanel-admin-web-beta ppanel/ppanel-admin-web:beta"

    # Run Docker command
    eval $docker_cmd

    # Get server IP address
    ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$ip_address" ]; then
        ip_address=$(ifconfig 2>/dev/null | grep 'inet ' | awk 'NR==1{print $2}')
    fi
    if [ -z "$ip_address" ]; then
        ip_address=$(ip addr show 2>/dev/null | grep 'inet ' | awk '/inet /{print $2}' | cut -d'/' -f1 | head -n 1)
    fi

    echo -e "\nAdmin Web Installation Completed / 管理端 Web 安装完成"
    echo -e "You can access the Admin Web at http://$ip_address:3000 / 您可以通过 http://$ip_address:3000 访问管理端 Web"
}

# User Web installation function
user_web_install() {
    echo -e "\nStarting User Web Installation / 开始用户端 Web 安装"

    # Check if Docker is installed
    check_docker

    # Prompt user to input environment variables
    echo -e "\nEnter the following information / 请输入以下信息:"
    read -p "Enter NEXT_PUBLIC_API_URL (e.g., https://api.example.com): " NEXT_PUBLIC_API_URL

    # Optional
    read -p "Enter NEXT_PUBLIC_DEFAULT_LANGUAGE (Optional, e.g., zh-CN or en-US): " NEXT_PUBLIC_DEFAULT_LANGUAGE
    read -p "Enter NEXT_PUBLIC_SITE_URL (Optional): " NEXT_PUBLIC_SITE_URL
    read -p "Enter NEXT_PUBLIC_EMAIL (Optional): " NEXT_PUBLIC_EMAIL

    echo -e "\nEnter social media links (optional) / 输入社交媒体链接（可选）:"
    read -p "NEXT_PUBLIC_TELEGRAM_LINK: " NEXT_PUBLIC_TELEGRAM_LINK
    read -p "NEXT_PUBLIC_TWITTER_LINK: " NEXT_PUBLIC_TWITTER_LINK
    read -p "NEXT_PUBLIC_DISCORD_LINK: " NEXT_PUBLIC_DISCORD_LINK
    read -p "NEXT_PUBLIC_INSTAGRAM_LINK: " NEXT_PUBLIC_INSTAGRAM_LINK
    read -p "NEXT_PUBLIC_LINKEDIN_LINK: " NEXT_PUBLIC_LINKEDIN_LINK
    read -p "NEXT_PUBLIC_FACEBOOK_LINK: " NEXT_PUBLIC_FACEBOOK_LINK
    read -p "NEXT_PUBLIC_GITHUB_LINK: " NEXT_PUBLIC_GITHUB_LINK

    # Build Docker run command
    docker_cmd="docker run -d -p 3001:3000 \
      --restart=always --log-opt max-size=10m --log-opt max-file=3 \
      --env NEXT_PUBLIC_API_URL=\"$NEXT_PUBLIC_API_URL\""

    if [ -n "$NEXT_PUBLIC_DEFAULT_LANGUAGE" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_DEFAULT_LANGUAGE=\"$NEXT_PUBLIC_DEFAULT_LANGUAGE\""
    fi

    if [ -n "$NEXT_PUBLIC_SITE_URL" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_SITE_URL=\"$NEXT_PUBLIC_SITE_URL\""
    fi

    if [ -n "$NEXT_PUBLIC_EMAIL" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_EMAIL=\"$NEXT_PUBLIC_EMAIL\""
    fi

    if [ -n "$NEXT_PUBLIC_TELEGRAM_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_TELEGRAM_LINK=\"$NEXT_PUBLIC_TELEGRAM_LINK\""
    fi

    if [ -n "$NEXT_PUBLIC_TWITTER_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_TWITTER_LINK=\"$NEXT_PUBLIC_TWITTER_LINK\""
    fi

    if [ -n "$NEXT_PUBLIC_DISCORD_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_DISCORD_LINK=\"$NEXT_PUBLIC_DISCORD_LINK\""
    fi

    if [ -n "$NEXT_PUBLIC_INSTAGRAM_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_INSTAGRAM_LINK=\"$NEXT_PUBLIC_INSTAGRAM_LINK\""
    fi

    if [ -n "$NEXT_PUBLIC_LINKEDIN_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_LINKEDIN_LINK=\"$NEXT_PUBLIC_LINKEDIN_LINK\""
    fi

    if [ -n "$NEXT_PUBLIC_FACEBOOK_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_FACEBOOK_LINK=\"$NEXT_PUBLIC_FACEBOOK_LINK\""
    fi

    if [ -n "$NEXT_PUBLIC_GITHUB_LINK" ]; then
        docker_cmd="$docker_cmd --env NEXT_PUBLIC_GITHUB_LINK=\"$NEXT_PUBLIC_GITHUB_LINK\""
    fi

    docker_cmd="$docker_cmd --name ppanel-user-web-beta ppanel/ppanel-user-web:beta"

    # Run Docker command
    eval $docker_cmd

    # Get server IP address
    ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$ip_address" ]; then
        ip_address=$(ifconfig 2>/dev/null | grep 'inet ' | awk 'NR==1{print $2}')
    fi
    if [ -z "$ip_address" ]; then
        ip_address=$(ip addr show 2>/dev/null | grep 'inet ' | awk '/inet /{print $2}' | cut -d'/' -f1 | head -n 1)
    fi

    echo -e "\nUser Web Installation Completed / 用户端 Web 安装完成"
    echo -e "You can access the User Web at http://$ip_address:3001 / 您可以通过 http://$ip_address:3001 访问用户端 Web"
}

# Check if Docker is installed
check_docker() {
    if ! [ -x "$(command -v curl)" ]; then
        echo -e "\nCurl is not installed. Installing Curl... / Curl 未安装。正在安装 Curl..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update -y && sudo apt-get install -y curl
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install -y curl
        else
            echo -e "\nCould not determine package manager. Please install curl manually. / 无法确定包管理器。请手动安装 curl。"
            exit 1
        fi
        echo -e "\nCurl installation completed. / Curl 安装完成。"
    fi
    if ! [ -x "$(command -v docker)" ]; then
        echo -e "\nDocker is not installed. Installing Docker... / Docker 未安装。正在安装 Docker..."
        curl -fsSL https://get.docker.com | bash -s -- -y
        echo -e "\nDocker installation completed. / Docker 安装完成。"
    else
        echo -e "\nDocker is already installed. / Docker 已经安装。"
    fi
}

# Install MySQL using Docker
install_mysql() {
    echo -e "\nInstalling MySQL using Docker... / 使用 Docker 安装 MySQL..."

    docker run --name mysql \
            --restart=always \
            --log-opt max-size=10m --log-opt max-file=3 \
            -v /var/lib/mysql:/var/lib/mysql \
            -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
            -e MYSQL_DATABASE="$MYSQL_DATABASE" \
            -e MYSQL_USER="$MYSQL_USER" \
            -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
            -d -p 3306:3306 mysql:8

    echo -e "\nMySQL installation completed. / MySQL 安装完成。"
}

# Install Redis using Docker
install_redis() {
    echo -e "\nInstalling Redis using Docker... / 使用 Docker 安装 Redis..."
    if [ -n "$REDIS_PASSWORD" ]; then
        docker run --name redis \
            --restart=always --log-opt max-size=10m --log-opt max-file=3 \
            -v /var/lib/redis:/data \
            -d -p 6379:6379 redis:latest redis-server --requirepass "$REDIS_PASSWORD"
    else
        docker run --name redis \
            -v /var/lib/redis:/data \
            --restart=always --log-opt max-size=10m --log-opt max-file=3 \
            -d -p 6379:6379 redis:latest
    fi
    echo -e "\nRedis installation completed. / Redis 安装完成。"
}

# Start the PPanel service
start_docker_service() {
    echo -e "\nStarting the PPanel service... / 启动 PPanel 服务..."

    # Remove existing container if it exists
    docker rm -f ppanel-server-beta 2>/dev/null

    docker run -d -p 8080:8080 \
      --name ppanel-server-beta \
      --restart=always --log-opt max-size=10m --log-opt max-file=3 \
      -v /etc/ppanel.yaml:/app/etc/ppanel.yaml \
      ppanel/ppanel-server:beta

    if [ $? -eq 0 ]; then
        echo -e "\nPPanel service started successfully. / PPanel 服务已成功启动。"
    else
        echo -e "\nFailed to start PPanel service. / 无法启动 PPanel 服务。"
    fi
}

# Command-line installation function
command_line_install() {
    check_docker
    echo -e "\nPlease provide the following information / 请提供以下信息:"

    # Ask if the user wants to install MySQL
    read -p "Do you want to install MySQL using Docker now? (y/n) / 您是否想使用 Docker 安装 MySQL？(y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -p "Enter MySQL Database Name / 输入 MySQL 数据库名称: " MYSQL_DATABASE
        read -sp "Enter MySQL Root Password / 输入 MySQL Root 密码: " MYSQL_ROOT_PASSWORD
        echo
        read -p "Enter MySQL User (default: ppanel) / 输入 MySQL 用户 (默认: ppanel): " MYSQL_USER
        MYSQL_USER=${MYSQL_USER:-ppanel}
        read -sp "Enter MySQL Password for user $MYSQL_USER / 输入 MySQL 用户 $MYSQL_USER 的密码: " MYSQL_PASSWORD
        echo
        install_mysql
        MYSQL_HOST="localhost"
        MYSQL_PORT="3306"
    else
        read -p "Enter MySQL Host (default: localhost) / 输入 MySQL 主机 (默认: localhost): " MYSQL_HOST
        MYSQL_HOST=${MYSQL_HOST:-localhost}
        read -p "Enter MySQL Port (default: 3306) / 输入 MySQL 端口 (默认: 3306): " MYSQL_PORT
        MYSQL_PORT=${MYSQL_PORT:-3306}
        read -p "Enter MySQL User (default: root) / 输入 MySQL 用户 (默认: root): " MYSQL_USER
        MYSQL_USER=${MYSQL_USER:-root}
        read -sp "Enter MySQL Password / 输入 MySQL 密码: " MYSQL_PASSWORD
        echo
        read -p "Enter MySQL Database Name / 输入 MySQL 数据库名称: " MYSQL_DATABASE
    fi

    # Ask if the user wants to install Redis
    read -p "Do you want to install Redis using Docker now? (y/n) / 您是否想使用 Docker 安装 Redis？(y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -sp "Enter Redis Password (Optional) / 输入 Redis 密码 (可选): " REDIS_PASSWORD
        echo
        install_redis
        REDIS_HOST="127.0.0.1"
        REDIS_PORT="6379"
    else
        read -p "Enter Redis Host (default: 127.0.0.1) / 输入 Redis 主机 (默认: 127.0.0.1): " REDIS_HOST
        REDIS_HOST=${REDIS_HOST:-127.0.0.1}
        read -p "Enter Redis Port (default: 6379) / 输入 Redis 端口 (默认: 6379): " REDIS_PORT
        REDIS_PORT=${REDIS_PORT:-6379}
        read -sp "Enter Redis Password (Optional) / 输入 Redis 密码 (可选): " REDIS_PASSWORD
        echo
    fi

    # Generate random UUID
    if ! [ -x "$(command -v uuidgen)" ]; then
        echo -e "\nuuidgen is not installed. Installing uuidgen... / uuidgen 未安装。正在安装 uuidgen..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update -y && sudo apt-get install -y uuid-runtime
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install -y uuid
        else
            echo -e "\nCould not determine package manager. Please install uuidgen manually. / 无法确定包管理器。请手动安装 uuidgen。"
            exit 1
        fi
        echo -e "\nuuidgen installation completed. / uuidgen 安装完成。"
    fi

    ACCESS_SECRET=$(uuidgen)
    ACCESS_EXPIRE=604800

    # Create configuration file
    cat > /etc/ppanel.yaml <<EOL
Host: 0.0.0.0
Port: 8080
Debug: true
JwtAuth:
    AccessSecret: "${ACCESS_SECRET}"
    AccessExpire: ${ACCESS_EXPIRE}
Logger:
    FilePath: ./ppanel.log
    MaxSize: 50
    MaxBackup: 3
    MaxAge: 30
    Compress: true
    LogType: json
    Level: info
MySQL:
    Addr: ${MYSQL_HOST}:${MYSQL_PORT}
    Username: ${MYSQL_USER}
    Password: ${MYSQL_PASSWORD}
    Dbname: ${MYSQL_DATABASE}
    Config: charset%3Dutf8mb4%26parseTime%3Dtrue%26loc%3DLocal
    MaxIdleConns: 10
    MaxOpenConns: 10
    LogMode: dev
    LogZap: false
    SlowThreshold: 1000
Redis:
    Host: ${REDIS_HOST}:${REDIS_PORT}
    Pass: "${REDIS_PASSWORD}"
    DB: 0
EOL

    start_docker_service

    # Get server IP address
    ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$ip_address" ]; then
        ip_address=$(ifconfig 2>/dev/null | grep 'inet ' | awk 'NR==1{print $2}')
    fi
    if [ -z "$ip_address" ]; then
        ip_address=$(ip addr show 2>/dev/null | grep 'inet ' | awk '/inet /{print $2}' | cut -d'/' -f1 | head -n 1)
    fi

    echo -e "\nServer installation completed. You can access the service at http://$ip_address:8080 / 服务端安装完成。您可以通过 http://$ip_address:8080 访问服务。"
}

# Web installation function
web_install() {
    check_docker

    # Create an empty /etc/ppanel.yaml file
    echo -e "\nCreating an empty /etc/ppanel.yaml file... / 创建空的 /etc/ppanel.yaml 文件..."
    > /etc/ppanel.yaml
    echo -e "Empty /etc/ppanel.yaml file created. / 已创建空的 /etc/ppanel.yaml 文件。\n"

    # Ask if the user wants to install MySQL
    read -p "Do you want to install MySQL using Docker now? (y/n) / 您是否想使用 Docker 安装 MySQL？(y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -p "Enter MySQL Database Name / 输入 MySQL 数据库名称: " MYSQL_DATABASE
        read -sp "Enter MySQL Root Password / 输入 MySQL Root 密码: " MYSQL_ROOT_PASSWORD
        echo
        read -p "Enter MySQL User / 输入 MySQL 用户名 (default: ppanel): " MYSQL_USER
        MYSQL_USER=${MYSQL_USER:-ppanel}
        read -sp "Enter MySQL Password / 输入 MySQL 密码: " MYSQL_PASSWORD
        echo
        install_mysql
    fi

    # Ask if the user wants to install Redis
    read -p "Do you want to install Redis using Docker now? (y/n) / 您是否想使用 Docker 安装 Redis？(y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        read -sp "Enter Redis Password (Optional) / 输入 Redis 密码 (可选): " REDIS_PASSWORD
        echo
        install_redis
    fi

    echo -e "\nStarting the PPanel service for Web Installation... / 启动 PPanel 服务以进行 Web 安装..."
    start_docker_service

    # Get server IP address
    ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$ip_address" ]; then
        ip_address=$(ifconfig 2>/dev/null | grep 'inet ' | awk 'NR==1{print $2}')
    fi
    if [ -z "$ip_address" ]; then
        ip_address=$(ip addr show 2>/dev/null | grep 'inet ' | awk '/inet /{print $2}' | cut -d'/' -f1 | head -n 1)
    fi

    echo -e "\nPlease go to http://$ip_address:8080 to complete the initialization. / 请前往 http://$ip_address:8080 完成初始化。"
}

# Start the script
main_menu
