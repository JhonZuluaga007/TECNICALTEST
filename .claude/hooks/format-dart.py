#!/usr/bin/env python3
"""PostToolUse(Edit|Write) hook: run `fvm dart format` on the file just written.

`fvm dart format .` producing no diff is part of this project's definition of
done, and the pinned SDK's dart_style is the only one whose output counts.
Formatting each file as it is written keeps that gate from ever failing at the
end of a change.

Never fails the tool call: any error here is reported and swallowed.
"""

import json
import os
import subprocess
import sys


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    path = payload.get("tool_input", {}).get("file_path", "")
    if not isinstance(path, str) or not path.endswith(".dart"):
        return 0
    if not os.path.isfile(path):
        return 0
    # Generated files are formatted by their generator.
    if path.endswith((".freezed.dart", ".g.dart", ".config.dart")):
        return 0

    try:
        subprocess.run(
            ["fvm", "dart", "format", path],
            capture_output=True,
            timeout=60,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as error:
        print(f"format-dart hook: {error}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
