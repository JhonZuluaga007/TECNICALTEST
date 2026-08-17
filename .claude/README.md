# Agent configuration

How this repo is set up for Claude Code. Everything here is committed on purpose: the point
is that an agent session behaves the same way for whoever runs it next.

```
CLAUDE.md              always in context — invariants, commands, architecture map
.mcp.json              Dart/Flutter MCP server, running on the fvm-pinned SDK
.claude/
├── settings.json      permissions, hooks, MCP opt-in
├── hooks/             require-fvm.py (PreToolUse) · format-dart.py (PostToolUse)
├── skills/            loaded on demand, one per kind of work
└── agents/            subagents with their own context window and tool scope
```

## The three tiers, and why

**`CLAUDE.md` — always loaded, so it stays short.** Only what is needed on *every* turn: the
`fvm` rule, the layer map, the load-bearing types, the definition of done, and what not to
touch. Rationale and detail live one level down. Anything that grows here is a candidate for
a skill.

**Skills — loaded on demand.** Each holds the traps that are invisible in the code, so they
cost nothing until the matching work starts.

| Skill | Loaded when |
|---|---|
| `flutter-architecture` | Creating a file, moving code between layers, touching DI |
| `flutter-codegen` | Editing a `@freezed` / `@injectable` / `fromJson` class |
| `flutter-testing` | Writing or debugging a test |
| `flutter-widgets` | Anything under `presentation/` or `core/common_widgets/` |
| `flutter-verify` | Claiming a change is done; reading analyze/test output |
| `phase-workflow` | Running a roadmap phase, writing a PR doc |

Invoke one manually with `/flutter-testing`, or let the model pick it up from the description.

**Agents — separate context windows.** This is where the real context saving happens: the
subagent absorbs the file dumps and the tool output, and only its conclusion comes back.

| Agent | Tools | Why it exists |
|---|---|---|
| `flutter-verifier` | Bash + read | `fvm flutter test` prints hundreds of lines. The agent runs the whole gate and returns a five-line verdict plus the failing excerpts |
| `flutter-architect` | read-only | Plans before code exists; greps the 700-line changelog so the main session never has to read it |
| `flutter-test-author` | write + Bash | Writes a suite and mutation-verifies it, which means many runs of many tests |
| `flutter-reviewer` | read-only | Reads a whole diff against the invariant checklist and reports findings only |

The built-in `Explore` agent covers broad "where is X" sweeps.

## Hooks

Both are Python, both are tested, both fail open (a broken hook never blocks work).

- **`require-fvm.py`** (PreToolUse on Bash) — refuses a bare `flutter`/`dart`, since the SDK
  is pinned to 3.44.9 and an unpinned one produces a different lockfile, a different
  `dart format` result and a different analyzer. It tokenizes with `shlex`, so `dart` inside a
  quoted string — a grep pattern, a commit message — is never mistaken for a command.
  16 cases in the test matrix, including that one.
- **`format-dart.py`** (PostToolUse on Edit/Write) — runs `fvm dart format` on the file just
  written, so the "no diff" gate can never fail at the end of a change. Skips generated files.

## MCP

`.mcp.json` runs the Dart SDK's own MCP server through `fvm`, so its analyzer is the pinned
3.44.9 one. On this SDK the server is **`dart and flutter tooling` v0.1.4**, and it exposes
exactly these 13 tools — verified over a real stdio session, not read off the `--help`:

```
analyze_files  lsp  dtd  pub  pub_dev_search  read_package_uris  rip_grep_packages  roots
hot_reload  hot_restart  widget_inspector  get_runtime_errors  flutter_driver_command
```

**There is no `run_tests`, `dart_format` or `dart_fix` here.** `--help` lists them as feature
names, but v0.1.4 does not register them. Do not plan around them: tests and formatting go
through the `fvm` CLI and the `flutter-verifier` agent.

Two measurements worth keeping, because both were surprises:

- `analyze_files` works end to end against this project (`-> No errors`), and the server asks
  the client for `roots` before it can do anything — a client that answers with no root gets
  a server that analyzes nothing.
- Running the server from **outside** the project directory yields a *different* server
  (v0.1.1) with 24 tools, including `run_tests` — because `fvm dart` outside the project falls
  back to the global SDK. That larger tool set is not worth chasing: taking it means giving up
  the version pin, which is the reason `fvm` is mandatory here in the first place. Explicit
  `--dart-sdk` / `--flutter-sdk` flags were tested and change nothing.

`.claude/settings.json` opts in via `enabledMcpjsonServers`; the first session still asks for
approval, and the tools only appear after a restart — creating `.mcp.json` mid-session does
not connect it.

## Permissions

`settings.json` allowlists the read-only and routine commands (`fvm flutter analyze|test`,
`fvm dart format`, `build_runner`, read-only git, grep/find/awk) so they stop prompting. It
puts `git commit`, `git push`, `git reset`, `git checkout` and `gh pr create` behind an
explicit ask, and denies reading `env/*.json` and Android signing material outright.

## Extending this

- A rule that applies to *every* turn → `CLAUDE.md`, one line.
- A rule that applies to one kind of work → a skill. Keep the description specific about
  **when to load it**; that sentence is the whole retrieval mechanism.
- Work that produces a lot of output and one small conclusion → an agent.
- Something that must happen every time regardless of what the model decides → a hook.
