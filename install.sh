#!/bin/bash

# PPanel One-Click Deployment Script
# Supports selecting different service combinations for installation, automatically sets NEXT_PUBLIC_API_URL, clears other environment variables
# Prompts user to modify ppanel.yaml and corresponding Docker Compose files when deploying the server and one-click deployment
# Checks if the user is already in the ppanel-script directory
# Bilingual support (English first, then Chinese)
# Added an "Update services" option that functions similarly to "Restart services"

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root.${NC}"
  echo -e "${RED}请以 root 用户运行此脚本。${NC}"
  exit 1
fi

# Update system package index
echo -e "${GREEN}Updating system package index...${NC}"
echo -e "${GREEN}更新系统包索引...${NC}"
apt-get update -y

# Install necessary packages
# Check if curl is installed
if command -v curl >/dev/null 2>&1; then
    echo -e "${YELLOW}curl is already installed. Skipping installation.${NC}"
    echo -e "${YELLOW}检测到 curl 已安装，跳过安装步骤。${NC}"
else
    echo -e "${GREEN}Installing curl...${NC}"
    echo -e "${GREEN}正在安装 curl...${NC}"
    apt-get install -y curl
fi

# Check if git is installed
if command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}git is already installed. Skipping installation.${NC}"
    echo -e "${YELLOW}检测到 git 已安装，跳过安装步骤。${NC}"
else
    echo -e "${GREEN}Installing git...${NC}"
    echo -e "${GREEN}正在安装 git...${NC}"
    apt-get install -y git
fi

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker is already installed. Skipping installation.${NC}"
    echo -e "${YELLOW}检测到 Docker 已安装，跳过安装步骤。${NC}"
else
    # Install Docker
    echo -e "${GREEN}Installing Docker...${NC}"
    echo -e "${GREEN}正在安装 Docker...${NC}"
    curl -fsSL https://get.docker.com | bash -s -- -y
fi

