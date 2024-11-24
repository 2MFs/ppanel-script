#!/bin/bash

# PPanel One-Click Deployment Script
# Supports selecting different service combinations for installation, automatically sets NEXT_PUBLIC_API_URL, clears other environment variables
# Prompts user to modify ppanel.yaml and corresponding Docker Compose files when deploying the server and one-click deployment
# Checks if the user is already in the ppanel-script directory
# Bilingual support (English first, then Chinese)
# Added an "Update services" option that functions similarly to "Restart services"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  echo "请以 root 用户运行此脚本。"
  exit 1
fi

# Update system package index
echo "Updating system package index..."
echo "更新系统包索引..."
apt-get update -y

# Install necessary packages
echo "Installing necessary packages..."
echo "安装必要的软件包..."
apt-get install -y curl git

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed. Skipping installation."
    echo "检测到 Docker 已安装，跳过安装步骤。"
else
    # Install Docker
    echo "Installing Docker..."
    echo "正在安装 Docker..."
    curl -fsSL https://get.docker.com | bash -s -- -y
fi

# Check if in ppanel-script directory
CURRENT_DIR=${PWD##*/}
if [ "$CURRENT_DIR" != "ppanel-script" ]; then
    # Clone PPanel script repository
    echo "Cloning PPanel script repository..."
    echo "正在克隆 PPanel 脚本仓库..."
    git clone https://github.com/perfect-panel/ppanel-script.git
    cd ppanel-script
else
    echo "Detected that you are already in the ppanel-script directory, skipping clone step."
    echo "检测到已在 ppanel-script 目录中，跳过克隆步骤。"
fi

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Display service component selection menu
echo "Please select the action you want to perform:"
echo "请选择您要执行的操作："
echo "1) One-click deployment (All components) / 一键部署（全部组件）"
echo "2) Deploy server / 部署服务端"
echo "3) Deploy admin dashboard / 部署管理端"
echo "4) Deploy user dashboard / 部署用户端"
echo "5) Deploy front-end (Admin and User dashboards) / 部署前端（管理端和用户端）"
echo "6) Update services / 更新服务"
echo "7) Restart services / 重启服务"
echo "8) View logs / 查看日志"
echo "9) Exit / 退出"

read -p "Please enter a number (1-9): " choice
# If the user does not input, default to 1
if [ -z "$choice" ]; then
    choice=1
fi

# Define a function to set NEXT_PUBLIC_API_URL and clear other environment variables
set_next_public_api_url_in_yml() {
    read -p "Please enter NEXT_PUBLIC_API_URL (e.g., https://api.example.com): " api_url
    if [ -z "$api_url" ]; then
        echo "NEXT_PUBLIC_API_URL cannot be empty. Please rerun the script and enter a valid URL."
        echo "NEXT_PUBLIC_API_URL 不能为空，请重新运行脚本并输入有效的 URL。"
        exit 1
    fi
    yml_file=$1

    # Backup the original yml file
    cp "$yml_file" "${yml_file}.bak"

    # Initialize flag
    in_environment_section=0

    # Create a temporary file
    temp_file=$(mktemp)

    while IFS= read -r line; do
        # Check if entering the environment section
        if [[ $line =~ ^[[:space:]]*environment: ]]; then
            echo "$line" >> "$temp_file"
            in_environment_section=1
            continue
        fi

        # If in the environment section
        if [[ $in_environment_section -eq 1 ]]; then
            # Check if it's the next top-level key
            if [[ $line =~ ^[[:space:]]*[^[:space:]-] ]]; then
                # Leaving the environment section
                in_environment_section=0
            elif [[ $line =~ ^[[:space:]]*-[[:space:]]*([A-Za-z0-9_]+)= ]]; then
                var_name="${BASH_REMATCH[1]}"
                # If it's NEXT_PUBLIC_API_URL, set to user-provided value
                if [[ $var_name == "NEXT_PUBLIC_API_URL" ]]; then
                    echo "      - NEXT_PUBLIC_API_URL=$api_url" >> "$temp_file"
                else
                    # Other variables, set value to empty string
                    echo "      - $var_name=" >> "$temp_file"
                fi
                continue
            else
                # Other lines, copy directly
                echo "$line" >> "$temp_file"
                continue
            fi
        fi

        # Copy other lines
        echo "$line" >> "$temp_file"
    done < "$yml_file"

    # Replace the original yml file with the modified one
    mv "$temp_file" "$yml_file"
}

case $choice in
    1)
        echo "Starting one-click deployment of all components..."
        echo "开始一键部署所有组件..."
        # Set NEXT_PUBLIC_API_URL and update related yml files
        set_next_public_api_url_in_yml "docker-compose.yml"
        # Prompt user to modify configuration files
        echo "Please modify the following configuration files according to your needs before continuing:"
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/docker-compose.yml"
        echo "请根据实际需求修改以下配置文件，然后再继续部署："
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/docker-compose.yml"
        read -p "After modification, press Enter to continue... / 修改完成后，按回车键继续..."
        docker compose up -d
        ;;
    2)
        echo "Starting deployment of the server..."
        echo "开始部署服务端..."
        # Prompt user to modify configuration files
        echo "Please modify the following configuration files according to your needs before continuing:"
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/ppanel-server.yml"
        echo "请根据实际需求修改以下配置文件，然后再继续部署："
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/ppanel-server.yml"
        read -p "After modification, press Enter to continue... / 修改完成后，按回车键继续..."
        docker compose -f ppanel-server.yml up -d
        ;;
    3)
        echo "Starting deployment of the admin dashboard..."
        echo "开始部署管理端..."
        set_next_public_api_url_in_yml "ppanel-admin-web.yml"
        echo "Please modify the following configuration files according to your needs before continuing:"
        echo "- ppanel-script/ppanel-admin-web.yml"
        echo "请根据实际需求修改以下配置文件，然后再继续部署："
        echo "- ppanel-script/ppanel-admin-web.yml"
        read -p "After modification, press Enter to continue... / 修改完成后，按回车键继续..."
        docker compose -f ppanel-admin-web.yml up -d
        ;;
    4)
        echo "Starting deployment of the user dashboard..."
        echo "开始部署用户端..."
        set_next_public_api_url_in_yml "ppanel-user-web.yml"
        echo "Please modify the following configuration files according to your needs before continuing:"
        echo "- ppanel-script/ppanel-user-web.yml"
        echo "请根据实际需求修改以下配置文件，然后再继续部署："
        echo "- ppanel-script/ppanel-user-web.yml"
        read -p "After modification, press Enter to continue... / 修改完成后，按回车键继续..."
        docker compose -f ppanel-user-web.yml up -d
        ;;
    5)
        echo "Starting deployment of the front-end (Admin and User dashboards)..."
        echo "开始部署前端（管理端和用户端）..."
        set_next_public_api_url_in_yml "ppanel-web.yml"
        echo "Please modify the following configuration files according to your needs before continuing:"
        echo "- ppanel-script/ppanel-web.yml"
        echo "请根据实际需求修改以下配置文件，然后再继续部署："
        echo "- ppanel-script/ppanel-web.yml"
        read -p "After modification, press Enter to continue... / 修改完成后，按回车键继续..."
        docker compose -f ppanel-web.yml up -d
        ;;
    6)
        echo "Updating running services..."
        echo "正在更新正在运行的服务..."
        # Get a list of running containers and their compose project names
        mapfile -t running_projects < <(docker ps --format '{{.Label "com.docker.compose.project"}}' | sort | uniq)
        if [ ${#running_projects[@]} -eq 0 ]; then
            echo "No running services detected."
            echo "未检测到正在运行的服务。"
        else
            for project in "${running_projects[@]}"; do
                if [ -z "$project" ]; then
                    continue
                fi
                echo "Updating services in project: $project"
                echo "正在更新项目中的服务：$project"
                docker compose -p "$project" pull
                docker compose -p "$project" up -d
            done
            echo "All running services have been updated."
            echo "所有正在运行的服务已更新。"
        fi
        ;;
    7)
        echo "Restarting running services..."
        echo "正在重启正在运行的服务..."
        # Get a list of running containers and their compose project names
        mapfile -t running_projects < <(docker ps --format '{{.Label "com.docker.compose.project"}}' | sort | uniq)
        if [ ${#running_projects[@]} -eq 0 ]; then
            echo "No running services detected."
            echo "未检测到正在运行的服务。"
        else
            for project in "${running_projects[@]}"; do
                if [ -z "$project" ]; then
                    continue
                fi
                echo "Restarting services in project: $project"
                echo "正在重启项目中的服务：$project"
                docker compose -p "$project" restart
            done
            echo "All running services have been restarted."
            echo "所有正在运行的服务已重启。"
        fi
        ;;
    8)
        echo "Viewing logs..."
        echo "查看日志..."
        echo "You can press Ctrl+C to exit log viewing."
        echo "您可以按 Ctrl+C 退出日志查看。"
        docker compose logs -f
        ;;
    9)
        echo "Exiting the installation script."
        echo "退出安装脚本。"
        exit 0
        ;;
    *)
        echo "Invalid option, please rerun the script and select a valid number (1-9)."
        echo "无效的选项，请重新运行脚本并选择正确的数字（1-9）。"
        exit 1
        ;;
