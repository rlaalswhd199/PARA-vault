#!/usr/bin/env bash
# render_mermaids.sh — vault 내 모든 .md의 mermaid 블록을 PNG로 렌더.
#
# 사용:
#   bash scripts/render_mermaids.sh
#
# 동작:
#   - vault 내 .md 파일을 스캔, mermaid 블록 추출
#   - PNG는 3_Resources/Papers/<노트이름>_arch.png 에 저장
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
PNG_DIR="$VAULT_ROOT/3_Resources/Papers"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=1; shift;;
        --width) WIDTH="$2"; shift 2;;
        *) echo "unknown arg: $1" >&2; exit 1;;
    esac
done

# mermaid-cli 확인 (로컬 설치 우선)
MMDC="$VAULT_ROOT/.npm-local/node_modules/.bin/mmdc"
if [[ ! -x "$MMDC" ]]; then
    MMDC="$(command -v mmdc 2>/dev/null || true)"
fi
if [[ -z "$MMDC" ]]; then
    echo "❌ mermaid-cli (mmdc) 가 설치되어 있지 않습니다." >&2
    echo "   설치: cd $VAULT_ROOT && npm install --prefix .npm-local @mermaid-js/mermaid-cli" >&2
    exit 1
fi

# puppeteer --no-sandbox 설정 (Linux sandbox 제한 우회)
PUPPETEER_CFG="$(mktemp -t puppeteer.XXXXXX.json)"
echo '{"args":["--no-sandbox"]}' > "$PUPPETEER_CFG"
trap 'rm -f "$PUPPETEER_CFG"' EXIT

# mermaid 블록이 있는 .md 찾기 (_Templates/ 제외)
MD_FILES=()
while IFS= read -r file; do
    MD_FILES+=("$file")
done < <(grep -rl '```mermaid' --include='*.md' . | grep -v '/_Templates/' | grep -v '/\.npm-local/' | sort)

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
    echo "mermaid 블록을 가진 .md 파일이 없습니다."
    exit 0
fi

rendered=0
skipped=0
failed=0

for md in "${MD_FILES[@]}"; do
    base="$(basename "$md" .md)"
    png="$PNG_DIR/${base}_arch.png"

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

    echo "🎨 render: $md → $png"
    if "$MMDC" -i "$tmp" -o "$png" -t default -b transparent --width "$WIDTH" -p "$PUPPETEER_CFG" 2>&1 | grep -v '^$'; then
        rendered=$((rendered + 1))
    else
        echo "❌ failed: $md" >&2
        failed=$((failed + 1))
    fi

    rm -f "$tmp"
done

echo ""
echo "결과: rendered=$rendered, skipped=$skipped, failed=$failed"
