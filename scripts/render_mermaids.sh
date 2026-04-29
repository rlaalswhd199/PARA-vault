#!/usr/bin/env bash
# render_mermaids.sh — vault 내 모든 .md의 mermaid 블록을 PNG로 렌더.
#
# 사용:
#   1. (한 번만) brew install mermaid-cli
#   2. bash scripts/render_mermaids.sh
#
# 동작:
#   - vault 내 .md 파일을 스캔, mermaid 블록 추출
#   - 노트와 같은 디렉토리에 <노트이름>_arch.png 로 렌더
#   - .md가 PNG보다 새것이면 재렌더, 아니면 skip (mtime 비교)
#   - _Templates/는 제외
#
# 옵션:
#   --force    이미 최신이어도 모두 재렌더
#   --width N  PNG 가로 픽셀 (기본 2000)

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$VAULT_ROOT"

FORCE=0
WIDTH=2000

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=1; shift;;
        --width) WIDTH="$2"; shift 2;;
        *) echo "unknown arg: $1" >&2; exit 1;;
    esac
done

# mermaid-cli 확인
if ! command -v mmdc >/dev/null 2>&1; then
    echo "❌ mermaid-cli (mmdc) 가 설치되어 있지 않습니다." >&2
    echo "   설치: brew install mermaid-cli" >&2
    echo "   또는: npm install -g @mermaid-js/mermaid-cli" >&2
    exit 1
fi

# mermaid 블록이 있는 .md 찾기 (_Templates/ 제외)
MD_FILES=()
while IFS= read -r -d '' file; do
    MD_FILES+=("$file")
done < <(grep -lrz '```mermaid' --include='*.md' . | grep -v '/_Templates/')

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
    echo "mermaid 블록을 가진 .md 파일이 없습니다."
    exit 0
fi

rendered=0
skipped=0
failed=0

for md in "${MD_FILES[@]}"; do
    base="$(basename "$md" .md)"
    dir="$(dirname "$md")"
    png="$dir/${base}_arch.png"

    # 최신이면 skip (--force 가 아닐 때)
    if [[ $FORCE -eq 0 && -f "$png" && "$png" -nt "$md" ]]; then
        echo "⏭  skip (up-to-date): $png"
        skipped=$((skipped + 1))
        continue
    fi

    # mermaid 블록 추출
    tmp="$(mktemp -t mermaid.XXXXXX.mmd)"
    awk '/^```mermaid$/{flag=1; next} /^```$/{if(flag){flag=0; exit}} flag' "$md" > "$tmp"

    if [[ ! -s "$tmp" ]]; then
        echo "⚠  no mermaid body in: $md"
        rm -f "$tmp"
        continue
    fi

    echo "🎨 render: $md"
    if mmdc -i "$tmp" -o "$png" -t default -b transparent --width "$WIDTH" 2>&1 | tail -3; then
        rendered=$((rendered + 1))
    else
        echo "❌ failed: $md" >&2
        failed=$((failed + 1))
    fi

    rm -f "$tmp"
done

echo ""
echo "결과: rendered=$rendered, skipped=$skipped, failed=$failed"
