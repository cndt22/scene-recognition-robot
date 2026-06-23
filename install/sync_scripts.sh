#!/bin/bash
# 将最新 Python 脚本同步到 catkin devel（解决 catkin_make 未更新脚本的问题）
set -e
PKG_SRC="${1:-$HOME/scene-recognition-robot/src/scene_recognition_robot}"
DEVEL_LIB="${2:-$HOME/catkin_ws/devel/lib/scene_recognition_robot}"

if [ ! -d "$PKG_SRC/scripts" ]; then
  echo "错误: 找不到 $PKG_SRC/scripts"
  exit 1
fi

mkdir -p "$DEVEL_LIB"
cp -f "$PKG_SRC/scripts/"*.py "$DEVEL_LIB/"
chmod +x "$DEVEL_LIB/"*.py

echo "已同步到: $DEVEL_LIB"
grep -q "中文物体映射" "$DEVEL_LIB/scene_inference_node.py" && echo "scene_inference_node.py 已是中文版" || echo "警告: 仍不是中文版，请 git pull"
