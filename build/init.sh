#!/usr/bin/env bash

set -euo pipefail

source common.sh

# Read default configuration values from the config.mk in the build directory, which *should*
# be the current directory. This is a subpar solution that depends on grep and xargs, but they
# will be available in most environments.
DEFAULT_SITE_TITLE=$(grep DEFAULT_SITE_TITLE "$(dirname "$0")/config.mk" | cut -d':=' -f2- | xargs)
DEFAULT_SITE_URL=$(grep DEFAULT_SITE_URL "$(dirname "$0")/config.mk" | cut -d':=' -f2- | xargs)
DEFAULT_SITE_DESC=$(grep DEFAULT_SITE_DESC "$(dirname "$0")/config.mk" | cut -d':=' -f2- | xargs)
METADATA_FILE=$(grep METADATA_FILE "$(dirname "$0")/config.mk" | cut -d':=' -f2- | xargs)
DEFAULT_BUILD_DATE=$(grep DEFAULT_BUILD_DATE "$(dirname "$0")/config.mk" | cut -d':=' -f2- | xargs)
DEFAULT_BUILD_USER=$(grep DEFAULT_BUILD_USER "$(dirname "$0")/config.mk" | cut -d':=' -f2- | xargs)

SITE_TITLE=$DEFAULT_SITE_TITLE
SITE_URL=$DEFAULT_SITE_URL
SITE_DESC=$DEFAULT_SITE_DESC
BUILD_DATE=$DEFAULT_BUILD_DATE
BUILD_USER=$DEFAULT_BUILD_USER

# If metadata file exists, we use it to override the default values that are already set.
if [[ -f "$METADATA_FILE" ]]; then
  log_info "Metadata file exists, extracting site metadata from $METADATA_FILE"

  # Extract values, defaulting to empty string if not found
  json_title=$(jq -r '.json_title // empty' "$METADATA_FILE")
  site_url=$(jq -r '.site_url // empty' "$METADATA_FILE")
  site_description=$(jq -r '.site_description // empty' "$METADATA_FILE")

  # Use extracted values if they exist, otherwise keep defaults
  [[ -n "$json_title" ]] && SITE_TITLE="$json_title"
  [[ -n "$site_url" ]] && SITE_URL="$site_url"
  [[ -n "$site_description" ]] && SITE_DESC="$site_description"

  log_success "Metadata loaded successfully"
else
  log_warning "No metadata file found at $METADATA_FILE, using defaults"
fi

# Create a temporary file with all the configuration variables
cat >"$(dirname "$0")/config.mk" <<EOF
# Generated configuration file - DO NOT EDIT
# Generated on $BUILD_DATE by $BUILD_USER

# Site metadata
SITE_TITLE := $SITE_TITLE
SITE_URL := $SITE_URL
SITE_DESC := $SITE_DESC

# Build information
BUILD_DATE := "$BUILD_DATE"
BUILD_USER := "$BUILD_USER"
EOF

log_info "Build environment initialized with site title: $SITE_TITLE"
