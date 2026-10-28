import argparse
from pathlib import Path
import re


def patch(source):
    pattern = r"(?m)^(PrestigeModeUI\.MAX_LEVEL[ \t]*=[ \t]*)60[^\r\n]*(?=\r?$)"
    updated, count = re.subn(pattern, r"\g<1>GetMaxLevel()", source)
    if count != 1:
        raise ValueError("Expected exactly one stock PrestigeModeUI.MAX_LEVEL = 60 assignment")
    return updated


def main():
    parser = argparse.ArgumentParser(description="Prepare a realm-cap PrestigeMode.lua client replacement")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error("Use a separate staging output; do not overwrite the source client")
    with args.source.open(encoding="utf-8", newline="") as source:
        result = patch(source.read())
    with args.output.open("x", encoding="utf-8", newline="") as output:
        output.write(result)


if __name__ == "__main__":
    main()
