#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""语音播报节点：TTS 播报场景识别结果。"""

import shutil
import subprocess
import rospy
from scene_recognition_robot.srv import AnnounceScene, AnnounceSceneResponse


class TTSNode:
    def __init__(self):
        rospy.init_node("tts_node")

        self.engine = rospy.get_param("~engine", "auto")  # auto | espeak | pyttsx3
        self.language = rospy.get_param("~default_language", "zh")
        self.rate = rospy.get_param("~rate", 150)

        self.srv = rospy.Service("/announce_scene", AnnounceScene, self.handle_announce)
        rospy.loginfo("tts_node 已启动，引擎: %s", self.engine)

    def _espeak_binaries(self):
        bins = []
        for name in ("espeak-ng", "espeak"):
            if shutil.which(name):
                bins.append(name)
        return bins

    def _voice_candidates(self, language):
        if language == "zh":
            return ["zh", "cmn", "zh-yue", "mandarin", "en"]
        return ["en", "en-us"]

    def _speak_espeak(self, text, language):
        last_error = None
        for binary in self._espeak_binaries():
            for voice in self._voice_candidates(language):
                cmd = [binary, "-v", voice, "-s", str(self.rate), text]
                try:
                    subprocess.run(cmd, check=True, timeout=180)
                    rospy.loginfo("TTS 使用 %s -v %s", binary, voice)
                    return
                except subprocess.CalledProcessError as exc:
                    last_error = exc
                    rospy.logwarn("%s -v %s 失败，尝试下一个语音", binary, voice)
        raise RuntimeError(
            "espeak 中文不可用，请执行: sudo apt install espeak-ng espeak-ng-data"
        ) from last_error

    def _speak_pyttsx3(self, text):
        import pyttsx3

        engine = pyttsx3.init()
        engine.setProperty("rate", self.rate)
        engine.say(text)
        engine.runAndWait()

    def speak(self, text, language="zh"):
        rospy.loginfo("语音播报: %s", text)
        errors = []

        if self.engine in ("auto", "espeak"):
            try:
                self._speak_espeak(text, language)
                return
            except Exception as exc:
                errors.append("espeak: %s" % exc)
                if self.engine == "espeak":
                    raise

        if self.engine in ("auto", "pyttsx3"):
            try:
                self._speak_pyttsx3(text)
                return
            except Exception as exc:
                errors.append("pyttsx3: %s" % exc)

        raise RuntimeError("所有 TTS 引擎均失败: %s" % "; ".join(errors))

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
