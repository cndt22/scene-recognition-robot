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
