# A-Simple-Static-Site-Generator

A minimal, extensible static site generator using `make`, `pandoc`, and shell scripts. It converts Markdown files into styled HTML, supports tags, search indexing, RSS feeds, and versioning.

## Features

- Converts Markdown (`.md`) to standalone HTML using `pandoc`
- Custom HTML templates and Lua filters
- Auto-injected tag links
- Per-tag HTML pages
- Bibliography and citations (`refs.json` + `apa.csl`)
- RSS feed generation
- Search indexing using `search_generator.py`
- Timestamped version snapshots
- Local development server

## Requirements

- `make`
- `pandoc`
- `python3`
- `awk`, `bash`, and common Unix tools
- Pandoc Lua filters (e.g., `dropcap.lua`, `mdlinks.lua`, etc.)

## Directory Structure

```
.
├── content/               
│   └── *.md               # Source Markdown posts (excluding index.md)
├── pages/                 
│   └── *.html             # Generated HTML files
├── layout/
│   ├── default.html       # Main page template
│   ├── tag.html           # Tag page template
│   └── style.css          # Site stylesheet
├── scripts/
│   ├── build-index.sh
│   ├── build-rss.sh
│   ├── build-single-post.sh
│   ├── build-tag-pages.sh
│   ├── dropcap.lua
│   ├── mdlinks.lua
│   ├── mermaid.lua
│   └── search_generator.py
├── tag_temp/              # Temporary files for tag generation
├── refs.json              # Optional bibliography file
├── apa.csl                # Optional CSL file for citation formatting
├── Makefile               # Build automation with GNU Make
└── README.md              # Project documentation
```

## Setup

1. Create a Python virtual environment. `make venv`
2. Run `pip install beautifulsoup4`
3. Build the entire site `make`
4. Serve locally `make serve`
5. Cleanup `make clean       # Removes generated HTML, CSS, and tag data`
6. Rebuilding `make rebuild     # Clean and rebuild everything from scratch`
7. Versioning `make version`

## Available Make Targets

|**Command**|**Description**|
|---|---|
|make|Build the site: posts, tags, index, RSS, and search index|
|make venv|Set up Python virtual environment|
|make search|Generate index.txt for search (uses search_generator.py)|
|make clean|Remove generated HTML, CSS, XML, and tag temp files|
|make clean-all|Clean everything including the virtual environment|
|make serve|Build and serve at `http://localhost:8000`|
|make rebuild|Clean and rebuild the entire site|
|make tags|Rebuild tag pages only|
|make rss|Generate the RSS feed|
|make version|Snapshot build in versions/pages-<timestamp>|
|make debug|Output debug info about paths and variables|
|make help|Show help information|
