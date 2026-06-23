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
