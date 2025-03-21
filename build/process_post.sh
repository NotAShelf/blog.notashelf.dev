#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

# Check arguments
if [[ $# -lt 7 ]]; then
  log_error "Usage: $0 <input_file> <output_file> <meta_template> <template_dir> <site_title> <site_desc> <site_url>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
META_TEMPLATE="$3"
TEMPLATE_DIR="$4"
SITE_TITLE="$5"
SITE_DESC="$6"
SITE_URL="$7"

FILENAME=$(basename "$INPUT_FILE")
SANITIZED_TITLE=$(sanitize_title "$FILENAME")

log_info "Extracting metadata from $FILENAME"

# Extract metadata
META_JSON=$(pandoc --template="$META_TEMPLATE" "$INPUT_FILE")
TITLE=$(echo "$META_JSON" | jq -r '.title // empty')
DATE=$(echo "$META_JSON" | jq -r '.date // empty')
DESCRIPTION=$(echo "$META_JSON" | jq -r '.description // empty')

# Use fallbacks if metadata is missing
[[ -z "$TITLE" ]] && TITLE="$SANITIZED_TITLE"
[[ -z "$DATE" ]] && DATE=$(extract_date "$FILENAME")
[[ -z "$DESCRIPTION" ]] && DESCRIPTION="$SITE_DESC"

log_info "Title: $TITLE"
log_info "Date: $DATE"

mkdir -p "$(dirname "$OUTPUT_FILE")"
log_info "Converting to HTML..."
pandoc --from gfm+smart --to html \
  --standalone \
  --template "${TEMPLATE_DIR}/html/page.html" \
  --css "/style.css" \
  --metadata "title=${TITLE}" \
  --metadata "description=${DESCRIPTION}" \
  --metadata "date=${DATE}" \
  "${INPUT_FILE}" -o "${OUTPUT_FILE}"

# Verify the file was created
if [[ -f "$OUTPUT_FILE" ]]; then
  log_success "Generated $OUTPUT_FILE"
else
  log_error "Failed to generate $OUTPUT_FILE"
  exit 1
fi
