# Default configuration for the script. Values set here will be overriden
# by the metadata file (meta.json) if it exists.
CONTENT_DIR := notes
TEMPLATE_DIR := templates
OUT_DIR := out
FILTER_DIR := filters

METADATA_FILE := meta.json
SITE_TITLE := NotAShelf's personal blog
SITE_URL := https://blog.notashelf.dev
SITE_DESC := Notes on Nix, Linux and every other pie I put a finger in

# If metadata file exists, extract values and override what is set above.
ifneq ($(wildcard $(METADATA_FILE)),)
    SITE_TITLE := $(shell jq -r '.json_title // "NotAShelf\\047s personal blog"' $(METADATA_FILE))
    SITE_URL := $(shell jq -r '.site_url // "https://blog.notashelf.dev"' $(METADATA_FILE))
    SITE_DESC := $(shell jq -r '.site_description // "Notes on Nix, Linux and every other pie I put a finger in"' $(METADATA_FILE))
endif
