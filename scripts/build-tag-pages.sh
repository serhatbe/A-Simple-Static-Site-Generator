#!/bin/bash
set -euo pipefail

extract_title() {
  awk '/^---/{h++} h==2{exit} h==1 && /^title:/{gsub(/^title:[[:space:]]*["'\''"]?|["'\''"]?$/,""); print; exit}' "$1"
}

shopt -s nullglob
tagfiles=(tag_temp/*.txt)
shopt -u nullglob

if (( ${#tagfiles[@]} == 0 )); then
  echo "No tags to process."
  exit 0
fi

count=0
for tagfile in "${tagfiles[@]}"; do
  tag=$(basename "$tagfile" .txt)
  {
    printf "<h2>Tag: %s</h2><ul>\n" "$tag"
    while read -r post; do
      title=$(extract_title "content/$post.md")
      printf "<li><a href=\"%s.html\">%s</a></li>\n" "$post" "${title:-$post}"
    done < "$tagfile"
    printf "</ul>\n"
  } | pandoc --template=layout/tag.html --metadata title="Tag: $tag" -o "pages/tag-$tag.html"
  ((count++))
done

echo "Generated $count tag page(s)"