#!/usr/bin/env python3

import os
import json
import re
import sys
from pathlib import Path
from datetime import date
from bs4 import BeautifulSoup, Comment

def extract_content_from_html(file_path):
    """Extract clean text content from HTML file."""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Parse with BeautifulSoup
        soup = BeautifulSoup(content, 'html.parser')
        
        # Remove script and style elements
        for script in soup(["script", "style"]):
            script.decompose()
        
        # Remove comments
        for comment in soup.find_all(string=lambda text: isinstance(text, Comment)):
            comment.extract()
        
        # Extract title
        title_tag = soup.find('title')
        title = title_tag.get_text().strip() if title_tag else "Untitled"
        
        # Extract clean text content
        text = soup.get_text()
        
        # Clean up whitespace
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)
        
        # Truncate
        text = text[:1500] if len(text) > 1500 else text
        
        return title, text
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}", file=sys.stderr)
        return "Untitled", ""

def extract_date_from_filename(filename):
    """Extract date from filename or return current date."""
    match = re.search(r'(\d{4}-\d{2}-\d{2})', str(filename))
    if match:
        return match.group(1)
    else:
        return date.today().isoformat()

def generate_search_index(pages_dir="./pages"):
    """Generate search index JSON file."""
    pages_path = Path(pages_dir)
    
    if not pages_path.exists():
        print(f"Error: Directory {pages_dir} does not exist", file=sys.stderr)
        sys.exit(1)
    
    # Find all HTML files, excluding search-related ones
    html_files = [
    f for f in pages_path.glob("*.html")
    if "search" not in f.name.lower()
    and not f.name.startswith(("_", "draft-"))
]
    html_files.sort()
    
    search_index = []
    
    for html_file in html_files:
        try:
            title, content = extract_content_from_html(html_file)
            
            # Get relative path
            rel_path = html_file.name
            
            # Extract or generate date
            file_date = extract_date_from_filename(html_file.name)
            
            entry = {
                "title": title,
                "url": rel_path,
                "date": file_date,
                "description": "",
                "tags": "",
                "content": content
            }
            
            search_index.append(entry)
            print(f"Processed: {html_file.name} - '{title}'")
            
        except Exception as e:
            print(f"Error processing {html_file}: {e}", file=sys.stderr)
            continue
    
    # Write JSON file
    search_index_path = pages_path / "search-index.json"
    
    try:
        with open(search_index_path, 'w', encoding='utf-8') as f:
            json.dump(search_index, f, indent=2, ensure_ascii=False)
        
        print(f"\n✅ Search index generated: {search_index_path}")
        print(f"📊 Generated {len(search_index)} entries")
        print(f"📊 File size: {search_index_path.stat().st_size} bytes")
        
        # Validate JSON
        with open(search_index_path, 'r', encoding='utf-8') as f:
            json.load(f)
        print("✅ JSON is valid")
        
    except Exception as e:
        print(f"Error writing search index: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    pages_dir = sys.argv[1] if len(sys.argv) > 1 else "./pages"
    generate_search_index(pages_dir)