# Check if in ppanel-script directory
CURRENT_DIR=${PWD##*/}
if [ "$CURRENT_DIR" != "ppanel-script" ]; then
    # Clone PPanel script repository
    echo -e "${GREEN}Cloning PPanel script repository...${NC}"
    echo -e "${GREEN}正在克隆 PPanel 脚本仓库...${NC}"
    git clone https://github.com/perfect-panel/ppanel-script.git
    cd ppanel-script
else
    echo -e "${YELLOW}Detected that you are already in the ppanel-script directory, skipping clone step.${NC}"
    echo -e "${YELLOW}检测到已在 ppanel-script 目录中，跳过克隆步骤。${NC}"
fi

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Display service component selection menu
echo -e "${CYAN}==================================================${NC}"
echo -e "${BOLD}Please select the action you want to perform:${NC}"
echo -e "${BOLD}请选择您要执行的操作：${NC}"
echo -e "${CYAN}==================================================${NC}"
echo -e "1) One-click deployment (All components) / 一键部署（全部组件）"
echo -e "2) Deploy server / 部署服务端"
echo -e "3) Deploy admin dashboard / 部署管理端"
echo -e "4) Deploy user dashboard / 部署用户端"
echo -e "5) Deploy front-end (Admin and User dashboards) / 部署前端（管理端和用户端）"
echo -e "6) Update services / 更新服务"
echo -e "7) Restart services / 重启服务"
echo -e "8) View logs / 查看日志"
echo -e "9) Exit / 退出"
echo -e "${CYAN}==================================================${NC}"

# Prompt user for selection
echo -ne "${BOLD}Please enter a number (1-9): ${NC}"
read choice
# If the user does not input, default to 1
if [ -z "$choice" ]; then
    choice=1
fi

# Define a function to set NEXT_PUBLIC_API_URL
set_next_public_api_url_in_yml() {
    echo -ne "${BOLD}Please enter NEXT_PUBLIC_API_URL (e.g., https://api.example.com): ${NC}"
    read api_url
    if [ -z "$api_url" ]; then
        echo -e "${RED}NEXT_PUBLIC_API_URL cannot be empty. Please rerun the script and enter a valid URL.${NC}"
        echo -e "${RED}NEXT_PUBLIC_API_URL 不能为空，请重新运行脚本并输入有效的 URL。${NC}"
        exit 1
    fi
    yml_file=$1

    # Backup the original yml file
    cp "$yml_file" "${yml_file}.bak"

    # Create a temporary file
    temp_file=$(mktemp)

    # Initialize flag
    in_environment_section=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if entering the environment section
        if [[ $line =~ ^[[:space:]]*environment: ]]; then
            echo "$line" >> "$temp_file"
            in_environment_section=1
            continue
        fi

        # If in the environment section
        if [[ $in_environment_section -eq 1 ]]; then
            # Check if it's the next top-level key (without indentation)
            if [[ $line =~ ^[[:space:]]{0,2}[a-zA-Z0-9_-]+: ]]; then
                in_environment_section=0
            elif [[ $line =~ ^([[:space:]]*)(NEXT_PUBLIC_API_URL): ]]; then
                indentation="${BASH_REMATCH[1]}"
                var_name="${BASH_REMATCH[2]}"
                # Set NEXT_PUBLIC_API_URL to user-provided value
                echo "${indentation}${var_name}: $api_url" >> "$temp_file"
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
        echo -e "${GREEN}Starting one-click deployment of all components...${NC}"
        echo -e "${GREEN}开始一键部署所有组件...${NC}"
        # Set NEXT_PUBLIC_API_URL and update related yml files
        set_next_public_api_url_in_yml "docker-compose.yml"
        # Prompt user to modify configuration files
        echo -e "${YELLOW}Please modify the following configuration files according to your needs before continuing:${NC}"
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/docker-compose.yml"
        echo -e "${YELLOW}请根据实际需求修改以下配置文件，然后再继续部署：${NC}"
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/docker-compose.yml"
        echo -ne "${BOLD}After modification, press Enter to continue... / 修改完成后，按回车键继续...${NC}"
        read
        docker compose up -d
        ;;
    2)
        echo -e "${GREEN}Starting deployment of the server...${NC}"
        echo -e "${GREEN}开始部署服务端...${NC}"
        # Prompt user to modify configuration files
        echo -e "${YELLOW}Please modify the following configuration files according to your needs before continuing:${NC}"
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/ppanel-server.yml"
        echo -e "${YELLOW}请根据实际需求修改以下配置文件，然后再继续部署：${NC}"
        echo "- ppanel-script/config/ppanel.yaml"
        echo "- ppanel-script/ppanel-server.yml"
        echo -ne "${BOLD}After modification, press Enter to continue... / 修改完成后，按回车键继续...${NC}"
        read
        docker compose -f ppanel-server.yml up -d
        ;;
    3)
        echo -e "${GREEN}Starting deployment of the admin dashboard...${NC}"
        echo -e "${GREEN}开始部署管理端...${NC}"
        set_next_public_api_url_in_yml "ppanel-admin-web.yml"
        echo -e "${YELLOW}Please modify the following configuration files according to your needs before continuing:${NC}"
        echo "- ppanel-script/ppanel-admin-web.yml"
        echo -e "${YELLOW}请根据实际需求修改以下配置文件，然后再继续部署：${NC}"
        echo "- ppanel-script/ppanel-admin-web.yml"
        echo -ne "${BOLD}After modification, press Enter to continue... / 修改完成后，按回车键继续...${NC}"
        read
        docker compose -f ppanel-admin-web.yml up -d
        ;;
    4)
        echo -e "${GREEN}Starting deployment of the user dashboard...${NC}"
        echo -e "${GREEN}开始部署用户端...${NC}"
        set_next_public_api_url_in_yml "ppanel-user-web.yml"
        echo -e "${YELLOW}Please modify the following configuration files according to your needs before continuing:${NC}"
        echo "- ppanel-script/ppanel-user-web.yml"
        echo -e "${YELLOW}请根据实际需求修改以下配置文件，然后再继续部署：${NC}"
        echo "- ppanel-script/ppanel-user-web.yml"
        echo -ne "${BOLD}After modification, press Enter to continue... / 修改完成后，按回车键继续...${NC}"
        read
        docker compose -f ppanel-user-web.yml up -d
        ;;
    5)
        echo -e "${GREEN}Starting deployment of the front-end (Admin and User dashboards)...${NC}"
        echo -e "${GREEN}开始部署前端（管理端和用户端）...${NC}"
        set_next_public_api_url_in_yml "ppanel-web.yml"
        echo -e "${YELLOW}Please modify the following configuration files according to your needs before continuing:${NC}"
        echo "- ppanel-script/ppanel-web.yml"
        echo -e "${YELLOW}请根据实际需求修改以下配置文件，然后再继续部署：${NC}"
        echo "- ppanel-script/ppanel-web.yml"
        echo -ne "${BOLD}After modification, press Enter to continue... / 修改完成后，按回车键继续...${NC}"
        read
        docker compose -f ppanel-web.yml up -d
        ;;
    6)
        echo -e "${GREEN}Updating running services...${NC}"
        echo -e "${GREEN}正在更新正在运行的服务...${NC}"
        # Get a list of running containers and their compose project names
        mapfile -t running_projects < <(docker ps --format '{{.Label "com.docker.compose.project"}}' | sort | uniq)
        if [ ${#running_projects[@]} -eq 0 ]; then
            echo -e "${YELLOW}No running services detected.${NC}"
            echo -e "${YELLOW}未检测到正在运行的服务。${NC}"
        else
            for project in "${running_projects[@]}"; do
                if [ -z "$project" ]; then
                    continue
                fi
                echo -e "${GREEN}Updating services in project: $project${NC}"
                echo -e "${GREEN}正在更新项目中的服务：$project${NC}"
                docker compose -p "$project" pull
                docker compose -p "$project" up -d
            done
            echo -e "${GREEN}All running services have been updated.${NC}"
            echo -e "${GREEN}所有正在运行的服务已更新。${NC}"
        fi
        ;;
    7)
        echo -e "${GREEN}Restarting running services...${NC}"
        echo -e "${GREEN}正在重启正在运行的服务...${NC}"
        # Get a list of running containers and their compose project names
        mapfile -t running_projects < <(docker ps --format '{{.Label "com.docker.compose.project"}}' | sort | uniq)
        if [ ${#running_projects[@]} -eq 0 ]; then
            echo -e "${YELLOW}No running services detected.${NC}"
            echo -e "${YELLOW}未检测到正在运行的服务。${NC}"
        else
            for project in "${running_projects[@]}"; do
                if [ -z "$project" ]; then
                    continue
                fi
                echo -e "${GREEN}Restarting services in project: $project${NC}"
                echo -e "${GREEN}正在重启项目中的服务：$project${NC}"
                docker compose -p "$project" restart
            done
            echo -e "${GREEN}All running services have been restarted.${NC}"
            echo -e "${GREEN}所有正在运行的服务已重启。${NC}"
        fi
        ;;
    8)
        echo -e "${GREEN}Viewing logs...${NC}"
        echo -e "${GREEN}查看日志...${NC}"
        echo -e "${YELLOW}You can press Ctrl+C to exit log viewing.${NC}"
        echo -e "${YELLOW}您可以按 Ctrl+C 退出日志查看。${NC}"
        docker compose logs -f
        ;;
    9)
        echo -e "${GREEN}Exiting the installation script.${NC}"
        echo -e "${GREEN}退出安装脚本。${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option, please rerun the script and select a valid number (1-9).${NC}"
        echo -e "${RED}无效的选项，请重新运行脚本并选择正确的数字（1-9）。${NC}"
        exit 1
        ;;
esac

# Deployment completion information (for deployment options)
if [[ "$choice" -ge 1 && "$choice" -le 5 ]]; then
    echo -e "${GREEN}Deployment completed!${NC}"
    echo -e "${GREEN}部署完成！${NC}"

    # Prompt access addresses
    echo ""
    echo -e "${BOLD}Please use the following addresses to access the deployed services:${NC}"
    echo -e "${BOLD}请使用以下地址访问已部署的服务：${NC}"
    if [ "$choice" == "1" ] || [ "$choice" == "2" ]; then
        echo -e "Server (API) / 服务端（API）：${CYAN}http://$SERVER_IP:8080${NC}"
    fi
    if [ "$choice" == "1" ] || [ "$choice" == "3" ]; then
        echo -e "Admin Dashboard / 管理端：${CYAN}http://$SERVER_IP:3000${NC}"
    fi
    if [ "$choice" == "1" ] || [ "$choice" == "4" ]; then
        echo -e "User Dashboard / 用户端：${CYAN}http://$SERVER_IP:3001${NC}"
    fi
    if [ "$choice" == "5" ]; then
        echo -e "Admin Dashboard / 管理端：${CYAN}http://$SERVER_IP:3000${NC}"
        echo -e "User Dashboard / 用户端：${CYAN}http://$SERVER_IP:3001${NC}"
    fi

    # Display default admin account information (only for options 1 or 2)
    if [ "$choice" == "1" ] || [ "$choice" == "2" ]; then
        echo ""
        echo -e "${BOLD}Default Admin Account / 默认管理员账户：${NC}"
        echo -e "Username / 用户名: ${CYAN}admin@ppanel.dev${NC}"
        echo -e "Password / 密码: ${CYAN}password${NC}"
        echo -e "${YELLOW}Please change the default password after the first login to ensure security.${NC}"
        echo -e "${YELLOW}请在首次登录后及时修改默认密码以确保安全。${NC}"
    fi

    # Display service status
    echo ""
    echo -e "${BOLD}You can check the service status using the following command:${NC}"
    echo -e "${BOLD}您可以使用以下命令查看服务运行状态：${NC}"
    echo -e "${CYAN}docker compose ps${NC}"
fi
