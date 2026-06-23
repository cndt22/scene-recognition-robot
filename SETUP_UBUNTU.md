# Ubuntu 完整操作指南（无需 Windows 传文件）

本文档假设你**只在 Ubuntu 20.04 虚拟机/物理机内**完成全部操作，不从 Windows 拷贝任何文件。

---

## 总览

```
安装 Ubuntu 20.04
    ↓
更新系统 + 安装 git
    ↓
从 Gitee/GitHub 克隆项目（在 Ubuntu 浏览器/终端完成）
    ↓
运行一键安装脚本 bootstrap_ubuntu.sh
    ↓
启动 Gazebo 仿真
```

预计总耗时：**1.5 ~ 2.5 小时**（主要是 ROS 下载）

---

## 第一部分：安装 Ubuntu 20.04 虚拟机

> 若已有 Ubuntu 20.04，跳到 **第二部分**。

### 1.1 下载 Ubuntu 镜像（在 Ubuntu 宿主或虚拟机内用浏览器）

打开 Firefox，访问：

```
https://releases.ubuntu.com/20.04/
```

下载：**ubuntu-20.04.6-desktop-amd64.iso**（约 4GB）

### 1.2 创建虚拟机（VMware 示例）

1. 打开 VMware → **创建新的虚拟机**
2. 选择 **典型** → 下一步
3. 选择 **安装程序光盘映像文件** → 选刚下载的 `.iso`
4. 操作系统：**Linux** → **Ubuntu 64 位**
5. 虚拟机名称：`Ubuntu-ROS`
6. 磁盘：**至少 40GB**
7. 自定义硬件 → 内存 **8192 MB（8GB）** → 处理器 **2 核**
8. 完成并启动虚拟机

### 1.3 安装 Ubuntu 系统

1. 选 **Install Ubuntu**
2. 键盘：**Chinese**
3. 选 **正常安装** → 勾选 **安装第三方软件**
4. 选 **清除整个磁盘并安装 Ubuntu**（虚拟机内安全）
5. 设置用户名和密码（例如用户名 `ros`）
6. 等待安装完成 → **现在重启**
7. 登录 Ubuntu 桌面

### 1.4 确认版本

打开终端（`Ctrl + Alt + T`）：

```bash
lsb_release -a
```

必须看到 `Ubuntu 20.04`。

---

## 第二部分：系统基础配置

在终端依次执行：

```bash
# 更新系统
sudo apt update
sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git vim build-essential python3-pip

# 安装中文输入法（可选）
sudo apt install -y ibus-pinyin
# 设置 → 区域与语言 → 输入源 → 添加 Chinese (Pinyin)
```

---

## 第三部分：获取项目代码（在 Ubuntu 内完成）

有三种方式，**任选一种**。

---

### 方式 A：Git 克隆（推荐）

#### A1. 注册 Gitee（在 Ubuntu 的 Firefox 浏览器）

1. 打开 Firefox
2. 访问 `https://gitee.com`
3. 注册账号并登录

#### A2. 新建仓库并上传

1. 点击右上角 **+** → **新建仓库**
2. 仓库名：`scene-recognition-robot`
3. 选 **私有** 或 **公开** → **创建**
4. 进入仓库 → **上传文件** → 上传整个项目压缩包

> 若老师/同学给了仓库地址，跳过 A2，直接 A3。

#### A3. 在终端克隆

```bash
cd ~
git clone https://gitee.com/你的用户名/scene-recognition-robot.git
cd scene-recognition-robot
ls install/bootstrap_ubuntu.sh
```

能看到 `bootstrap_ubuntu.sh` 即成功。

---

### 方式 B：GitHub 克隆

```bash
cd ~
git clone https://github.com/你的用户名/scene-recognition-robot.git
cd scene-recognition-robot
```

---

### 方式 C：在 Ubuntu 浏览器下载 ZIP

1. Firefox 打开 Gitee/GitHub 上的项目页面
2. 点击 **克隆/下载** → **下载 ZIP**
3. 解压：

```bash
cd ~
unzip ~/Downloads/scene-recognition-robot-master.zip
mv scene-recognition-robot-master scene-recognition-robot
cd scene-recognition-robot
ls install/
```

应看到 `bootstrap_ubuntu.sh` 和 `project.tar.gz`。

---

## 第四部分：一键安装（ROS + 依赖 + 编译）

```bash
cd ~/scene-recognition-robot
chmod +x install/bootstrap_ubuntu.sh
bash install/bootstrap_ubuntu.sh
```

脚本会自动完成：

| 步骤 | 内容 |
|------|------|
| 1/7 | 更新系统 |
| 2/7 | 安装 ROS Noetic（约 20–40 分钟） |
| 3/7 | 安装 TurtleBot3、Gazebo、导航包 |
| 4/7 | 解压项目到 `~/scene-recognition-robot` |
| 5/7 | 安装 Python 依赖 |
| 6/7 | `catkin_make` 编译 |
| 7/7 | 验证安装 |

> 安装过程中可能需要输入密码，以及 ROS 安装时选择 **Yes/默认** 即可。

安装成功末尾显示：

```
安装完成!
rospack find scene_recognition_robot
/home/ros/scene-recognition-robot/src/scene_recognition_robot
```

---

