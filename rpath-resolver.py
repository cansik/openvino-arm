import argparse
import glob
import os
import subprocess
from pathlib import Path
from typing import Dict, List

files: Dict[str, Path] = {}
libs: List[Path] = []

LIB_EXTS = {".so", ".dylib"}


def get_rpaths(path: Path) -> [Path]:
    output = subprocess.check_output(["otool", "-l", str(path)]).decode("utf-8", "ignore")
    lines = output.splitlines()
    rpath_lines = [line.strip() for line in lines if "@rpath" in line]

    rpaths = [Path(path.split(" ")[1]) for path in rpath_lines]
    return rpaths


def change_rpath(rpath: Path, new_path: Path, file_path: Path):
    output = subprocess.check_output(["install_name_tool", "-change",
                                      str(rpath), str(new_path), str(file_path)]).decode("utf-8", "ignore")


def main():
    args = parse_args()

    print("creating file index...")
    for file in glob.glob(os.path.join(args.path, "**", "*"), recursive=True):
        file_path = Path(file)
        file_name = file_path.name
        files[file_name] = file_path

        if file_path.suffix in LIB_EXTS:
            libs.append(file_path)

    fix_counter = 0
    for lib in libs:
        print(f"fixing {lib}...")
        rpaths = get_rpaths(lib)

        for rpath in rpaths:
            if rpath.name not in files:
                print(f"WARNING >>>> Could not resolve {rpath}!")
                continue

            if rpath.name == lib.name:
                continue

            fix_counter += 1

            resolved_path = files[rpath.name]
            relative_path = Path(os.path.relpath(str(resolved_path.absolute()), str(lib.parent.absolute())))

            loader_path = Path("@loader_path", relative_path)
            change_rpath(rpath, loader_path, lib.absolute())

    print(f"fixed {fix_counter} rpaths!")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=str, help="Path to the unpacked wheel folder.")
    return parser.parse_args()


if __name__ == "__main__":
    main()
