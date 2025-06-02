#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

INPUT_DIR="content"
OUTPUT_DIR="pages"
RSS_FILE="$OUTPUT_DIR/rss.xml"
SITE_URL="https://continuum.codeberg.page"

# RSS metadata
TITLE="ℂ𝕠𝕟𝕥𝕚𝕟𝕦𝕦𝕞"
DESCRIPTION="Latest posts from ℂ𝕠𝕟𝕥𝕚𝕟𝕦𝕦𝕞"
LANGUAGE="en-ca"
GENERATOR="Custom Static Site Generator"

# Extract title from HTML - macOS bash compatible  
extract_html_title() {
  local file="$1"
  local title
  
  title=$(grep -i '<title>' "$file" | sed 's/.*<title>\(.*\)<\/title>.*/\1/' | head -n 1)
  
  # Don't double-escape - HTML titles are already properly encoded
  if [ -n "$title" ]; then
    echo "$title"
  else
    echo ""
  fi
}

# Extract meta description from HTML - macOS bash compatible
extract_html_description() {
  local file="$1"
  local desc
  
  # Handle multi-line meta descriptions by reading the whole file as one line
  desc=$(tr '\n' ' ' < "$file" | \
         grep -o '<meta[^>]*name="description"[^>]*>' | \
         sed 's/.*content="\([^"]*\)".*/\1/' | \
         head -n 1)
  
  # If that didn't work, try single quotes
  if [ -z "$desc" ]; then
    desc=$(tr '\n' ' ' < "$file" | \
           grep -o '<meta[^>]*name="description"[^>]*>' | \
           sed "s/.*content='\([^']*\)'.*/\1/" | \
           head -n 1)
  fi
  
  # Clean and escape the description
  if [ -n "$desc" ]; then
    # Remove any HTML tags and clean whitespace
    desc=$(echo "$desc" | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Properly escape XML entities
    desc=$(echo "$desc" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    echo "$desc"
  else
    echo "No description."
  fi
}

# Write RSS header
{
cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${TITLE}</title>
    <link>${SITE_URL}</link>
    <description>${DESCRIPTION}</description>
    <language>${LANGUAGE}</language>
    <generator>${GENERATOR}</generator>
    <lastBuildDate>$(date -R)</lastBuildDate>
    <atom:link href="${SITE_URL}/rss.xml" rel="self" type="application/rss+xml" />
EOF
} > "$RSS_FILE"

# Add each post as an <item>
find "$OUTPUT_DIR" -maxdepth 1 -name '*.html' \
  ! -name 'index.html' \
  ! -name 'rss.xml' \
  ! -name 'tag-*.html' \
  -print0 | sort -z -r | while IFS= read -r -d '' file; do
  
  filename=$(basename "$file")
  link="${SITE_URL}/${filename}"
  title=$(extract_html_title "$file")
  desc=$(extract_html_description "$file")
  pubdate=$(date -R -r "$file")
  
  # Use filename as fallback title
  if [ -z "$title" ]; then
    title="$filename"
  fi
  
  # Ensure we have a description
  if [ -z "$desc" ]; then
    desc="No description."
  fi
  
  cat <<EOF >> "$RSS_FILE"
    <item>
      <title>$title</title>
      <link>$link</link>
      <guid>$link</guid>
      <pubDate>$pubdate</pubDate>
      <description>$desc</description>
    </item>
EOF
done

# Close the RSS file
cat <<EOF >> "$RSS_FILE"
  </channel>
</rss>
EOF

echo "Generated: $RSS_FILE"

# Basic validation if xmllint is available
if command -v xmllint >/dev/null 2>&1; then
  if xmllint --noout "$RSS_FILE" 2>/dev/null; then
    echo "✓ RSS file is valid XML"
  else
    echo "⚠ RSS file may have XML errors"
  fi
fi