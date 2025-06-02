#!/bin/bash
set -euo pipefail

INPUT_DIR="content"
OUTPUT_DIR="pages"
TEMPLATE="layout/default.html"
TAG_TEMP="tag_temp"

# Extract title from YAML front matter
extract_title() {
    awk '
        BEGIN { in_header = 1 }
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

build_index() {
    tmpfile=$(mktemp)

    # Collect post metadata
    for file in "$INPUT_DIR"/*.md; do
        base=$(basename "$file" .md)
        [[ "$base" == "index" ]] && continue

        title=$(extract_title "$file")
        title=${title:-$base}
        date="${base:0:10}"
        year="${date:0:4}"
        mtime=$(date -r "$file" +%s)

        echo "$year|<li>$date: <a href=\"$base.html\">$title</a></li>" >> "$tmpfile"
        echo "$mtime|<li>$date: <a href=\"$base.html\">$title</a></li>" >> recent.tmp
    done

    # Build Recently Updated section (top 5 by mtime)
    recent_html="<h3>Recently Updated</h3><ul>"
    sort -r -n recent.tmp | head -n 5 | cut -d'|' -f2- >> recent.list
    while IFS= read -r line; do
        recent_html+="$line"
    done < recent.list
    recent_html+="</ul>"
    rm -f recent.tmp recent.list

    # Build yearly archive
    years=$(cut -d'|' -f1 "$tmpfile" | sort -ru)
    current_year=$(date +%Y)
    index_html=""

    for year in $years; do
        if [ "$year" = "$current_year" ]; then
            index_html+="<details open><summary><strong>$year</strong></summary><ul>"
        else
            index_html+="<details><summary><strong>$year</strong></summary><ul>"
        fi

        grep "^$year|" "$tmpfile" | sort -r | cut -d'|' -f2- >> year_items.html
        while IFS= read -r entry; do
            index_html+="$entry"
        done < year_items.html
        index_html+="</ul></details>"
        rm -f year_items.html
    done

    rm "$tmpfile"

    # Tag cloud
    tag_cloud="<h3>Tag Cloud</h3><p>"
    for tagfile in "$TAG_TEMP"/*.txt; do
        tag=$(basename "$tagfile" .txt)
        tag_cloud+="<a href=\"tag-$tag.html\">$tag</a> "
    done
    tag_cloud+="</p>"

    # Final output
    echo "$recent_html$index_html$tag_cloud" | pandoc --template="$TEMPLATE" -o "$OUTPUT_DIR/index.html"
    echo "Generated: $OUTPUT_DIR/index.html"
}

build_index