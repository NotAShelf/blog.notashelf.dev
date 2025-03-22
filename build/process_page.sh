#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

if [[ $# -lt 5 ]]; then
  log_error "Usage: $0 <input_file> <output_file> <template_dir> <site_title> <site_desc>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
TEMPLATE_DIR="$3"
SITE_TITLE="$4"
SITE_DESC="$5"

FILENAME=$(basename "$INPUT_FILE")
SANITIZED_TITLE=$(sanitize_title "$FILENAME")

log_info "Processing page: $FILENAME"

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Create the final file
pandoc --from gfm --to html \
  --standalone \
  --template "${TEMPLATE_DIR}/html/page.html" \
  --css "/style.css" \
  --metadata "title=${SANITIZED_TITLE}" \
  --metadata "description=${SITE_DESC}" \
  "${INPUT_FILE}" -o "${OUTPUT_FILE}"

log_success "Generated $OUTPUT_FILE"
