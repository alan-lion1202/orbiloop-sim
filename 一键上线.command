#!/bin/bash
# 双击这个文件即可：内联打包 → 推送到 GitHub Pages
# 首次运行会要求粘贴一次 GitHub Token，之后自动使用本地保存的
cd "$(dirname "$0")"
bash 更新并部署.sh
echo ""
echo "按回车关闭窗口"
read -r _