### 若不想用一键脚本，手动安装

<details>
<summary>点击展开手动安装步骤</summary>

#### 手动 1：安装 ROS Noetic

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

#### 手动 2：安装项目依赖

```bash
sudo apt install -y \
  ros-noetic-navigation ros-noetic-move-base ros-noetic-map-server \
  ros-noetic-amcl ros-noetic-gazebo-ros-pkgs \
  ros-noetic-turtlebot3-gazebo ros-noetic-turtlebot3-navigation \
  ros-noetic-turtlebot3-description espeak espeak-data

echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc
source ~/.bashrc
```

#### 手动 3：编译

```bash
cd ~/scene-recognition-robot
chmod +x src/scene_recognition_robot/scripts/*.py
pip3 install PyYAML
source /opt/ros/noetic/setup.bash
rosdep install --from-paths src --ignore-src -r -y
catkin_make
echo "source ~/scene-recognition-robot/devel/setup.bash" >> ~/.bashrc
source devel/setup.bash
```

</details>

---

## 第五部分：验证 ROS 安装

**终端 1：**

```bash
source /opt/ros/noetic/setup.bash
roscore
```

**终端 2：**

```bash
source /opt/ros/noetic/setup.bash
rosnode list
```

看到 `/rosout` 表示 ROS 正常。回到终端 1 按 `Ctrl + C` 停止。

---

## 第六部分：运行 Gazebo 仿真

### 6.1 加载环境

每次打开新终端都要执行（或已写入 `~/.bashrc` 可省略）：

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
```

### 6.2 启动仿真

```bash
cd ~/scene-recognition-robot
roslaunch scene_recognition_robot gazebo_sim.launch
```

### 6.3 你会看到

| 窗口 | 内容 |
|------|------|
| **Gazebo** | 10m×10m 四室房屋 + TurtleBot3 机器人 |
| **RViz** | 地图、激光、机器人位置 |
| **终端** | 节点运行日志 |

### 6.4 自动任务流程

```
启动 → 等待 10 秒（定位）
  → 卧室 (2.5, 2.5)   识别「卧室」
  → 餐厅 (7.5, 2.5)   识别「餐厅」
  → 厨房 (2.5, 7.5)   识别「厨房」
  → 客厅 (7.5, 7.5)   识别「客厅」
  → 汇报点 (0.8, 0.8) 语音播报
  → 完成
```

### 6.5 停止

在 launch 终端按 **`Ctrl + C`**。

---

## 第七部分：监控与调试

另开一个终端：

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash

# 查看场景识别结果
rostopic echo /scene_result

# 查看物体检测
rostopic echo /detected_objects

# 测试语音
rosservice call /announce_scene "text: '当前房间是卧室' language: 'zh'"

# 查看激光雷达
rostopic hz /scan
```

---

## 第八部分：其他运行模式

```bash
# 无 Gazebo 快速演示
roslaunch scene_recognition_robot demo_mock.launch

# 手动调试（不自动跑任务）
roslaunch scene_recognition_robot gazebo_sim.launch run_mission:=false

# 无 GUI（电脑配置低）
roslaunch scene_recognition_robot gazebo_sim.launch gui:=false rviz:=false
```

---

## 第九部分：常见问题

| 问题 | 解决方法 |
|------|---------|
| `roslaunch: command not found` | `source /opt/ros/noetic/setup.bash` |
| `TURTLEBOT3_MODEL is not set` | `export TURTLEBOT3_MODEL=waffle_pi` |
| 找不到 `scene_recognition_robot` 包 | `cd ~/scene-recognition-robot && catkin_make && source devel/setup.bash` |
| Gazebo 黑屏/闪退 | 虚拟机内存调到 8GB，开启 3D 加速 |
| 机器人不动 | 等 10 秒以上；RViz 看 AMCL 粒子是否收敛 |
| 没声音 | `espeak -v zh "测试"`，检查音量 |
| 首次 Gazebo 很慢 | 正常，首次需下载模型，等 2–5 分钟 |
| `git clone` 失败 | 检查网络；或用浏览器下载 ZIP（方式 C） |

---

## 第十部分：每次运行命令速查

```bash
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
cd ~/scene-recognition-robot
roslaunch scene_recognition_robot gazebo_sim.launch
```

---

## 附录：仿真环境说明

```
          y ↑
            |
      厨房  |  客厅
            |
    --------+--------→ x
            |
      卧室  |  餐厅
            |
      ★(0,0)  ●汇报点(0.8,0.8)
```

| 房间 | 物体 | 识别结果 |
|------|------|---------|
| 卧室 | 床、枕头 | bedroom |
| 餐厅 | 餐桌、碗 | dining_room |
| 厨房 | 冰箱、微波炉 | kitchen |
| 客厅 | 沙发、电视 | living_room |

---

## 附录：项目目录

安装完成后：

```
~/scene-recognition-robot/
├── install/
│   ├── bootstrap_ubuntu.sh    ← 一键安装脚本
│   └── project.tar.gz         ← 项目源码包
├── src/scene_recognition_robot/
│   ├── launch/gazebo_sim.launch
│   ├── worlds/scene_house.world
│   ├── maps/house_map.yaml
│   ├── config/
│   └── scripts/
└── devel/                       ← 编译输出
```
