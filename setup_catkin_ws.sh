#!/bin/bash
# 初始化 catkin 工作空间（仅需运行一次）
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE"

source /opt/ros/melodic/setup.bash

# src/ 下 CMakeLists.txt
if [ ! -f src/CMakeLists.txt ]; then
  catkin_init_workspace src
fi

# 工作空间根目录必须是 toplevel.cmake 软链接
if [ ! -L CMakeLists.txt ]; then
  rm -f CMakeLists.txt
  ln -s /opt/ros/melodic/share/catkin/cmake/toplevel.cmake CMakeLists.txt
fi

echo "工作空间已就绪，请执行: catkin_make && source devel/setup.bash"
