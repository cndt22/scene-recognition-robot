#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parent.parent
include = []
for p in sorted((root / "src").rglob("*")):
    if p.is_file():
        include.append(p.relative_to(root))
include.append(Path("requirements.txt"))

out = Path(__file__).resolve().parent / "create_all_on_ubuntu.sh"
lines = [
    "#!/bin/bash",
    "# 在 Ubuntu 终端运行: bash create_all_on_ubuntu.sh",
    "set -e",
    'BASE="$HOME/scene-recognition-robot"',
    'mkdir -p "$BASE"',
    "",
]

for rel in include:
    path = root / rel
    if path.suffix.lower() in {".pgm", ".png", ".jpg"}:
        continue
    content = path.read_text(encoding="utf-8")
    dest = f"$BASE/{rel.as_posix()}"
    lines.append(f'mkdir -p "$(dirname "{dest}")"')
    lines.append(f"cat > '{dest}' << 'ENDOFFILE'")
    lines.append(content)
    lines.append("ENDOFFILE")
    lines.append("")

lines += [
    'chmod +x "$BASE/src/scene_recognition_robot/scripts/"*.py',
    'python3 "$BASE/src/scene_recognition_robot/scripts/generate_house_map.py"',
    'echo "===== 项目创建完成 ====="',
    'echo "路径: $BASE"',
    'ls "$BASE/src/scene_recognition_robot/launch/"',
]

out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {out} ({out.stat().st_size} bytes, {len(include)} files)")
