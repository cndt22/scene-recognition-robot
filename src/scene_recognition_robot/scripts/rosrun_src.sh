#!/bin/bash
# 始终从 package/scripts/ 源码运行 Python 节点（避免 devel 旧脚本）
PKG="$(rospack find scene_recognition_robot)"
NODE="$1"
shift
exec python3 "${PKG}/scripts/${NODE}" "$@"
