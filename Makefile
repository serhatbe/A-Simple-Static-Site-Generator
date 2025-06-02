# Static Site Generator Makefile
# Variables
CONTENT_DIR    := content
OUTPUT_DIR     := pages
TAG_TEMP       := tag_temp
TEMPLATE       := layout/default.html
TAG_TEMPLATE   := layout/tag.html
STYLE_SRC      := layout/style.css
STYLE_DEST     := $(OUTPUT_DIR)/style.css
REFS           := refs.json
CSL            := apa.csl
SITE_URL       := https://continuum.codeberg.page # Update as required
VERSION_DIR    := versions
TIMESTAMP      := $(shell date +"%Y%m%d-%H%M%S")
VERSION_OUTPUT := $(VERSION_DIR)/pages-$(TIMESTAMP)
VENV_DIR       := .venv
VENV_ACTIVATE  := $(VENV_DIR)/bin/activate

# Collect markdown posts (excluding index.md)
POSTS       := $(filter-out $(CONTENT_DIR)/index.md, $(wildcard $(CONTENT_DIR)/*.md))
POST_HTML   := $(patsubst $(CONTENT_DIR)/%.md,$(OUTPUT_DIR)/%.html,$(POSTS))

# Tag pages (generated based on tag_temp/*.txt)
TAG_FILES   := $(wildcard $(TAG_TEMP)/*.txt)
TAG_PAGES   := $(patsubst $(TAG_TEMP)/%.txt,$(OUTPUT_DIR)/tag-%.html,$(TAG_FILES))

.PHONY: all clean venv search

# Final build target - now includes search generation
all: $(POST_HTML) $(TAG_PAGES) $(OUTPUT_DIR)/index.html $(OUTPUT_DIR)/rss.xml $(STYLE_DEST) search

# Virtual environment setup
$(VENV_ACTIVATE):
	python3 -m venv $(VENV_DIR)
	@echo "Virtual environment created. Activate with: source $(VENV_ACTIVATE)"

venv: $(VENV_ACTIVATE)

# Search generation target
search: $(POST_HTML) | venv
	@if [ -f "$(VENV_ACTIVATE)" ]; then \
		echo "Generating search index..."; \
		source $(VENV_ACTIVATE) && python3 scripts/search_generator.py ./$(OUTPUT_DIR); \
	else \
		echo "Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi

# Rule to convert each .md post to .html
$(OUTPUT_DIR)/%.html: $(CONTENT_DIR)/%.md | $(TAG_TEMP) $(OUTPUT_DIR)
	./scripts/build-single-post.sh "$<" "$@"

# Index page depends on generated post HTML and tag files
$(OUTPUT_DIR)/index.html: $(POST_HTML) $(TAG_FILES)
	./scripts/build-index.sh

# Generate each tag page
$(OUTPUT_DIR)/tag-%.html: $(TAG_TEMP)/%.txt
	./scripts/build-tag-pages.sh $*

# RSS feed generation
$(OUTPUT_DIR)/rss.xml: $(POST_HTML)
	./scripts/build-rss.sh "$(OUTPUT_DIR)" "$(SITE_URL)"

# Copy static stylesheet
$(STYLE_DEST): $(STYLE_SRC) | $(OUTPUT_DIR)
	cp $(STYLE_SRC) $(STYLE_DEST)

# Create output directories
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(TAG_TEMP):
	mkdir -p $(TAG_TEMP)

# Clean build artifacts (now includes venv cleanup)
clean:
	find $(OUTPUT_DIR) -type f \( \
	  \( -name "*.html" ! -name "search.html" \) -o \
	  -name "*.xml" -o -name "*.css" \
	\) -delete
	rm -rf $(TAG_TEMP)

# Clean everything including virtual environment
clean-all: clean
	rm -rf $(VENV_DIR)

# === Versioning Target ===
version: all
	mkdir -p $(VERSION_OUTPUT)
	cp -r $(OUTPUT_DIR)/* $(VERSION_OUTPUT)/
	echo "Version created at: $(VERSION_OUTPUT)"

# Serve locally
serve: all
	@echo "Starting development server at http://localhost:8000"
	@cd $(OUTPUT_DIR) && python3 -m http.server 8000

# Force rebuild everything
rebuild: clean all

# Rebuild tag pages only
tags: $(TAG_PAGES)

# Generate RSS feed
rss: $(OUTPUT_DIR)/rss.xml

# Debugging info
debug:
	@echo "CONTENT_DIR: $(CONTENT_DIR)"
	@echo "OUTPUT_DIR:  $(OUTPUT_DIR)"
	@echo "TEMPLATE:    $(TEMPLATE)"
	@echo "TAG_TEMPLATE:$(TAG_TEMPLATE)"
	@echo "POSTS:       $(POSTS)"
	@echo "POST_HTML:   $(POST_HTML)"
	@echo "TAG_FILES:   $(TAG_FILES)"
	@echo "TAG_PAGES:   $(TAG_PAGES)"
	@echo "VENV_DIR:    $(VENV_DIR)"
	@echo "VENV_ACTIVATE: $(VENV_ACTIVATE)"

# Help target
help:
	@echo "Static Site Generator"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the entire site including search index (default)"
	@echo "  venv      - Create Python virtual environment"
	@echo "  search    - Generate search index (requires venv)"
	@echo "  clean     - Remove all generated files"
	@echo "  clean-all - Remove generated files and virtual environment"
	@echo "  serve     - Build and serve the site locally"
	@echo "  rebuild   - Clean and rebuild everything"
	@echo "  tags      - Rebuild tag pages only"
	@echo "  rss       - Generate RSS feed"
	@echo "  version   - Save a snapshot of the current build output"
	@echo "  debug     - Show debugging information"
	@echo "  help      - Show this help message"