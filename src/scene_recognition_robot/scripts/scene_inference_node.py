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
        self.last_logged_scene = None

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
        if scene_id != self.last_logged_scene:
            self.last_logged_scene = scene_id
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
