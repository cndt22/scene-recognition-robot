#!/bin/bash
# 安装 scene_recognition_robot 编译与仿真所需依赖（Ubuntu 18.04 + ROS Melodic）
set -e
sudo apt update
sudo apt install -y \
  ros-melodic-move-base-msgs \
  ros-melodic-move-base \
  ros-melodic-map-server \
  ros-melodic-amcl \
  ros-melodic-gazebo-ros-pkgs \
  ros-melodic-turtlebot3 \
  ros-melodic-turtlebot3-gazebo \
  ros-melodic-turtlebot3-navigation \
  ros-melodic-robot-state-publisher \
  ros-melodic-xacro \
  ros-melodic-rviz \
  python3-yaml \
  python3-rospkg \
  python-rospkg \
  espeak-ng \
  espeak-ng-data \
  dos2unix
echo "依赖安装完成"
