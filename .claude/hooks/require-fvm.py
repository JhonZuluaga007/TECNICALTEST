#!/usr/bin/env python3
"""PreToolUse(Bash) hook: refuse `flutter` / `dart` invocations that skip fvm.

The SDK is pinned to 3.44.9 in `.fvm/fvm_config.json`. A bare `flutter` or `dart`
runs whatever is on $PATH, which silently produces a different `pubspec.lock`, a
different `dart format` result and a different analyzer — i.e. a diff nobody can
review. Exit code 2 feeds the message back to the model so it can retry itself.

The command is tokenized with `shlex`, not split with a regex, so `flutter` or
`dart` appearing **inside a quoted string** — a grep pattern, a commit message, a
line of documentation — is one token and is never mistaken for a command. Only a
token in command position (first, or right after an unquoted `&&`, `||`, `;`,
`|`, `(`) is checked.
"""

import json
import re
import shlex
import sys

BLOCKED = {"flutter", "dart"}
SEPARATORS = {"&&", "||", ";", "|", "(", "{", "&"}
# `FOO=bar dart ...` — a leading environment assignment does not end command position.
ENV_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")


def offending_token(command: str) -> str | None:
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        # Unbalanced quotes: nothing reliable to inspect, so do not block.
        return None

    at_command_start = True
    for token in tokens:
        if token in SEPARATORS:
            at_command_start = True
            continue
        if not at_command_start:
            continue
        if ENV_ASSIGNMENT.match(token):
            continue
        if token in BLOCKED:
            return token
        at_command_start = False

    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    command = payload.get("tool_input", {}).get("command", "")
    if not isinstance(command, str):
        return 0

    token = offending_token(command)
    if token is None:
        return 0

    print(
        f"Blocked: `{token} ...` must be run through fvm.\n"
        f"This project pins Flutter 3.44.9 in .fvm/fvm_config.json; a bare `{token}` "
        f"uses whatever is on $PATH and produces a different lockfile, formatting and "
        f"analyzer output.\n"
        f"Retry the same command with an `fvm ` prefix, e.g. `fvm {token} ...`.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
