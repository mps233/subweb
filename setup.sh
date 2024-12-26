#!/bin/bash

# 创建新文件夹并进入
FOLDER_NAME="paolu"
mkdir -p "$FOLDER_NAME"
cd "$FOLDER_NAME" || { echo "无法进入目录 $FOLDER_NAME"; exit 1; }

# 克隆仓库
echo "正在克隆仓库..."
git clone https://github.com/XrayR-project/XrayR-release .

# 下载配置文件
CONFIG_FILE="config.yml"
echo "正在下载配置文件..."
curl -o "$CONFIG_FILE" https://raw.githubusercontent.com/mps233/subweb/refs/heads/vercel/config.yml

# 让用户输入 NodeID
read -p "请输入新的 NodeID 数字: " NODE_ID

# 更新配置文件
if [[ -f "$CONFIG_FILE" ]]; then
    echo "正在更新配置文件中的 NodeID..."
    sed -i "s/NodeID:.*/NodeID: $NODE_ID/" "$CONFIG_FILE"
else
    echo "配置文件未找到！"
    exit 1
fi

# 启动 Docker 容器
echo "正在启动 Docker 容器..."
docker-compose up -d

echo "脚本执行完成！"
