#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成与 scene_house.world 匹配的占据栅格地图。"""

import os
import struct

# 地图参数：12m x 12m（含边界余量），分辨率 0.05m -> 240x240
RESOLUTION = 0.05
WIDTH = 240
HEIGHT = 240
ORIGIN_X = -1.0
ORIGIN_Y = -1.0

WALL_THICKNESS = 3  # 像素（约 0.15m）


def world_to_pixel(x, y):
    px = int((x - ORIGIN_X) / RESOLUTION)
    py = int((y - ORIGIN_Y) / RESOLUTION)
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

    # 家具不画入地图（避免导航目标落在障碍物上；场景识别用位置真值）
    # draw_rect(grid, 1.5, 1.7, 3.5, 3.3, 100)   # bed
    # draw_rect(grid, 6.7, 2.0, 8.3, 3.0, 100)   # table
    # draw_rect(grid, 1.6, 6.6, 2.4, 8.4, 100)   # fridge
    # draw_rect(grid, 6.5, 7.1, 8.5, 7.9, 100)   # sofa

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
