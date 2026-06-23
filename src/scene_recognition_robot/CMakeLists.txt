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
    message_runtime
)

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(PROGRAMS
  scripts/rosrun_src.sh
  scripts/object_detection_node.py
  scripts/scene_inference_node.py
  scripts/mission_controller_node.py
  scripts/tts_node.py
  scripts/gazebo_gt_detection_node.py
  scripts/generate_house_map.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

# 每次编译后强制把 scripts 复制到 devel，避免运行旧脚本
add_custom_command(
  OUTPUT ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}/.scripts_synced
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/scripts ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}
  COMMAND ${CMAKE_COMMAND} -E touch ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}/.scripts_synced
  DEPENDS
    scripts/rosrun_src.sh
    scripts/scene_inference_node.py
    scripts/mission_controller_node.py
    scripts/tts_node.py
    scripts/gazebo_gt_detection_node.py
    scripts/object_detection_node.py
    scripts/generate_house_map.py
  COMMENT "Syncing Python scripts to devel"
)

add_custom_target(${PROJECT_NAME}_sync_scripts ALL
  DEPENDS ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}/.scripts_synced
)

install(DIRECTORY launch config rviz worlds maps
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)
