# c2md-skill

Convert documents, web pages, and images to Markdown — without touching your system Python.

Wraps [MarkItDown](https://github.com/microsoft/markitdown) in a Docker/Podman container and exposes a single shell script. Designed for agents and automation scripts.

## Requirements

- Docker or Podman
- [mcporter](https://www.npmjs.com/package/mcporter) (`pnpm install -g mcporter`)

## Install

```bash
git clone https://github.com/ArcticLampyrid/c2md-skill.git
chmod +x c2md-skill/scripts/convert-to-markdown.sh
```

### Agent / OpenClaw integration

Copy this repo to `~/.openclaw/workspace/skills/convert-to-markdown`.

## Usage

```bash
scripts/convert-to-markdown.sh <file-or-url> [file-or-url ...]
```

See <SKILL.md> for more details.

## How it works

For local files, the script copies them into a temp directory and mounts it read-only into the container. For URLs, it calls the container directly. Either way, MarkItDown runs inside the container and the host Python environment is never touched.

## License

[The Unlicense](LICENSE) — public domain.
