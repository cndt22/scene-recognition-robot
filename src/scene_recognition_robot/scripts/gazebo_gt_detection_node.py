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
