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
from geometry_msgs.msg import PoseStamped, Quaternion, PoseWithCovarianceStamped
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

        rooms_file = rospy.get_param(
            "~rooms_file",
            os.path.join(pkg_path, "config", "gazebo_rooms.yaml"),
        )
        with open(rooms_file, "r", encoding="utf-8") as f:
            self.room_bounds = {
                room_id: room.get("bounds", [])
                for room_id, room in yaml.safe_load(f).get("rooms", {}).items()
            }

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
        self.announce = None
        try:
            rospy.wait_for_service("/announce_scene", timeout=15.0)
            self.announce = rospy.ServiceProxy("/announce_scene", AnnounceScene)
        except rospy.ROSException:
            rospy.logwarn("播报服务暂不可用，任务继续（无语音播报）")

        rospy.loginfo("mission_controller_node 已启动，共 %d 个房间", len(self.rooms))

    def scene_callback(self, msg):
        if self.current_room is None:
            return
        if msg.room_type and msg.room_type != self.current_room:
            return
        self.scene_buffer.append(msg)

    def _get_amcl_xy(self):
        try:
            msg = rospy.wait_for_message(
                "/amcl_pose", PoseWithCovarianceStamped, timeout=2.0
            )
            return msg.pose.pose.position.x, msg.pose.pose.position.y
        except rospy.ROSException:
            return None, None

    def _in_room_bounds(self, room_id, x, y):
        bounds = self.room_bounds.get(room_id, [])
        if len(bounds) != 4:
            return False
        x_min, y_min, x_max, y_max = bounds
        return x_min <= x <= x_max and y_min <= y <= y_max

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
                x, y = self._get_amcl_xy()
                if x is not None and self._in_room_bounds(rid, x, y):
                    rospy.logwarn(
                        "导航未到目标点，但已在 %s 区域内 (%.2f, %.2f)，继续识别",
                        room.get("name", rid),
                        x,
                        y,
                    )
                else:
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
        if self.announce is None:
            rospy.logwarn("跳过语音播报：/announce_scene 不可用")
        else:
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
