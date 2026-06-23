# 场景识别机器人 — 完整安装与运行指南

本文档是 **独立项目** 的从零开始操作手册，不依赖任何其他项目。

---

## 目录

1. [项目简介](#1-项目简介)
2. [环境要求](#2-环境要求)
3. [获取项目](#3-获取项目)
4. [安装 Ubuntu 基础环境](#4-安装-ubuntu-基础环境)
5. [安装 ROS Noetic](#5-安装-ros-noetic)
6. [安装项目依赖](#6-安装项目依赖)
7. [编译项目](#7-编译项目)
8. [运行 Gazebo 仿真](#8-运行-gazebo-仿真)
9. [观察与验证](#9-观察与验证)
10. [其他运行模式](#10-其他运行模式)
11. [常见问题](#11-常见问题)
12. [命令速查表](#12-命令速查表)

---

## 1. 项目简介

**项目名称**：scene-recognition-robot（场景识别机器人）

**课设目标**：
- 机器人进入不同房间
- 识别房间内物体
- 根据物体推断房间类型（至少 3 种）
- 识别完成后移动到指定位置
- 语音播报识别结果

**技术栈**：ROS Noetic + Gazebo + TurtleBot3 + Python

**项目结构**：

```
scene-recognition-robot/
├── SETUP.md                 ← 本文档
├── README.md                ← 项目说明
├── requirements.txt         ← Python 依赖
└── src/
    └── scene_recognition_robot/
        ├── config/          ← 场景规则、导航点、AMCL 参数
        ├── launch/          ← 启动文件
        ├── worlds/          ← Gazebo 仿真世界
        ├── maps/            ← 导航地图
        ├── msg/ srv/        ← ROS 自定义消息
        └── scripts/         ← Python 节点
```

---

## 2. 环境要求

| 项目 | 要求 |
|------|------|
| 操作系统 | **Ubuntu 20.04 LTS**（必须，与 ROS Noetic 匹配） |
| ROS 版本 | ROS Noetic |
| 内存 | ≥ 8GB（Gazebo + RViz 较占内存） |
| 磁盘 | ≥ 15GB 可用空间 |
| 网络 | 首次安装需联网下载软件包 |

> Ubuntu 22.04 对应 ROS2，**不能**运行本项目。请使用 Ubuntu 20.04 虚拟机或双系统。

---

## 3. 获取项目

将整个 `scene-recognition-robot` 文件夹复制到 Ubuntu 用户目录：

```bash
# 目标路径（推荐）
~/scene-recognition-robot/
```

**复制方式（任选其一）**：

### 方式 A：U 盘

1. 在 Windows /Mac 上将 `scene-recognition-robot` 文件夹复制到 U 盘
2. Ubuntu 插入 U 盘后执行：

```bash
cp -r /media/$USER/你的U盘名/scene-recognition-robot ~/
```

### 方式 B：虚拟机共享文件夹

```bash
cp -r /mnt/hgfs/共享文件夹/scene-recognition-robot ~/
```

### 方式 C：Git

```bash
cd ~
git clone <仓库地址> scene-recognition-robot
```

### 验证

```bash
ls ~/scene-recognition-robot/src/scene_recognition_robot/launch/
```

应能看到 `gazebo_sim.launch` 等文件。

---

## 4. 安装 Ubuntu 基础环境

### 4.1 打开终端

登录 Ubuntu 后，按 `Ctrl + Alt + T` 打开终端。

### 4.2 确认系统版本

```bash
lsb_release -a
```

输出应包含 `Ubuntu 20.04`。

### 4.3 更新系统

```bash
sudo apt update
sudo apt upgrade -y
```

### 4.4 安装基础工具

```bash
sudo apt install -y curl wget git build-essential python3-pip
```

---

## 5. 安装 ROS Noetic

> 若已安装 ROS Noetic，执行 `rosversion -d` 确认输出 `noetic` 后，跳到 [第 6 节](#6-安装项目依赖)。

### 5.1 添加 ROS 软件源

```bash
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
```

### 5.2 添加密钥

```bash
sudo apt install curl -y
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo apt update
```

### 5.3 安装 ROS（完整桌面版）

```bash
sudo apt install ros-noetic-desktop-full -y
```

> 约需 20–40 分钟，请耐心等待。

### 5.4 配置 ROS 环境变量

```bash
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

### 5.5 安装 rosdep

```bash
sudo apt install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool
sudo rosdep init
rosdep update
```

### 5.6 验证 ROS 安装

**终端 1**：

```bash
roscore
```

**终端 2**（新开一个终端）：

```bash
source /opt/ros/noetic/setup.bash
rosnode list
```

若看到 `/rosout`，说明 ROS 安装成功。

回到终端 1，按 `Ctrl + C` 停止 roscore。

---

## 6. 安装项目依赖

### 6.1 安装 ROS 功能包

```bash
sudo apt install -y \
  ros-noetic-navigation \
  ros-noetic-move-base \
  ros-noetic-map-server \
  ros-noetic-amcl \
  ros-noetic-dwa-local-planner \
  ros-noetic-gazebo-ros-pkgs \
  ros-noetic-gazebo-ros-control \
  ros-noetic-turtlebot3 \
  ros-noetic-turtlebot3-gazebo \
  ros-noetic-turtlebot3-navigation \
  ros-noetic-turtlebot3-description \
  ros-noetic-cv-bridge \
  ros-noetic-vision-msgs \
  ros-noetic-xacro \
  ros-noetic-robot-state-publisher \
  ros-noetic-rviz
```

### 6.2 安装语音播报

```bash
sudo apt install -y espeak espeak-data
```

### 6.3 设置 TurtleBot3 模型

```bash
echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc
source ~/.bashrc
```

验证：

```bash
echo $TURTLEBOT3_MODEL
# 应输出: waffle_pi
```

### 6.4 安装 Python 依赖（可选）

Gazebo 仿真默认不需要 YOLO，但建议安装 PyYAML：

```bash
cd ~/scene-recognition-robot
pip3 install PyYAML
```

若需 YOLO 视觉检测模式，再安装全部依赖：

```bash
pip3 install -r requirements.txt
```

---

## 7. 编译项目

### 7.1 进入项目目录

```bash
cd ~/scene-recognition-robot
```

### 7.2 赋予脚本执行权限

```bash
chmod +x src/scene_recognition_robot/scripts/*.py
```

### 7.3 安装 ROS 包依赖

```bash
source /opt/ros/noetic/setup.bash
rosdep install --from-paths src --ignore-src -r -y
```

### 7.4 编译

```bash
catkin_make
```

成功时末尾类似：

```
[100%] Built target scene_recognition_robot_generate_messages
```

### 7.5 加载工作空间

```bash
source devel/setup.bash
echo "source ~/scene-recognition-robot/devel/setup.bash" >> ~/.bashrc
```

### 7.6 验证编译结果

```bash
rospack find scene_recognition_robot
```

应输出：

```
/home/你的用户名/scene-recognition-robot/src/scene_recognition_robot
```

---

## 8. 运行 Gazebo 仿真

### 8.1 每次运行前的环境加载

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
```

### 8.2 启动仿真

```bash
cd ~/scene-recognition-robot
roslaunch scene_recognition_robot gazebo_sim.launch
```

### 8.3 启动后会看到

| 窗口 | 说明 |
|------|------|
| Gazebo | 10m×10m 四室房屋 + TurtleBot3 机器人 |
| RViz | 地图、激光雷达、机器人位置 |
| 终端 | 各 ROS 节点运行日志 |

### 8.4 自动任务流程

```
启动后等待 10 秒（AMCL 定位收敛）
        ↓
① 导航到卧室 (2.5, 2.5)   → 识别为「卧室」
        ↓
② 导航到餐厅 (7.5, 2.5)   → 识别为「餐厅」
        ↓
③ 导航到厨房 (2.5, 7.5)   → 识别为「厨房」
        ↓
④ 导航到客厅 (7.5, 7.5)   → 识别为「客厅」
        ↓
⑤ 导航到汇报点 (0.8, 0.8) → 语音播报全部结果
        ↓
任务完成
```

### 8.5 仿真环境布局

```
          y ↑
            |
      厨房  |  客厅
   (冰箱等) | (沙发/电视)
            |
    --------+--------→ x
            |
      卧室  |  餐厅
   (床/枕头)| (桌/椅/碗)
            |
      ★起点(0,0)  ●汇报点(0.8,0.8)
```

| 房间 | 关键物体 | 识别规则 |
|------|---------|---------|
| 卧室 | bed, pillow | 检测到床 → 卧室 |
| 餐厅 | dining table, bowl | 桌子 + 碗 → 餐厅 |
| 厨房 | refrigerator, microwave | 检测到冰箱 → 厨房 |
| 客厅 | couch, tv | 检测到沙发/电视 → 客厅 |

### 8.6 停止仿真

在 launch 终端按 `Ctrl + C`。

---

## 9. 观察与验证

启动仿真后，**另开一个终端**：

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
```

### 9.1 查看物体检测

```bash
rostopic echo /detected_objects
```

### 9.2 查看场景识别结果

```bash
rostopic echo /scene_result
```

### 9.3 查看所有 ROS 话题

```bash
rostopic list
```

### 9.4 手动测试语音

```bash
rosservice call /announce_scene "text: '当前房间是卧室' language: 'zh'"
```

### 9.5 检查激光雷达

```bash
rostopic echo /scan -n 1
```

### 9.6 检查地图

```bash
rostopic echo /map -n 1
```

---

## 10. 其他运行模式

### 10.1 无 Gazebo 快速演示

不启动 Gazebo，用 mock 数据验证识别 + 播报逻辑：

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
roslaunch scene_recognition_robot demo_mock.launch
```

### 10.2 手动调试（不自动执行任务）

```bash
roslaunch scene_recognition_robot gazebo_sim.launch run_mission:=false
```

然后在 RViz 中用 **「2D Nav Goal」** 工具手动点击目标位置。

### 10.3 无 GUI 模式（远程/低配置）

```bash
roslaunch scene_recognition_robot gazebo_sim.launch gui:=false rviz:=false
```

### 10.4 YOLO 视觉检测模式

```bash
pip3 install -r requirements.txt
roslaunch scene_recognition_robot gazebo_sim.launch use_yolo:=true
```

> Gazebo 中家具为简化几何体，YOLO 识别率较低，默认推荐使用区域真值检测。

---

## 11. 常见问题

### Q1: `roslaunch: command not found`

```bash
source /opt/ros/noetic/setup.bash
```

### Q2: `TURTLEBOT3_MODEL is not set`

```bash
export TURTLEBOT3_MODEL=waffle_pi
```

### Q3: `rospack find scene_recognition_robot` 找不到

```bash
cd ~/scene-recognition-robot
catkin_make
source devel/setup.bash
```

### Q4: Gazebo 黑屏或闪退

- 虚拟机需开启 3D 图形加速
- 内存建议 ≥ 8GB
- 单独测试：`gazebo`

### Q5: 机器人不移动

1. 确认 `echo $TURTLEBOT3_MODEL` 输出 `waffle_pi`
2. 等待至少 10 秒让 AMCL 定位收敛
3. 在 RViz 中观察粒子云是否集中在机器人附近
4. 检查激光：`rostopic hz /scan`

### Q6: 没有语音

```bash
espeak -v zh "测试语音"
```

检查系统音量。若 espeak 中文效果差，可改用 pyttsx3：

```bash
pip3 install pyttsx3
# 修改 launch 中 tts_node 的 engine 参数为 pyttsx3
```

### Q7: `catkin_make` 编译报错

```bash
cd ~/scene-recognition-robot
catkin_make clean
catkin_make
source devel/setup.bash
```

### Q8: 首次 Gazebo 启动很慢

Gazebo 首次运行会下载模型文件，需联网，等待 2–5 分钟正常。

### Q9: 导航到某个房间失败

- 检查 RViz 中地图是否正确加载
- 确认目标点不在障碍物上
- 可编辑 `config/mission_gazebo.yaml` 调整房间坐标

---

## 12. 命令速查表

### 首次安装（一次性）

```bash
# 系统更新
sudo apt update && sudo apt upgrade -y

# 安装 ROS Noetic
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt install curl -y
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo apt update
sudo apt install ros-noetic-desktop-full -y
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
sudo apt install python3-rosdep python3-rosinstall build-essential -y
sudo rosdep init && rosdep update

# 安装项目 ROS 依赖
sudo apt install -y ros-noetic-navigation ros-noetic-move-base ros-noetic-map-server \
  ros-noetic-amcl ros-noetic-gazebo-ros-pkgs ros-noetic-turtlebot3-gazebo \
  ros-noetic-turtlebot3-navigation ros-noetic-turtlebot3-description espeak espeak-data

# 设置 TurtleBot3
echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc
source ~/.bashrc

# 编译项目
cd ~/scene-recognition-robot
chmod +x src/scene_recognition_robot/scripts/*.py
rosdep install --from-paths src --ignore-src -r -y
catkin_make
echo "source ~/scene-recognition-robot/devel/setup.bash" >> ~/.bashrc
source devel/setup.bash
```

### 每次运行仿真

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
cd ~/scene-recognition-robot
roslaunch scene_recognition_robot gazebo_sim.launch
```

---

## 附录：节点说明

| 节点 | 功能 |
|------|------|
| `gazebo_gt_detection_node` | 根据机器人位置发布房间物体 |
| `scene_inference_node` | 物体 → 房间类型推理 |
| `mission_controller_node` | 任务编排：导航 + 采集 + 汇报 |
| `tts_node` | 语音播报 |
| `move_base` | 路径规划与导航 |
| `amcl` | 定位 |
| `map_server` | 加载地图 |

| 配置文件 | 用途 |
|---------|------|
| `config/scene_rules.yaml` | 物体→房间推理规则 |
| `config/mission_gazebo.yaml` | 各房间导航坐标 |
| `config/gazebo_rooms.yaml` | 仿真房间区域定义 |
| `worlds/scene_house.world` | Gazebo 四室场景 |
| `maps/house_map.yaml` | 导航地图 |
