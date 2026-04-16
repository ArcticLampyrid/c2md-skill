#!/usr/bin/env bash
# convert-to-markdown.sh - Convert files and URLs to Markdown via an isolated MarkItDown container.
#
# Features:
# - No system Python pollution, everything runs inside Docker/Podman
# - Friendly for agents and scripts
# - Supports local files, file:// URIs, and http/https URLs
#
# Usage:
#   convert-to-markdown.sh <file-path-or-uri> [file-path-or-uri ...]

set -euo pipefail

IMAGE="${C2MD_IMAGE:-mcp/markitdown}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/c2md.XXXXXX")"
chmod 755 "$WORK_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

usage() {
    cat >&2 <<'EOF'
Usage:
  convert-to-markdown.sh <file-path-or-uri> [file-path-or-uri ...]

Examples:
  convert-to-markdown.sh ./report.pdf
  convert-to-markdown.sh file:///home/user/slides.pptx
  convert-to-markdown.sh https://example.com/doc.html

Environment:
  C2MD_IMAGE   Override container image (default: mcp/markitdown)
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

detect_runtime() {
    if command -v podman >/dev/null 2>&1; then
        echo podman
    elif command -v docker >/dev/null 2>&1; then
        echo docker
    else
        die "Neither podman nor docker was found."
    fi
}

ensure_mcporter() {
    if command -v mcporter >/dev/null 2>&1; then
        return 0
    fi

    if command -v pnpm >/dev/null 2>&1; then
        die "mcporter not found. Install it with: pnpm add -g mcporter"
    elif command -v npm >/dev/null 2>&1; then
        die "mcporter not found. Install it with: npm install -g mcporter"
    else
        die "mcporter not found. Install Node.js tooling first, then install mcporter."
    fi
}

ensure_image() {
    local runtime="$1"
    if ! "$runtime" image inspect "$IMAGE" >/dev/null 2>&1; then
        echo "Pulling $IMAGE ..." >&2
        "$runtime" pull --quiet "$IMAGE"
    fi
}

resolve_local_path() {
    local input="$1"

    if [[ "$input" == file://* ]]; then
        local encoded="${input#file://}"
        python - <<'PY' "$encoded"
import sys
from urllib.parse import unquote
print(unquote(sys.argv[1]))
PY
    elif [[ "$input" = /* ]]; then
        printf '%s\n' "$input"
    else
        realpath "$input"
    fi
}

stage_file() {
    local src="$1"
    local base dest counter

    base="$(basename "$src")"
    dest="$WORK_DIR/$base"
    counter=1

    while [[ -e "$dest" ]]; do
        dest="$WORK_DIR/${counter}_$base"
        counter=$((counter + 1))
    done

    cat "$src" > "$dest"
    chmod 644 "$dest"
    printf '%s\n' "$dest"
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

RUNTIME="$(detect_runtime)"
ensure_mcporter
ensure_image "$RUNTIME"

declare -A LOCAL_URI_MAP=()

for input in "$@"; do
    if [[ "$input" == http://* || "$input" == https://* ]]; then
        continue
    fi

    resolved="$(resolve_local_path "$input")"
    [[ -f "$resolved" ]] || die "File not found: $resolved"

    if [[ -n "${LOCAL_URI_MAP[$resolved]:-}" ]]; then
        continue
    fi

    staged="$(stage_file "$resolved")"
    LOCAL_URI_MAP["$resolved"]="file:///workdir/${staged#"$WORK_DIR"/}"
done

for input in "$@"; do
    if [[ "$input" == http://* || "$input" == https://* ]]; then
        # shellcheck disable=SC2046
        mcporter call \
            --stdio "$RUNTIME" \
            $(printf -- '--stdio-arg %q ' run -i --rm "$IMAGE") \
            convert_to_markdown \
            uri="$input" \
            --output text
        continue
    fi

    resolved="$(resolve_local_path "$input")"
    uri="${LOCAL_URI_MAP[$resolved]}"

    # shellcheck disable=SC2046
    mcporter call \
        --stdio "$RUNTIME" \
        $(printf -- '--stdio-arg %q ' run -i --rm -v "$WORK_DIR:/workdir:ro" "$IMAGE") \
        convert_to_markdown \
        uri="$uri" \
        --output text
done
