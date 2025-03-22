# Makefile based build tooling to orchestrate everything from one place. This is by no means a good solution
# as a *lot* of logic is duplicated on purpose, specifically to allow isolating steps of the process as
# targets in the Makefile. E.g. the code to find source code is used also in the actual script. The reason
# for this is that I don't want 15 scripts that source each other randomly. The logic is relatively simple
# and we can always copy paste again. Though, please remember to update any processing logic here IF you
# are updating the scripts.
# - NotAShelf

# Current directory is the root directory. This implies that the Makefile is in the root of the
# repository, and not nested somewhere. Update if moving the Makefile
ROOT_DIR := $(CURDIR)

BUILD_DATE := "2025-03-21 09:33:41"
BUILD_USER := "NotAShelf" # XXX: maybe worth separating this and the author

# Directory paths to be used further in the script.
NOTES_DIR := notes
TEMPLATE_DIR := templates
OUT_DIR := out
FILTER_DIR := filters

OUT_POSTS_DIR := $(OUT_DIR)/posts
OUT_PAGES_DIR := $(OUT_DIR)/pages

# Site Metadata
METADATA_FILE := meta.json
SITE_TITLE := NotAShelf's personal blog
SITE_URL := https://blog.notashelf.dev
SITE_DESC := Notes on Nix, Linux and every other pie I put a finger in

# If metadata file exists, extract values
ifneq ($(wildcard $(METADATA_FILE)),)
    SITE_TITLE := $(shell jq -r '.json_title // "NotAShelf\\047s personal blog"' $(METADATA_FILE))
    SITE_URL := $(shell jq -r '.site_url // "https://blog.notashelf.dev"' $(METADATA_FILE))
    SITE_DESC := $(shell jq -r '.site_description // "Notes on Nix, Linux and every other pie I put a finger in"' $(METADATA_FILE))
endif

