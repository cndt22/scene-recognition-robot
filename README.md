# 场景识别机器人

独立 ROS 课设项目：机器人进入不同房间 → 识别物体 → 推断房间类型 → 导航汇报 → 语音播报。

## 快速开始

**Ubuntu 完整步骤（无需 Windows 传文件）见 [SETUP_UBUNTU.md](SETUP_UBUNTU.md)**

```bash
# 1. 在 Ubuntu 内 git clone 项目后，一键安装：
cd ~/scene-recognition-robot
bash install/bootstrap_ubuntu.sh

# 2. 每次运行仿真：
source /opt/ros/noetic/setup.bash
source ~/scene-recognition-robot/devel/setup.bash
export TURTLEBOT3_MODEL=waffle_pi
roslaunch scene_recognition_robot gazebo_sim.launch
```

## 环境要求

- Ubuntu 20.04 + ROS Noetic
- 内存 ≥ 8GB

## 课设要求对照

| 要求 | 实现 |
|------|------|
| 根据物体判断房间类型 | `scene_inference_node` + `scene_rules.yaml` |
| 至少 3 种房间 | 卧室、餐厅、厨房、客厅（4 种） |
| 识别完成后到指定位置 | `mission_controller_node` 导航至汇报点 |
| 语音播报结果 | `tts_node`（espeak） |

## 项目结构

```
scene-recognition-robot/
├── SETUP.md              ← 完整安装运行指南
├── README.md             ← 本文件
├── requirements.txt
└── src/scene_recognition_robot/
    ├── config/           场景规则、导航点
    ├── launch/           启动文件
    ├── worlds/           Gazebo 世界
    ├── maps/             导航地图
    ├── msg/ srv/         ROS 消息定义
    └── scripts/          Python 节点
```

## 系统架构

```
scene_house.world (Gazebo 四室场景)
        ↓
TurtleBot3 (/scan, /camera, /odom)
        ↓
map_server + AMCL + move_base
        ↓
gazebo_gt_detection_node → scene_inference_node
        ↓
mission_controller_node → tts_node
```

## Launch 文件

| 文件 | 用途 |
|------|------|
| `gazebo_sim.launch` | Gazebo 仿真一键启动（推荐） |
| `demo_mock.launch` | 无 Gazebo 快速演示 |
| `full_mission.launch` | 真实机器人完整任务 |
| `scene_recognition.launch` | 仅识别节点 |

## 调试

```bash
rostopic echo /detected_objects    # 物体检测
rostopic echo /scene_result        # 场景识别
rosservice call /announce_scene "text: '测试' language: 'zh'"  # 语音测试
```