esac

# Deployment completion information (for deployment options)
if [[ "$choice" -ge 1 && "$choice" -le 5 ]]; then
    echo "Deployment completed!"
    echo "部署完成！"

    # Prompt access addresses
    echo ""
    echo "Please use the following addresses to access the deployed services:"
    echo "请使用以下地址访问已部署的服务："
    if [ "$choice" == "1" ] || [ "$choice" == "2" ]; then
        echo "Server (API) / 服务端（API）：http://$SERVER_IP:8080"
    fi
    if [ "$choice" == "1" ] || [ "$choice" == "3" ]; then
        echo "Admin Dashboard / 管理端：http://$SERVER_IP:3000"
    fi
    if [ "$choice" == "1" ] || [ "$choice" == "4" ]; then
        echo "User Dashboard / 用户端：http://$SERVER_IP:3001"
    fi
    if [ "$choice" == "5" ]; then
        echo "Admin Dashboard / 管理端：http://$SERVER_IP:3000"
        echo "User Dashboard / 用户端：http://$SERVER_IP:3001"
    fi

    # Display default admin account information (only for options 1 or 2)
    if [ "$choice" == "1" ] || [ "$choice" == "2" ]; then
        echo ""
        echo "Default Admin Account / 默认管理员账户："
        echo "Username / 用户名: admin@ppanel.dev"
        echo "Password / 密码: admin-password"
        echo "Please change the default password after the first login to ensure security."
        echo "请在首次登录后及时修改默认密码以确保安全。"
    fi

    # Display service status
    echo ""
    echo "You can check the service status using the following command:"
    echo "您可以使用以下命令查看服务运行状态："
    echo "docker compose ps"
fi
