#!/bin/bash
# Orbiloop 戒指模拟器 → GitHub Pages 部署
# 用法：在终端执行  bash deploy.sh
# 第一次需要粘贴 GitHub Personal Access Token（带 repo 权限），之后会保存在本地 .gh_token

set -e
cd "$(dirname "$0")"

REPO_NAME="orbiloop-sim"
API="https://api.github.com"
TOKEN_FILE=".gh_token"

echo "========================================"
echo "  Orbiloop 模拟器 → GitHub Pages"
echo "========================================"
echo ""

# ---------- 1. 取得 token ----------
if [ -f "$TOKEN_FILE" ]; then
  TOKEN=$(cat "$TOKEN_FILE")
  echo "使用本地已保存的 token（$TOKEN_FILE）"
else
  echo "需要一个 GitHub Personal Access Token，权限勾 repo 即可。"
  echo "生成地址: https://github.com/settings/tokens  →  Generate new token (classic)"
  echo ""
  read -rsp "粘贴 token（输入时不显示）: " TOKEN
  echo ""
  if [ -z "$TOKEN" ]; then
    echo "!! 没有输入 token，退出"
    exit 1
  fi
  printf '%s' "$TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo "token 已保存到 $TOKEN_FILE（权限 600，不会提交到仓库）"
fi
echo ""

# ---------- 2. 验证 token，取用户名 ----------
USER_JSON=$(curl -s -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" "$API/user")
USER=$(printf '%s' "$USER_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin).get('login',''))" 2>/dev/null || echo "")
if [ -z "$USER" ]; then
  echo "!! token 无效或已过期。返回内容："
  printf '%s\n' "$USER_JSON" | head -5
  rm -f "$TOKEN_FILE"
  exit 1
fi
echo "GitHub 账号: $USER"
echo ""

# ---------- 3. 创建仓库（已存在则跳过） ----------
CODE=$(curl -s -o /tmp/orbiloop_gh_create.json -w "%{http_code}" -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "$API/user/repos" \
  -d "{\"name\":\"$REPO_NAME\",\"description\":\"Orbiloop ring display simulator\",\"private\":false}")

if [ "$CODE" = "201" ]; then
  echo "仓库已创建: $USER/$REPO_NAME"
elif [ "$CODE" = "422" ]; then
  echo "仓库 $USER/$REPO_NAME 已存在，直接更新"
else
  echo "!! 创建仓库失败（HTTP $CODE）"
  head -c 400 /tmp/orbiloop_gh_create.json
  echo ""
  exit 1
fi
echo ""

# ---------- 4. 推代码 ----------
if [ ! -d .git ]; then
  git init -q
fi
git config user.name "$USER"
git config user.email "$USER@users.noreply.github.com"
git add -A
if git diff --cached --quiet; then
  echo "没有文件改动"
else
  git commit -qm "deploy: Orbiloop ring simulator $(date '+%Y-%m-%d %H:%M')"
  echo "已提交"
fi
git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "https://$USER:$TOKEN@github.com/$USER/$REPO_NAME.git"
git push -u origin main --force
# 推送完成后把 token 从 remote URL 里移除，避免留在 .git/config
git remote set-url origin "https://github.com/$USER/$REPO_NAME.git"
echo "代码已推送"
echo ""

# ---------- 5. 启用 Pages ----------
CODE=$(curl -s -o /tmp/orbiloop_gh_pages.json -w "%{http_code}" -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "$API/repos/$USER/$REPO_NAME/pages" \
  -d '{"source":{"branch":"main","path":"/"}}')

if [ "$CODE" = "201" ]; then
  echo "GitHub Pages 已启用"
elif [ "$CODE" = "409" ]; then
  echo "GitHub Pages 之前已启用"
else
  echo "!! 启用 Pages 失败（HTTP $CODE）"
  head -c 400 /tmp/orbiloop_gh_pages.json
  echo ""
  echo "可以手动开：https://github.com/$USER/$REPO_NAME/settings/pages"
fi
echo ""

echo "========================================"
echo "  访问地址："
echo "  https://$USER.github.io/$REPO_NAME/"
echo ""
echo "  首次生效需要 1~2 分钟"
echo "  以后改了模拟器，重新内联后跑一次本脚本即可更新"
echo "========================================"
