#!/bin/bash
set -euo pipefail

INPUT_FILE="$1"
OUTPUT_FILE="$2"

INPUT_DIR="content"
OUTPUT_DIR="pages"
TAG_TEMP="tag_temp"
TEMPLATE="layout/default.html"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TAG_TEMP"

BASENAME=$(basename -- "$INPUT_FILE")
NAME="${BASENAME%.*}"

# Extract title from YAML front matter
extract_title() {
    awk '
        BEGIN { in_header = 1; header_lines = 0 }
        /^---[[:space:]]*$/ { header_lines++ }
        header_lines == 2 { exit }
        in_header && $1 ~ /^title:/ {
            sub(/^title:[[:space:]]*/, "", $0)
            gsub(/^["'\''"]|["'\''"]$/, "", $0)
            print $0
            exit
        }
    ' "$1"
}

# Extract tags from YAML front matter
extract_tags() {
    awk '
        BEGIN { in_tags = 0 }
        /^tags:/ { in_tags = 1; next }
        in_tags && /^[[:space:]]*-[[:space:]]*/ {
            gsub(/^[[:space:]]*-[[:space:]]*/, "")
            gsub(/#.*/, "")
            if (length($0) > 0) print $0
            next
        }
        in_tags && /^[^[:space:]-]/ { exit }
    ' "$1" | xargs
}

# Skip rebuild if up to date
if [[ -f "$OUTPUT_FILE" && "$INPUT_FILE" -ot "$OUTPUT_FILE" ]]; then
    exit 0
fi

# Handle tags
tags=$(extract_tags "$INPUT_FILE")
tag_links=""

for tag in $tags; do
    [[ -z "$tag" ]] && continue
    safe_tag=$(echo "$tag" | tr -cd '[:alnum:]-_')
    echo "$NAME" >> "$TAG_TEMP/$safe_tag.txt"
    tag_links+="<a href=\"tag-$safe_tag.html\">$tag</a> "
done

# Create a temp Markdown file with tag HTML injected
TMP_MD=$(mktemp)

awk -v tags_html="$tag_links" '
    BEGIN { count = 0 }
    {
        print
        if ($0 ~ /^---$/) count++
        if (count == 2 && tags_html != "") {
            print "\n**Tags**: " tags_html "\n"
            tags_html = ""
        }
    }
' "$INPUT_FILE" > "$TMP_MD"

# Run Pandoc
pandoc -f markdown \
    --lua-filter=./scripts/dropcap.lua \
    --lua-filter=./scripts/mdlinks.lua \
    --lua-filter=./scripts/mermaid.lua \
    --template="$TEMPLATE" \
    --mathjax \
    --bibliography=./refs.json \
    --citeproc \
    --csl=./apa.csl \
    "$TMP_MD" -o "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"
rm "$TMP_MD"