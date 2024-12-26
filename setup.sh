#!/bin/bash

# 显示功能选择菜单
echo "请选择要执行的功能："
echo "1) 安装"
echo "2) 增加规则"

read -p "请输入选择 (1 或 2): " choice

# 功能 1: 执行原来的功能
if [ "$choice" == "1" ]; then
    echo "正在安装..."

    # 检查并安装 git
    if ! command -v git &> /dev/null; then
        echo "git 未安装，正在安装..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y git
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y git
        else
            echo "无法识别系统，无法安装 git。请手动安装 git。"
            exit 1
        fi
    else
        echo "git 已安装，跳过安装过程。"
    fi

    # 检查并安装 curl
    if ! command -v curl &> /dev/null; then
        echo "curl 未安装，正在安装..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y curl
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y curl
        else
            echo "无法识别系统，无法安装 curl。请手动安装 curl。"
            exit 1
        fi
    else
        echo "curl 已安装，跳过安装过程。"
    fi

    # 检查并安装 docker
    if ! command -v docker &> /dev/null; then
        echo "docker 未安装，正在安装..."
        if [ -f /etc/debian_version ]; then
            sudo apt update
            sudo apt install -y docker.io
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y docker
        else
            echo "无法识别系统，无法安装 docker。请手动安装 docker。"
            exit 1
        fi
        # 启动 docker 服务并设置开机自启
        sudo systemctl start docker
        sudo systemctl enable docker

        # 验证 Docker 是否成功启动
        if ! systemctl is-active --quiet docker; then
            echo "Docker 启动失败，请检查日志。"
            exit 1
        fi
    else
        echo "docker 已安装，跳过安装过程。"
    fi

    # 检查并安装 docker-compose
    if ! command -v docker-compose &> /dev/null; then
        echo "docker-compose 未安装，正在安装..."

        # 检查系统架构
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            DOWNLOAD_URL="https://github.com/docker/compose/releases/download/v2.18.0/docker-compose-$(uname -s)-$(uname -m)"
        else
            echo "暂不支持此架构安装 Docker Compose。"
            exit 1
        fi

        # 下载并安装 Docker Compose
        sudo curl -L "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        # 验证是否安装成功
        if command -v docker-compose &> /dev/null; then
            echo "docker-compose 安装成功！"
        else
            echo "docker-compose 安装失败，请检查日志。"
            exit 1
        fi
    else
        echo "docker-compose 已安装，跳过安装过程。"
    fi

    # 创建新文件夹并进入
    FOLDER_NAME="paolu"
    mkdir -p "$FOLDER_NAME"
    cd "$FOLDER_NAME" || { echo "无法进入目录 $FOLDER_NAME"; exit 1; }

    # 克隆仓库
    echo "正在克隆仓库..."
    git clone https://github.com/XrayR-project/XrayR-release .
    cd config

    # 下载配置文件
    CONFIG_FILE="config.yml"
    echo "正在下载配置文件..."
    curl -o "$CONFIG_FILE" https://raw.githubusercontent.com/mps233/subweb/refs/heads/vercel/config.yml

    # 让用户输入 NodeID
    read -p "请输入新的 NodeID 数字: " NODE_ID

    # 更新配置文件
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "正在更新配置文件中的 NodeID..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS 上的 sed 语法
            sed -i '' "s/NodeID:.*/NodeID: $NODE_ID/" "$CONFIG_FILE"
        else
            # Linux 上的 sed 语法
            sed -i "s/NodeID:.*/NodeID: $NODE_ID/" "$CONFIG_FILE"
        fi
    else
        echo "配置文件未找到！"
        exit 1
    fi

    # 安装 chrony 同步时间
    echo "正在安装 chrony 同步时间..."
    sudo apt install chrony -y

    # 启动 Docker 容器
    echo "正在启动 Docker 容器..."
    docker-compose up -d

    echo "原来的功能执行完成！"
fi

# 功能 2: 执行新增的功能（更新 RouteConfigPath 和 OutboundConfigPath）
if [ "$choice" == "2" ]; then
    echo "正在增加规则..."

    cd /root/paolu/config

    CONFIG_FILE="config.yml"

    # 在 config.yml 文件中更新 RouteConfigPath 和 OutboundConfigPath
    echo "正在更新 RouteConfigPath 和 OutboundConfigPath..."

    # 添加 RouteConfigPath 和 OutboundConfigPath
    sed -i "s|RouteConfigPath:.*|RouteConfigPath: /etc/XrayR/route.json|" "$CONFIG_FILE"
    sed -i "s|OutboundConfigPath:.*|OutboundConfigPath: /etc/XrayR/custom_outbound.json|" "$CONFIG_FILE"

    # 替换文件
    rm -f route.json && curl -o route.json https://raw.githubusercontent.com/mps233/subweb/refs/heads/vercel/route.json
    rm -f custom_outbound.json && curl -o custom_outbound.json https://raw.githubusercontent.com/mps233/subweb/refs/heads/vercel/custom_outbound.json

    # 重启 Docker 容器
    echo "正在重启 Docker 容器..."
    docker restart paolu-xrayr-1

    echo "新增规则执行完成！"
fi



# 启动 Docker 容器
echo "正在启动 Docker 容器..."
docker-compose up -d

echo "脚本执行完成！"


