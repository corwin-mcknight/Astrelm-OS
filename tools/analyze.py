#!/usr/bin/env python3
"""Run the checked-in clang-tidy profile on configured Astrelm system C++."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent


def default_build_dir():
    selection = ROOT / "build" / "target.json"
    if not selection.exists():
        return ROOT / "build" / "riscv64-virt-minimal"
    target = json.loads(selection.read_text())
    triplet = "-".join(target[field] for field in ("arch", "board", "payload"))
    return ROOT / "build" / triplet


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, default=default_build_dir())
    args = parser.parse_args()

    build_dir = args.build_dir.resolve()
    database = build_dir / "compile_commands.json"
    if not database.is_file():
        parser.error(f"missing {database}; configure the target with cmake -P src/build.cmake")

    clang_tidy = shutil.which("clang-tidy")
    if clang_tidy is None:
        parser.error("clang-tidy is not installed or not on PATH")

    commands = json.loads(database.read_text())
    system_dir = ROOT / "src" / "system"
    files = set()
    for command in commands:
        path = Path(command["file"])
        if not path.is_absolute():
            path = Path(command["directory"]) / path
        path = path.resolve()
        if path.suffix in {".cc", ".cpp", ".cxx"} and system_dir in path.parents:
            files.add(str(path))
    files = sorted(files)
    if not files:
        parser.error(f"no system C++ translation units in {database}")

    print(f"Analyzing {len(files)} system C++ files in {build_dir}", flush=True)
    result = subprocess.run(
        [clang_tidy, "--verify-config", "-p", str(build_dir), files[0]],
        cwd=ROOT,
        check=False,
    )
    if result.returncode != 0:
        return result.returncode
    return subprocess.run(
        [clang_tidy, "-p", str(build_dir), *files],
        cwd=ROOT,
        check=False,
    ).returncode


if __name__ == "__main__":
    sys.exit(main())
