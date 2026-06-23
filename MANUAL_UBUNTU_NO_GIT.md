# Ubuntu 纯手工指南（不使用 Git）

全程在 **Ubuntu 20.04** 内完成，**不使用 git clone**。

---

## 总体流程

```
阶段一  安装 Ubuntu + 更新系统
阶段二  把「创建脚本」放进 Ubuntu（U盘/共享文件夹，只传 1 个文件）
阶段三  运行脚本，自动生成全部项目文件
阶段四  安装 ROS + 编译
阶段五  运行 Gazebo 仿真
```

> 项目共 29 个源码文件，用手一个一个 nano 写不现实。  
> 推荐做法：只拷贝 **1 个脚本文件** `create_all_on_ubuntu.sh` 到 Ubuntu，运行后自动创建全部代码。

---

## 阶段一：系统准备

### 1.1 打开终端

`Ctrl + Alt + T`

### 1.2 确认 Ubuntu 版本

```bash
lsb_release -a
```

必须是 **Ubuntu 20.04**。

### 1.3 更新系统

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget build-essential python3-pip
```

---

## 阶段二：把创建脚本放进 Ubuntu

你需要把 Windows 上这个 **单独文件** 拷到 Ubuntu：

```
E:\sky-take-out\scene-recognition-robot\install\create_all_on_ubuntu.sh
```

### 方法 A：U 盘（推荐）

1. U 盘插 Windows，复制 `create_all_on_ubuntu.sh` 到 U 盘
2. U 盘插 Ubuntu
3. 终端执行：

```bash
cp /media/$USER/*/create_all_on_ubuntu.sh ~/
ls ~/create_all_on_ubuntu.sh
```

### 方法 B：虚拟机共享文件夹

1. VMware 设置共享文件夹，指向 `E:\sky-take-out\scene-recognition-robot\install`
2. Ubuntu 终端：

```bash
cp /mnt/hgfs/install/create_all_on_ubuntu.sh ~/
```

> 共享文件夹路径因虚拟机配置而异，可能是 `/mnt/hgfs/共享名/create_all_on_ubuntu.sh`

### 方法 C：在 Ubuntu 里用 nano 新建（无 U 盘时）

```bash
nano ~/create_all_on_ubuntu.sh
```

把 `create_all_on_ubuntu.sh` 的全部内容粘贴进去（在 Cursor/Windows 打开该文件，Ctrl+A 全选复制）。

保存：`Ctrl+O` 回车，`Ctrl+X` 退出。

---

## 阶段三：自动生成项目全部文件

```bash
chmod +x ~/create_all_on_ubuntu.sh
bash ~/create_all_on_ubuntu.sh
```

成功输出类似：

```
===== 项目创建完成 =====
路径: /home/你的用户名/scene-recognition-robot
gazebo_sim.launch  demo_mock.launch  ...
```

### 验证

```bash
ls ~/scene-recognition-robot/src/scene_recognition_robot/launch/
ls ~/scene-recognition-robot/src/scene_recognition_robot/scripts/
```

---

## 阶段四：安装 ROS 并编译

同样只需 **1 个脚本** `setup_ros_and_build.sh`（或用下面手动命令）。

### 方法 A：用脚本（推荐）

把 `install/setup_ros_and_build.sh` 拷到 Ubuntu（同阶段二方式），然后：

```bash
cp /media/$USER/*/setup_ros_and_build.sh ~/
chmod +x ~/setup_ros_and_build.sh
bash ~/setup_ros_and_build.sh
```

> 耗时约 **30–60 分钟**（主要是 ROS 下载）。

### 方法 B：手动逐步执行

#### 4.1 安装 ROS Noetic

```bash
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt install curl -y
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo apt update
sudo apt install ros-noetic-desktop-full -y
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
sudo apt install python3-rosdep python3-rosinstall build-essential -y
sudo rosdep init
rosdep update
```

#### 4.2 安装项目依赖

```bash
sudo apt install -y \
  ros-noetic-navigation ros-noetic-move-base ros-noetic-map-server \
  ros-noetic-amcl ros-noetic-gazebo-ros-pkgs \
  ros-noetic-turtlebot3-gazebo ros-noetic-turtlebot3-navigation \
  ros-noetic-turtlebot3-description espeak espeak-data

echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc
source ~/.bashrc
```

#### 4.3 编译项目

```bash
cd ~/scene-recognition-robot
pip3 install PyYAML
chmod +x src/scene_recognition_robot/scripts/*.py
source /opt/ros/noetic/setup.bash
rosdep install --from-paths src --ignore-src -r -y
catkin_make
echo "source ~/scene-recognition-robot/devel/setup.bash" >> ~/.bashrc
source devel/setup.bash
```

#### 4.4 验证

```bash
rospack find scene_recognition_robot
```

---

## 阶段五：运行 Gazebo 仿真

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
cd ~/scene-recognition-robot
roslaunch scene_recognition_robot gazebo_sim.launch
```

### 你会看到

- Gazebo 四室场景 + TurtleBot3
- RViz 地图
- 机器人依次访问 4 个房间
- 最后语音播报结果

### 停止

launch 终端按 `Ctrl + C`

---

## 每次运行（安装完成后）

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
roslaunch scene_recognition_robot gazebo_sim.launch
```

---

## 需要拷贝到 Ubuntu 的文件（仅 2 个，不用 git）

| 文件 | 作用 |
|------|------|
| `install/create_all_on_ubuntu.sh` | 自动创建全部项目源码 |
| `install/setup_ros_and_build.sh` | 安装 ROS + 编译 |

Windows 路径：

```
E:\sky-take-out\scene-recognition-robot\install\create_all_on_ubuntu.sh
E:\sky-take-out\scene-recognition-robot\install\setup_ros_and_build.sh
```

---

## 常见问题

| 问题 | 解决 |
|------|------|
| `curl ros.asc` 失败 | 检查网络/DNS，换手机热点 |
| Gazebo 黑屏 | 虚拟机内存 8GB，开 3D 加速 |
| 机器人不动 | 等 10 秒，看 RViz 粒子云 |
| `catkin_make` 报错 | `cd ~/scene-recognition-robot && catkin_make clean && catkin_make` |

---

## 附录：项目创建后的目录

```
~/scene-recognition-robot/
└── src/scene_recognition_robot/
    ├── config/      场景规则、导航点
    ├── launch/      启动文件
    ├── worlds/      Gazebo 世界
    ├── maps/        导航地图（脚本自动生成）
    ├── msg/ srv/    ROS 消息
    └── scripts/     Python 节点
```
