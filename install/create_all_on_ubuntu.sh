#!/bin/bash
# 在 Ubuntu 终端运行: bash create_all_on_ubuntu.sh
set -e
BASE="$HOME/scene-recognition-robot"
mkdir -p "$BASE"

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/CMakeLists.txt")"
cat > '$BASE/src/scene_recognition_robot/CMakeLists.txt' << 'ENDOFFILE'
cmake_minimum_required(VERSION 3.0.2)
project(scene_recognition_robot)

find_package(catkin REQUIRED COMPONENTS
  roscpp
  rospy
  std_msgs
  sensor_msgs
  geometry_msgs
  actionlib
  actionlib_msgs
  move_base_msgs
  cv_bridge
  vision_msgs
  message_generation
)

add_message_files(
  FILES
  DetectedObject.msg
  DetectedObjectArray.msg
  SceneResult.msg
)

add_service_files(
  FILES
  AnnounceScene.srv
)

generate_messages(
  DEPENDENCIES
  std_msgs
)

catkin_package(
  CATKIN_DEPENDS
    roscpp
    rospy
    std_msgs
    sensor_msgs
    geometry_msgs
    actionlib
    actionlib_msgs
    move_base_msgs
    cv_bridge
    vision_msgs
    message_runtime
)

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(PROGRAMS
  scripts/object_detection_node.py
  scripts/scene_inference_node.py
  scripts/mission_controller_node.py
  scripts/tts_node.py
  scripts/gazebo_gt_detection_node.py
  scripts/generate_house_map.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

install(DIRECTORY launch config rviz worlds maps
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/amcl_gazebo.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/amcl_gazebo.yaml' << 'ENDOFFILE'
# AMCL 参数（TurtleBot3 + scene_house 地图）

min_particles: 500
max_particles: 2000
kld_err: 0.05
update_min_d: 0.2
update_min_a: 0.5
resample_interval: 1
transform_tolerance: 0.5
recovery_alpha_slow: 0.0
recovery_alpha_fast: 0.0
initial_pose_x: 0.0
initial_pose_y: 0.0
initial_pose_a: 0.0
gui_publish_rate: 10.0
laser_max_range: 3.5
laser_min_range: 0.12
laser_max_beams: 180
odom_model_type: diff
odom_alpha1: 0.1
odom_alpha2: 0.1
odom_alpha3: 0.1
odom_alpha4: 0.1

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/costmap_common.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/costmap_common.yaml' << 'ENDOFFILE'
# 通用 costmap 参数（TurtleBot / 差分驱动底盘）

footprint: [[-0.2, -0.2], [-0.2, 0.2], [0.2, 0.2], [0.2, -0.2]]
robot_radius: 0.2

obstacle_range: 2.5
raytrace_range: 3.0
inflation_radius: 0.3
cost_scaling_factor: 3.0

observation_sources: scan
scan:
  data_type: LaserScan
  topic: /scan
  marking: true
  clearing: true

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/gazebo_rooms.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/gazebo_rooms.yaml' << 'ENDOFFILE'
# Gazebo 仿真：房间区域与对应物体（真值检测）
# 坐标系: map (与 Gazebo 世界一致，原点西南角)

rooms:
  bedroom:
    name_cn: "卧室"
    # 矩形区域 [x_min, y_min, x_max, y_max]
    bounds: [0.3, 0.3, 4.7, 4.7]
    objects:
      - bed
      - pillow

  dining_room:
    name_cn: "餐厅"
    bounds: [5.3, 0.3, 9.7, 4.7]
    objects:
      - dining table
      - chair
      - bowl

  kitchen:
    name_cn: "厨房"
    bounds: [0.3, 5.3, 4.7, 9.7]
    objects:
      - refrigerator
      - microwave

  living_room:
    name_cn: "客厅"
    bounds: [5.3, 5.3, 9.7, 9.7]
    objects:
      - couch
      - tv

# 机器人在房间区域内即认为"看到"该房间物体
detection_pose_topic: "/amcl_pose"

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/global_costmap.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/global_costmap.yaml' << 'ENDOFFILE'
global_costmap:
  global_frame: map
  robot_base_frame: base_link
  update_frequency: 5.0
  publish_frequency: 2.0
  static_map: true
  rolling_window: false
  width: 10.0
  height: 10.0
  resolution: 0.05

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/local_costmap.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/local_costmap.yaml' << 'ENDOFFILE'
local_costmap:
  global_frame: odom
  robot_base_frame: base_link
  update_frequency: 5.0
  publish_frequency: 2.0
  static_map: false
  rolling_window: true
  width: 3.0
  height: 3.0
  resolution: 0.05

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/mission.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/mission.yaml' << 'ENDOFFILE'
# 待探索房间导航点（map 坐标系）
# 机器人依次前往各房间入口进行场景识别

rooms:
  - id: room_1
    name: "房间一"
    pose:
      x: 2.0
      y: 1.0
      yaw: 0.0

  - id: room_2
    name: "房间二"
    pose:
      x: 5.0
      y: 3.0
      yaw: 1.57

  - id: room_3
    name: "房间三"
    pose:
      x: 1.0
      y: 4.5
      yaw: -1.57

# 识别完成后汇报位置
report_pose:
  x: 0.0
  y: 0.0
  yaw: 0.0

# 每个房间停留检测时间（秒）
detection_duration: 5.0

# 物体检测置信度阈值
confidence_threshold: 0.45

# 场景推理所需最少检测帧数（取众数）
min_detection_frames: 3

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/mission_gazebo.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/mission_gazebo.yaml' << 'ENDOFFILE'
# Gazebo scene_house.world 对应的任务导航点

rooms:
  - id: bedroom
    name: "卧室"
    pose:
      x: 2.5
      y: 2.5
      yaw: 0.0

  - id: dining_room
    name: "餐厅"
    pose:
      x: 7.5
      y: 2.5
      yaw: 3.14

  - id: kitchen
    name: "厨房"
    pose:
      x: 2.5
      y: 7.5
      yaw: 1.57

  - id: living_room
    name: "客厅"
    pose:
      x: 7.5
      y: 7.5
      yaw: -1.57

# 起始/汇报位置（绿色标记柱旁）
report_pose:
  x: 0.8
  y: 0.8
  yaw: 0.78

detection_duration: 4.0
confidence_threshold: 0.45
min_detection_frames: 2

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/move_base.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/move_base.yaml' << 'ENDOFFILE'
base_global_planner: navfn/NavfnROS
base_local_planner: base_local_planner/TrajectoryPlannerROS

controller_frequency: 5.0
planner_patience: 5.0
controller_patience: 15.0
oscillation_timeout: 10.0
oscillation_distance: 0.2

TrajectoryPlannerROS:
  max_vel_x: 0.5
  min_vel_x: 0.1
  max_rotational_vel: 1.0
  min_in_place_rotational_vel: 0.4
  acc_lim_x: 0.5
  acc_lim_theta: 0.6

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/config/scene_rules.yaml")"
cat > '$BASE/src/scene_recognition_robot/config/scene_rules.yaml' << 'ENDOFFILE'
# 场景识别规则：根据检测到的物体推断房间类型
# min_matches: 至少匹配多少个规则物体
# priority: 多场景同时匹配时取优先级最高者

scenes:
  bedroom:
    name_cn: "卧室"
    min_matches: 1
    priority: 10
    objects:
      - bed
      - pillow
      - wardrobe
      - nightstand

  dining_room:
    name_cn: "餐厅"
    min_matches: 2
    priority: 9
    # 桌子 + 食物 -> 餐厅（课设示例）
    required_groups:
      - [dining table, table]
      - [food, bowl, cup, plate, banana, apple, sandwich, pizza]

  kitchen:
    name_cn: "厨房"
    min_matches: 1
    priority: 8
    objects:
      - refrigerator
      - microwave
      - oven
      - sink
      - toaster

  living_room:
    name_cn: "客厅"
    min_matches: 1
    priority: 7
    objects:
      - couch
      - sofa
      - tv
      - remote
      - coffee table

  bathroom:
    name_cn: "卫生间"
    min_matches: 1
    priority: 11
    objects:
      - toilet
      - bathtub
      - sink

# 物体标签别名（YOLO COCO 类别映射）
label_aliases:
  dining table: [dining table, table]
  sofa: [couch, sofa]
  food: [food, banana, apple, sandwich, pizza, orange, broccoli, carrot, hot dog, donut, cake]

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/launch/demo_mock.launch")"
cat > '$BASE/src/scene_recognition_robot/launch/demo_mock.launch' << 'ENDOFFILE'
<?xml version="1.0"?>
<launch>
  <!-- 无实体机器人：mock 检测 + 模拟导航 + 语音播报 -->
  <include file="$(find scene_recognition_robot)/launch/scene_recognition.launch">
    <arg name="mock_detection" value="true"/>
  </include>

  <node pkg="scene_recognition_robot" type="mission_controller_node.py" name="mission_controller_node" output="screen">
    <param name="simulate_navigation" value="true"/>
    <param name="detection_duration" value="4.0"/>
    <param name="min_detection_frames" value="2"/>
  </node>
</launch>

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/launch/full_mission.launch")"
cat > '$BASE/src/scene_recognition_robot/launch/full_mission.launch' << 'ENDOFFILE'
<?xml version="1.0"?>
<launch>
  <!-- 完整任务：导航 + 识别 + 播报 -->
  <arg name="mock_detection" default="false"/>
  <arg name="simulate_navigation" default="false"/>
  <arg name="map_file" default=""/>
  <arg name="use_amcl" default="true"/>

  <include file="$(find scene_recognition_robot)/launch/scene_recognition.launch">
    <arg name="mock_detection" value="$(arg mock_detection)"/>
  </include>

  <!-- 导航栈（需要已有地图；map_file 为空则跳过 map_server） -->
  <group if="$(eval map_file != '')">
    <node pkg="map_server" type="map_server" name="map_server" args="$(arg map_file)"/>

    <node pkg="move_base" type="move_base" respawn="false" name="move_base" output="screen">
      <rosparam file="$(find scene_recognition_robot)/config/costmap_common.yaml" command="load" ns="global_costmap"/>
      <rosparam file="$(find scene_recognition_robot)/config/costmap_common.yaml" command="load" ns="local_costmap"/>
      <rosparam file="$(find scene_recognition_robot)/config/local_costmap.yaml" command="load"/>
      <rosparam file="$(find scene_recognition_robot)/config/global_costmap.yaml" command="load"/>
      <rosparam file="$(find scene_recognition_robot)/config/move_base.yaml" command="load"/>
    </node>

    <group if="$(arg use_amcl)">
      <include file="$(find amcl)/examples/amcl_diff.launch"/>
    </group>
  </group>

  <node pkg="scene_recognition_robot" type="mission_controller_node.py" name="mission_controller_node" output="screen">
    <param name="simulate_navigation" value="$(arg simulate_navigation)"/>
  </node>
</launch>

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/launch/gazebo_sim.launch")"
cat > '$BASE/src/scene_recognition_robot/launch/gazebo_sim.launch' << 'ENDOFFILE'
<?xml version="1.0"?>
<launch>
  <!-- Gazebo 仿真一键启动：TurtleBot3 + 四室场景 + 导航 + 识别 + 播报 -->

  <arg name="model" default="waffle_pi"/>
  <arg name="x_pos" default="0.0"/>
  <arg name="y_pos" default="0.0"/>
  <arg name="z_pos" default="0.0"/>
  <arg name="yaw" default="0.0"/>
  <arg name="gui" default="true"/>
  <arg name="use_yolo" default="false"/>
  <arg name="paused" default="false"/>
  <arg name="run_mission" default="true"/>

  <env name="TURTLEBOT3_MODEL" value="$(arg model)"/>

  <!-- ========== Gazebo 世界 ========== -->
  <include file="$(find gazebo_ros)/launch/empty_world.launch">
    <arg name="world_name" value="$(find scene_recognition_robot)/worlds/scene_house.world"/>
    <arg name="paused" value="$(arg paused)"/>
    <arg name="use_sim_time" value="true"/>
    <arg name="gui" value="$(arg gui)"/>
    <arg name="headless" value="false"/>
    <arg name="debug" value="false"/>
  </include>

  <!-- ========== 生成 TurtleBot3 ========== -->
  <param name="robot_description" command="$(find xacro)/xacro --inorder $(find turtlebot3_description)/urdf/turtlebot3_$(arg model).urdf.xacro"/>

  <node pkg="gazebo_ros" type="spawn_model" name="spawn_urdf"
        args="-urdf -model turtlebot3_$(arg model) -x $(arg x_pos) -y $(arg y_pos) -z $(arg z_pos) -Y $(arg yaw) -param robot_description"/>

  <node pkg="robot_state_publisher" type="robot_state_publisher" name="robot_state_publisher">
    <param name="use_sim_time" value="true"/>
  </node>

  <!-- ========== 地图与定位 ========== -->
  <node pkg="map_server" type="map_server" name="map_server"
        args="$(find scene_recognition_robot)/maps/house_map.yaml"/>

  <node pkg="amcl" type="amcl" name="amcl">
    <rosparam file="$(find scene_recognition_robot)/config/amcl_gazebo.yaml" command="load"/>
    <param name="use_sim_time" value="true"/>
    <param name="odom_frame_id" value="odom"/>
    <param name="base_frame_id" value="base_footprint"/>
    <param name="global_frame_id" value="map"/>
    <param name="scan_topic" value="/scan"/>
  </node>

  <!-- ========== move_base 导航 ========== -->
  <node pkg="move_base" type="move_base" respawn="false" name="move_base" output="screen">
    <param name="use_sim_time" value="true"/>
    <rosparam file="$(find scene_recognition_robot)/config/costmap_common.yaml" command="load" ns="global_costmap"/>
    <rosparam file="$(find scene_recognition_robot)/config/costmap_common.yaml" command="load" ns="local_costmap"/>
    <rosparam file="$(find scene_recognition_robot)/config/local_costmap.yaml" command="load"/>
    <rosparam file="$(find scene_recognition_robot)/config/global_costmap.yaml" command="load"/>
    <rosparam file="$(find scene_recognition_robot)/config/move_base.yaml" command="load"/>
  </node>

  <!-- ========== 场景识别 ========== -->
  <group if="$(arg use_yolo)">
    <node pkg="scene_recognition_robot" type="object_detection_node.py" name="object_detection_node" output="screen">
      <param name="mock_mode" value="false"/>
      <param name="image_topic" value="/camera/image_raw"/>
      <param name="model_path" value="yolov8n.pt"/>
    </node>
  </group>

  <group unless="$(arg use_yolo)">
    <node pkg="scene_recognition_robot" type="gazebo_gt_detection_node.py" name="gazebo_gt_detection_node" output="screen"/>
  </group>

  <node pkg="scene_recognition_robot" type="scene_inference_node.py" name="scene_inference_node" output="screen"/>

  <node pkg="scene_recognition_robot" type="tts_node.py" name="tts_node" output="screen">
    <param name="engine" value="espeak"/>
    <param name="default_language" value="zh"/>
  </node>

  <!-- 等待 Gazebo / AMCL 就绪后启动任务 -->
  <group if="$(arg run_mission)">
    <node pkg="scene_recognition_robot" type="mission_controller_node.py" name="mission_controller_node" output="screen">
      <param name="simulate_navigation" value="false"/>
      <param name="start_delay" value="10.0"/>
      <param name="mission_file" value="$(find scene_recognition_robot)/config/mission_gazebo.yaml"/>
    </node>
  </group>

  <!-- RViz 可视化（可选） -->
  <arg name="rviz" default="true"/>
  <group if="$(arg rviz)">
    <node pkg="rviz" type="rviz" name="rviz" required="false"
          args="-d $(find turtlebot3_navigation)/rviz/turtlebot3_navigation.rviz"/>
  </group>

</launch>

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/launch/scene_recognition.launch")"
cat > '$BASE/src/scene_recognition_robot/launch/scene_recognition.launch' << 'ENDOFFILE'
<?xml version="1.0"?>
<launch>
  <!-- 场景识别核心节点（无导航，适合 mock 调试） -->
  <arg name="mock_detection" default="true"/>
  <arg name="confidence_threshold" default="0.45"/>

  <node pkg="scene_recognition_robot" type="object_detection_node.py" name="object_detection_node" output="screen">
    <param name="mock_mode" value="$(arg mock_detection)"/>
    <param name="confidence_threshold" value="$(arg confidence_threshold)"/>
    <param name="image_topic" value="/camera/image_raw"/>
    <param name="model_path" value="yolov8n.pt"/>
  </node>

  <node pkg="scene_recognition_robot" type="scene_inference_node.py" name="scene_inference_node" output="screen">
    <param name="history_size" value="5"/>
  </node>

  <node pkg="scene_recognition_robot" type="tts_node.py" name="tts_node" output="screen">
    <param name="engine" value="espeak"/>
    <param name="default_language" value="zh"/>
    <param name="rate" value="150"/>
  </node>
</launch>

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/maps/house_map.yaml")"
cat > '$BASE/src/scene_recognition_robot/maps/house_map.yaml' << 'ENDOFFILE'
image: house_map.pgm
resolution: 0.05
origin: [0.0, 0.0, 0.0]
negate: 0
occupied_thresh: 0.65
free_thresh: 0.196

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/msg/DetectedObject.msg")"
cat > '$BASE/src/scene_recognition_robot/msg/DetectedObject.msg' << 'ENDOFFILE'
string label
float32 confidence
float32 x_min
float32 y_min
float32 x_max
float32 y_max

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/msg/DetectedObjectArray.msg")"
cat > '$BASE/src/scene_recognition_robot/msg/DetectedObjectArray.msg' << 'ENDOFFILE'
std_msgs/Header header
DetectedObject[] objects

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/msg/SceneResult.msg")"
cat > '$BASE/src/scene_recognition_robot/msg/SceneResult.msg' << 'ENDOFFILE'
std_msgs/Header header
string room_type
string room_name_cn
float32 confidence
string[] matched_objects
string[] all_detected_objects

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/package.xml")"
cat > '$BASE/src/scene_recognition_robot/package.xml' << 'ENDOFFILE'
<?xml version="1.0"?>
<package format="2">
  <name>scene_recognition_robot</name>
  <version>1.0.0</version>
  <description>Scene recognition robot: object detection, room inference, navigation, TTS</description>
  <maintainer email="student@example.com">student</maintainer>
  <license>MIT</license>

  <buildtool_depend>catkin</buildtool_depend>

  <build_depend>message_generation</build_depend>
  <build_depend>roscpp</build_depend>
  <build_depend>rospy</build_depend>
  <build_depend>std_msgs</build_depend>
  <build_depend>sensor_msgs</build_depend>
  <build_depend>geometry_msgs</build_depend>
  <build_depend>actionlib</build_depend>
  <build_depend>actionlib_msgs</build_depend>
  <build_depend>move_base_msgs</build_depend>
  <build_depend>cv_bridge</build_depend>
  <build_depend>vision_msgs</build_depend>

  <build_export_depend>roscpp</build_export_depend>
  <build_export_depend>rospy</build_export_depend>
  <build_export_depend>std_msgs</build_export_depend>
  <build_export_depend>sensor_msgs</build_export_depend>
  <build_export_depend>geometry_msgs</build_export_depend>
  <build_export_depend>actionlib</build_export_depend>
  <build_export_depend>actionlib_msgs</build_export_depend>
  <build_export_depend>move_base_msgs</build_export_depend>
  <build_export_depend>cv_bridge</build_export_depend>
  <build_export_depend>vision_msgs</build_export_depend>

  <exec_depend>message_runtime</exec_depend>
  <exec_depend>roscpp</exec_depend>
  <exec_depend>rospy</exec_depend>
  <exec_depend>std_msgs</exec_depend>
  <exec_depend>sensor_msgs</exec_depend>
  <exec_depend>geometry_msgs</exec_depend>
  <exec_depend>actionlib</exec_depend>
  <exec_depend>actionlib_msgs</exec_depend>
  <exec_depend>move_base_msgs</exec_depend>
  <exec_depend>cv_bridge</exec_depend>
  <exec_depend>vision_msgs</exec_depend>
  <exec_depend>usb_cam</exec_depend>
  <exec_depend>move_base</exec_depend>
  <exec_depend>map_server</exec_depend>
  <exec_depend>amcl</exec_depend>
  <exec_depend>gazebo_ros</exec_depend>
  <exec_depend>gazebo_ros_pkgs</exec_depend>
  <exec_depend>turtlebot3_gazebo</exec_depend>
  <exec_depend>turtlebot3_description</exec_depend>
  <exec_depend>turtlebot3_navigation</exec_depend>
  <exec_depend>robot_state_publisher</exec_depend>
  <exec_depend>xacro</exec_depend>
  <exec_depend>rviz</exec_depend>

  <export/>
</package>

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/scripts/gazebo_gt_detection_node.py")"
cat > '$BASE/src/scene_recognition_robot/scripts/gazebo_gt_detection_node.py' << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gazebo 真值检测节点：
根据 AMCL 定位判断机器人所在房间，发布该房间的物体列表。
（Gazebo 低模模型难以被 YOLO 稳定识别，仿真中使用区域真值。）
"""

import os
import yaml
import rospy
import rospkg
from geometry_msgs.msg import PoseWithCovarianceStamped
from scene_recognition_robot.msg import DetectedObject, DetectedObjectArray


class GazeboGTDetectionNode:
    def __init__(self):
        rospy.init_node("gazebo_gt_detection_node")

        pkg_path = rospkg.RosPack().get_path("scene_recognition_robot")
        rooms_file = rospy.get_param(
            "~rooms_file",
            os.path.join(pkg_path, "config", "gazebo_rooms.yaml"),
        )

        with open(rooms_file, "r", encoding="utf-8") as f:
            cfg = yaml.safe_load(f)

        self.rooms = cfg.get("rooms", {})
        self.pose_topic = cfg.get("detection_pose_topic", "/amcl_pose")
        self.rate_hz = rospy.get_param("~rate", 5.0)
        self.confidence = rospy.get_param("~confidence", 0.95)

        self.current_pose = None
        self.pub = rospy.Publisher("/detected_objects", DetectedObjectArray, queue_size=10)
        rospy.Subscriber(self.pose_topic, PoseWithCovarianceStamped, self.pose_callback, queue_size=1)

        rospy.Timer(rospy.Duration(1.0 / self.rate_hz), self.publish_detection)
        rospy.loginfo("gazebo_gt_detection_node 已启动，订阅: %s", self.pose_topic)

    def pose_callback(self, msg):
        self.current_pose = msg.pose.pose

    def _find_room(self, x, y):
        for room_id, room in self.rooms.items():
            bounds = room.get("bounds", [])
            if len(bounds) != 4:
                continue
            x_min, y_min, x_max, y_max = bounds
            if x_min <= x <= x_max and y_min <= y <= y_max:
                return room_id, room
        return None, None

    def publish_detection(self, _event):
        if self.current_pose is None:
            return

        x = self.current_pose.position.x
        y = self.current_pose.position.y
        room_id, room = self._find_room(x, y)

        msg = DetectedObjectArray()
        msg.header.stamp = rospy.Time.now()
        msg.header.frame_id = "map"

        if room is None:
            self.pub.publish(msg)
            return

        for label in room.get("objects", []):
            obj = DetectedObject()
            obj.label = label
            obj.confidence = self.confidence
            msg.objects.append(obj)

        self.pub.publish(msg)
        labels = ", ".join(room.get("objects", []))
        rospy.logdebug("Gazebo GT [%s]: %s", room_id, labels)


if __name__ == "__main__":
    try:
        GazeboGTDetectionNode()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/scripts/generate_house_map.py")"
cat > '$BASE/src/scene_recognition_robot/scripts/generate_house_map.py' << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成与 scene_house.world 匹配的占据栅格地图。"""

import os
import struct

# 地图参数：10m x 10m，分辨率 0.05m -> 200x200
RESOLUTION = 0.05
WIDTH = 200
HEIGHT = 200
ORIGIN_X = 0.0
ORIGIN_Y = 0.0

WALL_THICKNESS = 3  # 像素（约 0.15m）


def world_to_pixel(x, y):
    px = int(x / RESOLUTION)
    py = int(y / RESOLUTION)
    return px, py


def draw_h_line(grid, x1, x2, y, value=100):
    for x in range(max(0, x1), min(WIDTH, x2 + 1)):
        if 0 <= y < HEIGHT:
            grid[y][x] = value


def draw_v_line(grid, x, y1, y2, value=100):
    for y in range(max(0, y1), min(HEIGHT, y2 + 1)):
        if 0 <= x < WIDTH:
            grid[y][x] = value


def draw_rect(grid, x1, y1, x2, y2, value=100):
    px1, py1 = world_to_pixel(x1, y1)
    px2, py2 = world_to_pixel(x2, y2)
    for y in range(min(py1, py2), max(py1, py2) + 1):
        for x in range(min(px1, px2), max(px1, px2) + 1):
            if 0 <= x < WIDTH and 0 <= y < HEIGHT:
                grid[y][x] = value


def main():
    grid = [[0 for _ in range(WIDTH)] for _ in range(HEIGHT)]

    # 外墙
    draw_rect(grid, 0, 0, 10, 10, 100)

    # 内部自由空间（挖空）
    draw_rect(grid, 0.2, 0.2, 9.8, 9.8, 0)

    # 内墙 x=5（带门洞 y=4-6 即 world 2.0-3.0? 门洞在 y=2 附近）
    # 门洞：卧室-餐厅通道 y=1.5-3.5 at x=5
    draw_v_line(grid, world_to_pixel(5, 0)[0], world_to_pixel(5, 0)[1], world_to_pixel(5, 1.5)[1], 100)
    draw_v_line(grid, world_to_pixel(5, 0)[0], world_to_pixel(5, 3.5)[1], world_to_pixel(5, 5)[1], 100)
    draw_v_line(grid, world_to_pixel(5, 0)[0], world_to_pixel(5, 6.5)[1], world_to_pixel(5, 10)[1], 100)

    # 内墙 y=5（带门洞 x=1.5-3.5 和 x=6.5-8.5）
    draw_h_line(grid, world_to_pixel(0, 5)[0], world_to_pixel(1.5, 5)[0], world_to_pixel(0, 5)[1], 100)
    draw_h_line(grid, world_to_pixel(3.5, 5)[0], world_to_pixel(6.5, 5)[0], world_to_pixel(0, 5)[1], 100)
    draw_h_line(grid, world_to_pixel(8.5, 5)[0], world_to_pixel(10, 5)[0], world_to_pixel(0, 5)[1], 100)

    # 家具占据（简化为小矩形）
    draw_rect(grid, 1.5, 1.7, 3.5, 3.3, 100)   # bed
    draw_rect(grid, 6.7, 2.0, 8.3, 3.0, 100)   # table
    draw_rect(grid, 1.6, 6.6, 2.4, 8.4, 100)   # fridge
    draw_rect(grid, 6.5, 7.1, 8.5, 7.9, 100)   # sofa

    script_dir = os.path.dirname(os.path.abspath(__file__))
    maps_dir = os.path.join(script_dir, "..", "maps")
    os.makedirs(maps_dir, exist_ok=True)

    pgm_path = os.path.join(maps_dir, "house_map.pgm")
    with open(pgm_path, "wb") as f:
        f.write(b"P5\n")
        f.write(f"{WIDTH} {HEIGHT}\n".encode())
        f.write(b"255\n")
        for row in reversed(grid):
            f.write(bytes(255 - v for v in row))

    yaml_path = os.path.join(maps_dir, "house_map.yaml")
    with open(yaml_path, "w", encoding="utf-8") as f:
        f.write(f"""image: house_map.pgm
resolution: {RESOLUTION}
origin: [{ORIGIN_X}, {ORIGIN_Y}, 0.0]
negate: 0
occupied_thresh: 0.65
free_thresh: 0.196
""")

    print("Generated:", pgm_path)
    print("Generated:", yaml_path)


if __name__ == "__main__":
    main()

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/scripts/mission_controller_node.py")"
cat > '$BASE/src/scene_recognition_robot/scripts/mission_controller_node.py' << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务控制节点：
1. 依次导航到各房间
2. 采集物体并推理场景
3. 导航到汇报点
4. 语音播报全部识别结果
"""

import math
import os
import yaml
import rospy
import actionlib
import rospkg
from geometry_msgs.msg import Pose, PoseStamped, Quaternion
from move_base_msgs.msg import MoveBaseAction, MoveBaseGoal
from scene_recognition_robot.msg import SceneResult
from scene_recognition_robot.srv import AnnounceScene, AnnounceSceneRequest


def yaw_to_quaternion(yaw):
    q = Quaternion()
    q.x = 0.0
    q.y = 0.0
    q.z = math.sin(yaw / 2.0)
    q.w = math.cos(yaw / 2.0)
    return q


class MissionControllerNode:
    def __init__(self):
        rospy.init_node("mission_controller_node")

        pkg_path = rospkg.RosPack().get_path("scene_recognition_robot")
        mission_file = rospy.get_param(
            "~mission_file",
            os.path.join(pkg_path, "config", "mission.yaml"),
        )

        with open(mission_file, "r", encoding="utf-8") as f:
            self.mission = yaml.safe_load(f)

        self.rooms = self.mission.get("rooms", [])
        self.report_pose = self.mission.get("report_pose", {"x": 0, "y": 0, "yaw": 0})
        self.detection_duration = rospy.get_param("~detection_duration", self.mission.get("detection_duration", 5.0))
        self.min_detection_frames = rospy.get_param("~min_detection_frames", self.mission.get("min_detection_frames", 3))
        self.start_delay = rospy.get_param("~start_delay", 2.0)
        self.simulate_navigation = rospy.get_param("~simulate_navigation", False)

        self.results = {}
        self.scene_buffer = []
        self.current_room = None

        self.move_base = actionlib.SimpleActionClient("move_base", MoveBaseAction)
        if not self.simulate_navigation:
            rospy.loginfo("等待 move_base 服务器...")
            if not self.move_base.wait_for_server(rospy.Duration(30.0)):
                rospy.logwarn("move_base 不可用，切换为 simulate_navigation 模式")
                self.simulate_navigation = True

        rospy.Subscriber("/scene_result", SceneResult, self.scene_callback, queue_size=10)
        rospy.wait_for_service("/announce_scene", timeout=10.0)
        self.announce = rospy.ServiceProxy("/announce_scene", AnnounceScene)

        rospy.loginfo("mission_controller_node 已启动，共 %d 个房间", len(self.rooms))

    def scene_callback(self, msg):
        if self.current_room is None:
            return
        self.scene_buffer.append(msg)

    def _make_goal(self, x, y, yaw):
        goal = MoveBaseGoal()
        goal.target_pose = PoseStamped()
        goal.target_pose.header.frame_id = "map"
        goal.target_pose.header.stamp = rospy.Time.now()
        goal.target_pose.pose.position.x = x
        goal.target_pose.pose.position.y = y
        goal.target_pose.pose.position.z = 0.0
        goal.target_pose.pose.orientation = yaw_to_quaternion(yaw)
        return goal

    def navigate_to(self, x, y, yaw, label):
        rospy.loginfo("导航至 %s (%.2f, %.2f, %.2f)", label, x, y, yaw)
        if self.simulate_navigation:
            rospy.sleep(1.0)
            return True

        goal = self._make_goal(x, y, yaw)
        self.move_base.send_goal(goal)
        finished = self.move_base.wait_for_result(rospy.Duration(120.0))
        if not finished:
            rospy.logwarn("导航超时: %s", label)
            return False
        state = self.move_base.get_state()
        if state != actionlib.GoalStatus.SUCCEEDED:
            rospy.logwarn("导航失败: %s, state=%s", label, state)
            return False
        return True

    def collect_scene_result(self, room_id):
        self.scene_buffer = []
        rate = rospy.Rate(10)
        end_time = rospy.Time.now() + rospy.Duration(self.detection_duration)

        while rospy.Time.now() < end_time and not rospy.is_shutdown():
            rate.sleep()

        if len(self.scene_buffer) < self.min_detection_frames:
            rospy.logwarn("房间 %s 检测帧不足 (%d/%d)", room_id, len(self.scene_buffer), self.min_detection_frames)
            if not self.scene_buffer:
                return None

        # 取置信度最高的结果
        best = max(self.scene_buffer, key=lambda m: m.confidence)
        return best

    def build_announcement(self):
        lines = ["场景识别任务完成。"]
        for room in self.rooms:
            rid = room["id"]
            rname = room.get("name", rid)
            if rid in self.results and self.results[rid]:
                res = self.results[rid]
                objects = "、".join(res.matched_objects) if res.matched_objects else "未知物体"
                lines.append(f"{rname}识别为{res.room_name_cn}，检测到{objects}。")
            else:
                lines.append(f"{rname}未能识别。")
        return "".join(lines)

    def run_mission(self):
        for room in self.rooms:
            rid = room["id"]
            pose = room["pose"]
            self.current_room = rid

            ok = self.navigate_to(pose["x"], pose["y"], pose.get("yaw", 0.0), room.get("name", rid))
            if not ok:
                self.results[rid] = None
                continue

            rospy.loginfo("在 %s 进行场景识别...", room.get("name", rid))
            result = self.collect_scene_result(rid)
            self.results[rid] = result

            if result:
                rospy.loginfo(
                    "%s -> %s (%s)",
                    room.get("name", rid),
                    result.room_name_cn,
                    ", ".join(result.matched_objects),
                )

        self.current_room = None

        # 导航到汇报点
        rp = self.report_pose
        self.navigate_to(rp["x"], rp["y"], rp.get("yaw", 0.0), "汇报点")

        # 语音播报
        text = self.build_announcement()
        rospy.loginfo("播报内容: %s", text)
        try:
            req = AnnounceSceneRequest()
            req.text = text
            req.language = "zh"
            resp = self.announce(req)
            if not resp.success:
                rospy.logwarn("播报失败: %s", resp.message)
        except rospy.ServiceException as exc:
            rospy.logerr("调用播报服务失败: %s", exc)

        rospy.loginfo("任务完成")


if __name__ == "__main__":
    try:
        node = MissionControllerNode()
        delay = node.start_delay
        rospy.loginfo("等待 %.1f 秒后开始任务...", delay)
        rospy.sleep(delay)
        node.run_mission()
    except rospy.ROSInterruptException:
        pass

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/scripts/object_detection_node.py")"
cat > '$BASE/src/scene_recognition_robot/scripts/object_detection_node.py' << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""物体检测节点：订阅相机图像，发布 DetectedObjectArray。"""

import os
import rospy
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
from scene_recognition_robot.msg import DetectedObject, DetectedObjectArray

try:
    from ultralytics import YOLO
    YOLO_AVAILABLE = True
except ImportError:
    YOLO_AVAILABLE = False


class ObjectDetectionNode:
    def __init__(self):
        rospy.init_node("object_detection_node")

        self.conf_threshold = rospy.get_param("~confidence_threshold", 0.45)
        self.image_topic = rospy.get_param("~image_topic", "/camera/image_raw")
        self.model_path = rospy.get_param("~model_path", "yolov8n.pt")
        self.mock_mode = rospy.get_param("~mock_mode", not YOLO_AVAILABLE)

        self.bridge = CvBridge()
        self.model = None

        if not self.mock_mode:
            if not YOLO_AVAILABLE:
                rospy.logwarn("ultralytics 未安装，切换到 mock 模式")
                self.mock_mode = True
            else:
                rospy.loginfo("加载 YOLO 模型: %s", self.model_path)
                self.model = YOLO(self.model_path)

        self.pub = rospy.Publisher("/detected_objects", DetectedObjectArray, queue_size=10)
        self.sub = rospy.Subscriber(self.image_topic, Image, self.image_callback, queue_size=1)

        if self.mock_mode:
            rospy.logwarn("物体检测运行在 mock 模式（无相机/YOLO 时使用）")
            self._start_mock_timer()

        rospy.loginfo("object_detection_node 已启动，订阅: %s", self.image_topic)

    def _start_mock_timer(self):
        """Mock 模式：循环发布预设物体，便于无硬件调试。"""
        self._mock_scenes = [
            ["bed", "pillow"],
            ["dining table", "chair", "bowl"],
            ["refrigerator", "microwave"],
        ]
        self._mock_index = 0
        rospy.Timer(rospy.Duration(2.0), self._mock_publish)

    def _mock_publish(self, _event):
        labels = self._mock_scenes[self._mock_index % len(self._mock_scenes)]
        self._mock_index += 1
        msg = DetectedObjectArray()
        msg.header.stamp = rospy.Time.now()
        msg.header.frame_id = "camera_link"
        for label in labels:
            obj = DetectedObject()
            obj.label = label
            obj.confidence = 0.92
            msg.objects.append(obj)
        self.pub.publish(msg)
        rospy.loginfo("Mock 检测: %s", ", ".join(labels))

    def image_callback(self, msg):
        if self.mock_mode:
            return

        try:
            cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")
        except Exception as exc:
            rospy.logerr("图像转换失败: %s", exc)
            return

        results = self.model(cv_image, verbose=False)[0]
        out = DetectedObjectArray()
        out.header = msg.header

        for box in results.boxes:
            conf = float(box.conf[0])
            if conf < self.conf_threshold:
                continue
            cls_id = int(box.cls[0])
            label = results.names[cls_id]
            x1, y1, x2, y2 = box.xyxy[0].tolist()

            obj = DetectedObject()
            obj.label = label
            obj.confidence = conf
            obj.x_min = x1
            obj.y_min = y1
            obj.x_max = x2
            obj.y_max = y2
            out.objects.append(obj)

        self.pub.publish(out)
        if out.objects:
            labels = [o.label for o in out.objects]
            rospy.logdebug("检测到: %s", ", ".join(labels))


if __name__ == "__main__":
    try:
        ObjectDetectionNode()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/scripts/scene_inference_node.py")"
cat > '$BASE/src/scene_recognition_robot/scripts/scene_inference_node.py' << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""场景推理节点：根据检测物体推断房间类型。"""

import os
import yaml
import rospy
import rospkg
from collections import Counter
from scene_recognition_robot.msg import DetectedObjectArray, SceneResult


class SceneInferenceNode:
    def __init__(self):
        rospy.init_node("scene_inference_node")

        rules_path = rospy.get_param("~rules_file", "")
        if not rules_path:
            pkg_path = rospkg.RosPack().get_path("scene_recognition_robot")
            rules_path = os.path.join(pkg_path, "config", "scene_rules.yaml")

        with open(rules_path, "r", encoding="utf-8") as f:
            self.rules = yaml.safe_load(f)

        self.scenes = self.rules.get("scenes", {})
        self.aliases = self.rules.get("label_aliases", {})
        self.history_size = rospy.get_param("~history_size", 5)
        self.detection_history = []

        self.pub = rospy.Publisher("/scene_result", SceneResult, queue_size=10)
        self.sub = rospy.Subscriber("/detected_objects", DetectedObjectArray, self.callback, queue_size=10)

        rospy.loginfo("scene_inference_node 已启动，规则文件: %s", rules_path)

    def _normalize_label(self, label):
        label = label.lower().strip()
        for canonical, variants in self.aliases.items():
            if label == canonical or label in variants:
                return canonical
        return label

    def _labels_from_msg(self, msg):
        labels = set()
        for obj in msg.objects:
            labels.add(self._normalize_label(obj.label))
            labels.add(obj.label.lower().strip())
        return labels

    def _match_scene(self, detected_labels):
        best_scene = None
        best_score = (-1, -1, -1.0)  # priority, match_count, confidence

        for scene_id, cfg in self.scenes.items():
            matched = []

            if "required_groups" in cfg:
                group_hits = []
                for group in cfg["required_groups"]:
                    group_set = {g.lower() for g in group}
                    hit = detected_labels & group_set
                    if hit:
                        group_hits.append(hit)
                        matched.extend(hit)
                if len(group_hits) < len(cfg["required_groups"]):
                    continue
                match_count = len(set(matched))
            else:
                scene_objects = {o.lower() for o in cfg.get("objects", [])}
                for alias_key, variants in self.aliases.items():
                    if alias_key in scene_objects or any(v in scene_objects for v in variants):
                        scene_objects.add(alias_key)
                        scene_objects.update(variants)

                matched = list(detected_labels & scene_objects)
                match_count = len(matched)
                if match_count < cfg.get("min_matches", 1):
                    continue

            priority = cfg.get("priority", 0)
            confidence = match_count / max(len(cfg.get("objects", matched)), 1)
            score = (priority, match_count, confidence)

            if score > best_score:
                best_score = score
                best_scene = (scene_id, cfg, matched)

        return best_scene

    def callback(self, msg):
        labels = self._labels_from_msg(msg)
        if not labels:
            return

        result = self._match_scene(labels)
        if not result:
            rospy.logdebug("未匹配任何场景: %s", labels)
            return

        scene_id, cfg, matched = result
        self.detection_history.append(scene_id)
        if len(self.detection_history) > self.history_size:
            self.detection_history.pop(0)

        # 取最近帧众数，减少抖动
        dominant = Counter(self.detection_history).most_common(1)[0][0]
        if dominant != scene_id:
            scene_id = dominant
            cfg = self.scenes[scene_id]
            matched = list(labels & {o.lower() for o in cfg.get("objects", [])})

        out = SceneResult()
        out.header = msg.header
        out.room_type = scene_id
        out.room_name_cn = cfg.get("name_cn", scene_id)
        out.confidence = min(1.0, len(matched) / max(cfg.get("min_matches", 1), 1))
        out.matched_objects = list(set(matched))
        out.all_detected_objects = sorted(labels)

        self.pub.publish(out)
        rospy.loginfo(
            "场景识别: %s (%s)，匹配物体: %s",
            out.room_name_cn,
            out.room_type,
            ", ".join(out.matched_objects),
        )


if __name__ == "__main__":
    try:
        SceneInferenceNode()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/scripts/tts_node.py")"
cat > '$BASE/src/scene_recognition_robot/scripts/tts_node.py' << 'ENDOFFILE'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""语音播报节点：TTS 播报场景识别结果。"""

import subprocess
import rospy
from scene_recognition_robot.srv import AnnounceScene, AnnounceSceneResponse


class TTSNode:
    def __init__(self):
        rospy.init_node("tts_node")

        self.engine = rospy.get_param("~engine", "espeak")  # espeak | pyttsx3
        self.language = rospy.get_param("~default_language", "zh")
        self.rate = rospy.get_param("~rate", 150)

        self.srv = rospy.Service("/announce_scene", AnnounceScene, self.handle_announce)
        rospy.loginfo("tts_node 已启动，引擎: %s", self.engine)

    def _speak_espeak(self, text, language):
        lang_map = {"zh": "zh", "en": "en"}
        lang = lang_map.get(language, "zh")
        cmd = ["espeak", "-v", lang, "-s", str(self.rate), text]
        subprocess.run(cmd, check=True)

    def _speak_pyttsx3(self, text):
        import pyttsx3
        engine = pyttsx3.init()
        engine.setProperty("rate", self.rate)
        engine.say(text)
        engine.runAndWait()

    def speak(self, text, language="zh"):
        rospy.loginfo("语音播报: %s", text)
        if self.engine == "pyttsx3":
            self._speak_pyttsx3(text)
        else:
            self._speak_espeak(text, language)

    def handle_announce(self, req):
        resp = AnnounceSceneResponse()
        try:
            self.speak(req.text, req.language or self.language)
            resp.success = True
            resp.message = "播报成功"
        except Exception as exc:
            rospy.logerr("TTS 失败: %s", exc)
            resp.success = False
            resp.message = str(exc)
        return resp


if __name__ == "__main__":
    try:
        TTSNode()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/srv/AnnounceScene.srv")"
cat > '$BASE/src/scene_recognition_robot/srv/AnnounceScene.srv' << 'ENDOFFILE'
string text
string language
---
bool success
string message

ENDOFFILE

mkdir -p "$(dirname "$BASE/src/scene_recognition_robot/worlds/scene_house.world")"
cat > '$BASE/src/scene_recognition_robot/worlds/scene_house.world' << 'ENDOFFILE'
<?xml version="1.0" ?>
<sdf version="1.6">
  <world name="scene_house">

    <include>
      <uri>model://ground_plane</uri>
    </include>
    <include>
      <uri>model://sun</uri>
    </include>

    <physics type="ode">
      <real_time_update_rate>1000.0</real_time_update_rate>
      <max_step_size>0.001</max_step_size>
    </physics>

    <!-- ==================== 外墙 (10m x 10m) ==================== -->
    <model name="wall_north">
      <static>true</static>
      <pose>5 10 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>10.2 0.15 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>10.2 0.15 1.0</size></box></geometry>
          <material><ambient>0.8 0.8 0.8 1</ambient></material></visual>
      </link>
    </model>
    <model name="wall_south">
      <static>true</static>
      <pose>5 0 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>10.2 0.15 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>10.2 0.15 1.0</size></box></geometry>
          <material><ambient>0.8 0.8 0.8 1</ambient></material></visual>
      </link>
    </model>
    <model name="wall_west">
      <static>true</static>
      <pose>0 5 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>0.15 10.2 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>0.15 10.2 1.0</size></box></geometry>
          <material><ambient>0.8 0.8 0.8 1</ambient></material></visual>
      </link>
    </model>
    <model name="wall_east">
      <static>true</static>
      <pose>10 5 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>0.15 10.2 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>0.15 10.2 1.0</size></box></geometry>
          <material><ambient>0.8 0.8 0.8 1</ambient></material></visual>
      </link>
    </model>

    <!-- ==================== 内墙 (十字分隔，留门洞) ==================== -->
    <model name="wall_mid_x_west">
      <static>true</static>
      <pose>5 2.0 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>0.12 4.0 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>0.12 4.0 1.0</size></box></geometry>
          <material><ambient>0.7 0.7 0.7 1</ambient></material></visual>
      </link>
    </model>
    <model name="wall_mid_x_east">
      <static>true</static>
      <pose>5 8.0 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>0.12 4.0 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>0.12 4.0 1.0</size></box></geometry>
          <material><ambient>0.7 0.7 0.7 1</ambient></material></visual>
      </link>
    </model>
    <model name="wall_mid_y_south">
      <static>true</static>
      <pose>2.0 5 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>4.0 0.12 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>4.0 0.12 1.0</size></box></geometry>
          <material><ambient>0.7 0.7 0.7 1</ambient></material></visual>
      </link>
    </model>
    <model name="wall_mid_y_north">
      <static>true</static>
      <pose>8.0 5 0.5 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>4.0 0.12 1.0</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>4.0 0.12 1.0</size></box></geometry>
          <material><ambient>0.7 0.7 0.7 1</ambient></material></visual>
      </link>
    </model>

    <!-- ==================== 卧室 (西南, 0-5 x 0-5) ==================== -->
    <model name="bed">
      <static>true</static>
      <pose>2.5 2.5 0.25 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>2.0 1.6 0.5</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>2.0 1.6 0.5</size></box></geometry>
          <material><ambient>0.4 0.3 0.7 1</ambient></material></visual>
      </link>
    </model>
    <model name="pillow">
      <static>true</static>
      <pose>1.8 2.5 0.55 0 0 0</pose>
      <link name="link">
        <visual name="vis"><geometry><box><size>0.5 0.8 0.15</size></box></geometry>
          <material><ambient>1.0 1.0 1.0 1</ambient></material></visual>
      </link>
    </model>

    <!-- ==================== 餐厅 (东南, 5-10 x 0-5) ==================== -->
    <model name="dining_table">
      <static>true</static>
      <pose>7.5 2.5 0.4 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>1.6 1.0 0.8</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>1.6 1.0 0.8</size></box></geometry>
          <material><ambient>0.55 0.35 0.15 1</ambient></material></visual>
      </link>
    </model>
    <model name="dining_chair">
      <static>true</static>
      <pose>7.5 1.5 0.35 0 0 0</pose>
      <link name="link">
        <visual name="vis"><geometry><box><size>0.5 0.5 0.7</size></box></geometry>
          <material><ambient>0.3 0.3 0.3 1</ambient></material></visual>
      </link>
    </model>
    <model name="food_bowl">
      <static>true</static>
      <pose>7.5 2.5 0.85 0 0 0</pose>
      <link name="link">
        <visual name="vis"><geometry><cylinder><radius>0.15</radius><length>0.08</length></cylinder></geometry>
          <material><ambient>0.9 0.5 0.1 1</ambient></material></visual>
      </link>
    </model>

    <!-- ==================== 厨房 (西北, 0-5 x 5-10) ==================== -->
    <model name="refrigerator">
      <static>true</static>
      <pose>2.0 7.5 0.9 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>0.8 0.7 1.8</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>0.8 0.7 1.8</size></box></geometry>
          <material><ambient>0.85 0.85 0.9 1</ambient></material></visual>
      </link>
    </model>
    <model name="microwave">
      <static>true</static>
      <pose>3.5 7.0 0.9 0 0 0</pose>
      <link name="link">
        <visual name="vis"><geometry><box><size>0.5 0.4 0.3</size></box></geometry>
          <material><ambient>0.2 0.2 0.2 1</ambient></material></visual>
      </link>
    </model>

    <!-- ==================== 客厅 (东北, 5-10 x 5-10) ==================== -->
    <model name="sofa">
      <static>true</static>
      <pose>7.5 7.5 0.35 0 0 0</pose>
      <link name="link">
        <collision name="col"><geometry><box><size>2.0 0.8 0.7</size></box></geometry></collision>
        <visual name="vis"><geometry><box><size>2.0 0.8 0.7</size></box></geometry>
          <material><ambient>0.6 0.2 0.2 1</ambient></material></visual>
      </link>
    </model>
    <model name="tv">
      <static>true</static>
      <pose>9.0 7.5 1.0 0 0 1.57</pose>
      <link name="link">
        <visual name="vis"><geometry><box><size>0.1 1.2 0.8</size></box></geometry>
          <material><ambient>0.1 0.1 0.1 1</ambient></material></visual>
      </link>
    </model>

    <!-- 汇报区标记柱 -->
    <model name="report_marker">
      <static>true</static>
      <pose>0.8 0.8 0.25 0 0 0</pose>
      <link name="link">
        <visual name="vis"><geometry><cylinder><radius>0.15</radius><length>0.5</length></cylinder></geometry>
          <material><ambient>0.1 0.8 0.2 1</ambient></material></visual>
      </link>
    </model>

  </world>
</sdf>

ENDOFFILE

mkdir -p "$(dirname "$BASE/requirements.txt")"
cat > '$BASE/requirements.txt' << 'ENDOFFILE'
ultralytics>=8.0.0
opencv-python>=4.5.0
PyYAML>=5.4
pyttsx3>=2.90

ENDOFFILE

chmod +x "$BASE/src/scene_recognition_robot/scripts/"*.py
python3 "$BASE/src/scene_recognition_robot/scripts/generate_house_map.py"
echo "===== 项目创建完成 ====="
echo "路径: $BASE"
ls "$BASE/src/scene_recognition_robot/launch/"
