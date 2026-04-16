# c2md-skill

A tiny, agent-friendly `convert-to-markdown` skill that wraps [MarkItDown](https://github.com/microsoft/markitdown) in an isolated container.

It is built for AI tooling and automation first:
- no system Python pollution
- simple shell entrypoint
- safe-ish host boundary for local files
- works with local files and remote URLs
- easy to vendor into OpenClaw skills or any agent workspace

## Why this exists

A lot of document-to-Markdown tooling assumes you are fine installing Python packages into the host environment. That is annoying for long-lived machines, risky for shared environments, and awkward for agent setups that should be reproducible.

`c2md-skill` avoids that by keeping the conversion backend inside Docker or Podman. The host only needs:
- a container runtime
- `mcporter`
- this repo

That makes it a nice fit for:
- OpenClaw skills
- local automation scripts
- AI agents that need one obvious command to call
- users who do not want Python dependencies sprayed onto their machine

## Features

- Runs MarkItDown in an isolated container
- Does not install Python packages into the system environment
- Supports local paths, `file://` URIs, and `http(s)://` URLs
- Stages local files into a temporary read-only mount
- Handles multiple inputs in one command
- Minimal interface, good for LLM/agent tool use

## Repository layout

```text
.
├── README.md
├── SKILL.md
└── scripts/
    └── convert-to-markdown.sh
```

## Dependencies

### Required

- `docker` or `podman`
- `mcporter`

### Runtime image

By default the script uses:

```text
mcp/markitdown
```

You can override it with `C2MD_IMAGE` if needed.

## Install

### For humans

Clone the repo somewhere stable:

```bash
git clone https://github.com/ArcticLampyrid/c2md-skill.git
cd c2md-skill
chmod +x scripts/convert-to-markdown.sh
```

Install `mcporter`:

```bash
pnpm add -g mcporter
```

Or:

```bash
npm install -g mcporter
```

Make sure Docker or Podman is available.

## Install for AI tools / agents

The intended integration pattern is: keep this repository as a plain checked-out tool dependency, then call the shell script directly.

### OpenClaw skill install

Put this repo in your skill directory and point the skill to:

```bash
scripts/convert-to-markdown.sh <input>
```

Example `SKILL.md` usage block:

```bash
scripts/convert-to-markdown.sh <file-path-or-uri> [file-path-or-uri ...]
```

### Generic agent install guidance

For agents that can call local scripts:

1. Clone this repo into a known tools directory.
2. Ensure `mcporter` plus Docker/Podman are installed.
3. Mark `scripts/convert-to-markdown.sh` executable.
4. Register that script as the tool entrypoint.

Suggested tool description:

> Convert documents, images, and URLs into Markdown using a containerized MarkItDown backend. Supports local paths, file URIs, and remote URLs. Does not modify the host Python environment.

## Usage

### Single local file

```bash
scripts/convert-to-markdown.sh ./paper.pdf
```

### Multiple files

```bash
scripts/convert-to-markdown.sh ./a.docx ./b.pptx ./c.xlsx
```

### File URI

```bash
scripts/convert-to-markdown.sh file:///home/user/report.docx
```

### Remote URL

```bash
scripts/convert-to-markdown.sh https://example.com/page.html
```

### Custom container image

```bash
C2MD_IMAGE=ghcr.io/your-org/markitdown scripts/convert-to-markdown.sh ./file.pdf
```

## How it works

For local files, the script:

1. creates a temporary working directory
2. copies each input file into it
3. mounts that directory read-only into the container
4. asks the containerized MarkItDown MCP server to convert the file

For remote URLs, it calls the container without a file mount.

This keeps the host Python environment untouched while still giving the converter access to the needed content.

## Design goals

- **Agent friendly**: one command, predictable behavior
- **Host clean**: no Python package installation required
- **Portable**: works with Docker or Podman
- **Small surface area**: easy to inspect and adapt

## Non-goals

- rich job orchestration
- caching or deduplication across runs
- managing OCR model dependencies outside the selected container image
- abstracting every MarkItDown option behind flags

## License

This project is released under **The Unlicense**. See [LICENSE](LICENSE).
