#!/bin/bash
# ROS 环境 + 依赖安装 + 编译（项目文件已创建后运行）
set -e

BASE="$HOME/scene-recognition-robot"
cd "$BASE"

echo "[1/5] 更新系统..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget build-essential python3-pip lsb-release

echo "[2/5] 安装 ROS Noetic..."
if ! rosversion -d 2>/dev/null | grep -q noetic; then
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
  sudo apt update
  sudo apt install -y ros-noetic-desktop-full
  grep -q "noetic/setup.bash" ~/.bashrc || echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
  sudo apt install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool
  sudo rosdep init 2>/dev/null || true
  rosdep update
fi
source /opt/ros/noetic/setup.bash

echo "[3/5] 安装项目依赖..."
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

echo "[4/5] Python 依赖 + 编译..."
pip3 install --user PyYAML 2>/dev/null || pip3 install PyYAML
chmod +x src/scene_recognition_robot/scripts/*.py
rosdep install --from-paths src --ignore-src -r -y || true
catkin_make
grep -q "scene-recognition-robot/devel/setup.bash" ~/.bashrc || \
  echo "source $BASE/devel/setup.bash" >> ~/.bashrc
source devel/setup.bash

echo "[5/5] 验证..."
rospack find scene_recognition_robot
echo ""
echo "===== 全部完成 ====="
echo "运行仿真:"
echo "  source /opt/ros/noetic/setup.bash"
echo "  source ~/scene-recognition-robot/devel/setup.bash"
echo "  export TURTLEBOT3_MODEL=waffle_pi"
echo "  roslaunch scene_recognition_robot gazebo_sim.launch"
