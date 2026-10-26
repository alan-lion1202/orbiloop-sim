#!/bin/bash
# 一键更新：把改好的模拟器内联 → 复制到部署目录 → 推到 GitHub Pages
# 用法：bash 更新并部署.sh
# 日常改完 戒指3D模拟器.html 后跑这一个脚本就行

set -e
cd "$(dirname "$0")/.."

echo "【1/2】内联打包"
python3 内联打包.py
echo ""

echo "【2/2】推送到 GitHub Pages"
cd 在线部署
bash deploy.sh
