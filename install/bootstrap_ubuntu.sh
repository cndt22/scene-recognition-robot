#!/bin/bash
# scene-recognition-robot Ubuntu 一键安装脚本
# 用法: bash install/bootstrap_ubuntu.sh
set -e

PROJECT_DIR="$HOME/scene-recognition-robot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo " 场景识别机器人 - Ubuntu 一键安装"
echo "========================================"

# ---------- 检查 Ubuntu 20.04 ----------
if ! grep -q "20.04" /etc/os-release 2>/dev/null; then
  echo "[警告] 建议使用 Ubuntu 20.04。当前系统:"
  lsb_release -a || cat /etc/os-release
  read -p "继续? (y/n) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# ---------- 1. 系统更新 ----------
echo "[1/7] 更新系统..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget git build-essential python3-pip lsb-release

# ---------- 2. 安装 ROS Noetic ----------
if ! rosversion -d 2>/dev/null | grep -q noetic; then
  echo "[2/7] 安装 ROS Noetic（约 20-40 分钟）..."
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
  sudo apt update
  sudo apt install -y ros-noetic-desktop-full
  grep -q "noetic/setup.bash" ~/.bashrc || echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
  sudo apt install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool
  sudo rosdep init 2>/dev/null || true
  rosdep update
else
  echo "[2/7] ROS Noetic 已安装，跳过"
fi
source /opt/ros/noetic/setup.bash

# ---------- 3. 安装项目依赖 ----------
echo "[3/7] 安装 ROS 功能包与语音..."
sudo apt install -y \
  ros-noetic-navigation ros-noetic-move-base ros-noetic-map-server \
  ros-noetic-amcl ros-noetic-dwa-local-planner \
  ros-noetic-gazebo-ros-pkgs ros-noetic-gazebo-ros-control \
  ros-noetic-turtlebot3 ros-noetic-turtlebot3-gazebo \
  ros-noetic-turtlebot3-navigation ros-noetic-turtlebot3-description \
  ros-noetic-cv-bridge ros-noetic-vision-msgs ros-noetic-xacro \
  ros-noetic-robot-state-publisher ros-noetic-rviz espeak espeak-data

grep -q TURTLEBOT3_MODEL ~/.bashrc || echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc
export TURTLEBOT3_MODEL=waffle_pi

# ---------- 4. 解压项目 ----------
echo "[4/7] 创建项目..."
if [ -f "$SCRIPT_DIR/project.tar.gz" ]; then
  mkdir -p "$PROJECT_DIR"
  tar -xzf "$SCRIPT_DIR/project.tar.gz" -C "$PROJECT_DIR"
elif [ -f "$SCRIPT_DIR/project.tar.gz.b64" ]; then
  mkdir -p "$PROJECT_DIR"
  base64 -d "$SCRIPT_DIR/project.tar.gz.b64" | tar -xzf - -C "$PROJECT_DIR"
else
  echo "[错误] 未找到 project.tar.gz，请使用 git clone 获取完整项目"
  exit 1
fi

# ---------- 5. Python 依赖 ----------
echo "[5/7] 安装 Python 依赖..."
pip3 install --user PyYAML 2>/dev/null || pip3 install PyYAML

# ---------- 6. 编译 ----------
echo "[6/7] 编译 ROS 工作空间..."
cd "$PROJECT_DIR"
chmod +x src/scene_recognition_robot/scripts/*.py
rosdep install --from-paths src --ignore-src -r -y || true
catkin_make
grep -q "scene-recognition-robot/devel/setup.bash" ~/.bashrc || \
  echo "source $PROJECT_DIR/devel/setup.bash" >> ~/.bashrc
source devel/setup.bash

# ---------- 7. 验证 ----------
echo "[7/7] 验证安装..."
rospack find scene_recognition_robot

echo ""
echo "========================================"
echo " 安装完成!"
echo "========================================"
echo ""
echo "每次运行仿真前执行:"
echo "  source /opt/ros/noetic/setup.bash"
echo "  source ~/scene-recognition-robot/devel/setup.bash"
echo "  export TURTLEBOT3_MODEL=waffle_pi"
echo ""
echo "启动 Gazebo 仿真:"
echo "  cd ~/scene-recognition-robot"
echo "  roslaunch scene_recognition_robot gazebo_sim.launch"
echo ""