# Find source files from configured directories
POST_FILES := $(shell find $(NOTES_DIR) -maxdepth 1 -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*.md" 2>/dev/null || echo "")
PAGE_FILES := $(shell find $(NOTES_DIR) -maxdepth 1 -type f -name "*.md" ! -name "README.md" ! -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*.md" 2>/dev/null || echo "")
TEMPLATE_PAGES := $(shell find $(TEMPLATE_DIR)/pages -type f -name "*.md" ! -name "404.md" ! -name "posts.md" ! -name "index.md" 2>/dev/null || echo "")

# Generate output file paths
POST_HTML := $(patsubst $(NOTES_DIR)/%.md,$(OUT_POSTS_DIR)/%.html,$(POST_FILES))
PAGE_HTML := $(patsubst $(NOTES_DIR)/%.md,$(OUT_PAGES_DIR)/%.html,$(PAGE_FILES))
TEMPLATE_HTML := $(patsubst $(TEMPLATE_DIR)/pages/%.md,$(OUT_PAGES_DIR)/%.html,$(TEMPLATE_PAGES))

# Main target
all: prepare assets posts pages special-pages index json

# Prepare environment
prepare:
	@echo "Checking permissions..."
	@chmod +x $(ROOT_DIR)/build/*.sh
	@echo "Creating directories..."
	@mkdir -p $(OUT_DIR) $(OUT_POSTS_DIR) $(OUT_PAGES_DIR) $(OUT_DIR)/static
	@echo '$$meta-json$$' > $(OUT_DIR)/metadata.tpl

# CSS compilation
$(OUT_DIR)/style.css: $(TEMPLATE_DIR)/scss/main.scss
	@echo "Compiling stylesheet..."
	@sassc --style=compressed $< $@

# Assets processing
assets: $(OUT_DIR)/style.css
	@echo "Processing assets..."
	@cp -r $(TEMPLATE_DIR)/assets $(OUT_DIR)/ 2>/dev/null || true
	@cp -r $(TEMPLATE_DIR)/scripts $(OUT_DIR)/static/ 2>/dev/null || true
	@cp $(TEMPLATE_DIR)/meta/* $(OUT_DIR)/ 2>/dev/null || true

# Process all posts
posts: prepare $(POST_HTML)

# Process a single post
$(OUT_POSTS_DIR)/%.html: $(NOTES_DIR)/%.md
	@echo "Processing post: $(notdir $<)"
	@cd $(ROOT_DIR) && \
	./build/process_post.sh \
		"$(realpath $<)" \
		"$(realpath $(OUT_DIR))/posts/$(notdir $*).html" \
		"$(realpath $(OUT_DIR))/metadata.tpl" \
		"$(realpath $(TEMPLATE_DIR))" \
		"$(SITE_TITLE)" \
		"$(SITE_DESC)" \
		"$(SITE_URL)"

# Process regular pages
pages: prepare $(PAGE_HTML)

$(OUT_PAGES_DIR)/%.html: $(NOTES_DIR)/%.md
	@echo "Processing page: $(notdir $<)"
	@cd $(ROOT_DIR) && \
	./build/process_page.sh \
		"$(realpath $<)" \
		"$(realpath $(OUT_DIR))/pages/$(notdir $*).html" \
		"$(realpath $(TEMPLATE_DIR))" \
		"$(SITE_TITLE)" \
		"$(SITE_DESC)"

# Process template pages
special-pages: prepare $(TEMPLATE_HTML) $(OUT_DIR)/404.html $(OUT_PAGES_DIR)/posts.html

$(OUT_PAGES_DIR)/%.html: $(TEMPLATE_DIR)/pages/%.md
	@echo "Processing template page: $(notdir $<)"
	@cd $(ROOT_DIR) && \
	./build/process_page.sh \
		"$(realpath $<)" \
		"$(realpath $(OUT_DIR))/pages/$(notdir $*).html" \
		"$(realpath $(TEMPLATE_DIR))" \
		"$(SITE_TITLE)" \
		"$(SITE_DESC)"

# Special pages
$(OUT_DIR)/404.html: $(TEMPLATE_DIR)/pages/404.md
	@echo "Generating 404 page..."
	@pandoc --from gfm --to html \
		--standalone \
		--template "$(TEMPLATE_DIR)/html/404.html" \
		--css "style.css" \
		--metadata title="404 - Page Not Found" \
		--metadata description="$(SITE_DESC)" \
		$< -o $@

$(OUT_PAGES_DIR)/posts.html: $(TEMPLATE_DIR)/pages/posts.md
	@echo "Generating posts index page..."
	@pandoc --from gfm --to html \
		--standalone \
		--template "$(TEMPLATE_DIR)/html/posts.html" \
		--css "style.css" \
		--metadata title="Available Posts" \
		--metadata description="$(SITE_DESC)" \
		$< -o $@

# Index page
index: prepare $(OUT_DIR)/index.html

$(OUT_DIR)/index.html: $(TEMPLATE_DIR)/pages/index.md
	@echo "Generating index page..."
	@pandoc --from gfm --to html \
		--standalone \
		--template "$(TEMPLATE_DIR)/html/page.html" \
		--css "style.css" \
		--variable="index:true" \
		--metadata title="$(SITE_TITLE)" \
		--metadata description="$(SITE_DESC)" \
		$< -o $@

# Generate posts JSON index
json: prepare $(OUT_POSTS_DIR)/posts.json

$(OUT_POSTS_DIR)/posts.json:
	@echo "Generating posts JSON index..."
	@cd $(ROOT_DIR) && \
	./build/generate_json.sh \
		"$(realpath $(NOTES_DIR))" \
		"$(realpath $(OUT_DIR))/posts/posts.json" \
		"$(realpath $(OUT_DIR))/metadata.tpl" \
		"$(SITE_URL)"

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(OUT_DIR)

debug:
	@echo "SITE_TITLE: $(SITE_TITLE)"
	@echo "SITE_URL: $(SITE_URL)"
	@echo "SITE_DESC: $(SITE_DESC)"
	@echo "BUILD_DATE: $(BUILD_DATE)"
	@echo "BUILD_USER: $(BUILD_USER)"
	@echo "POST_FILES: $(POST_FILES)"
	@echo "PAGE_FILES: $(PAGE_FILES)"


# Phony targets
.PHONY: all clean prepare assets posts pages special-pages index json
