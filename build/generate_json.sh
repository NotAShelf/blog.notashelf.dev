#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

# Check if the necessary arguments have been provided to this component.
if [[ $# -lt 4 ]]; then
  log_error "Usage: $0 <posts_dir> <json_file> <meta_template> <site_url>"
  exit 1
fi

POSTS_DIR="$1"
JSON_FILE="$2"
META_TEMPLATE="$3"
SITE_URL="$4"

# Start generating JSON index
log_info "Generating posts index..."
JSON='{"posts":['
FIRST=true

# Process each post from the posts directory, looking for any files with the .md extension
# Every file there is a post, but not every file must be published directly.
if [[ -d "$POSTS_DIR" ]]; then
  for FILE in "$POSTS_DIR"/*.md; do
    if [[ -f "$FILE" ]]; then
      FILENAME=$(basename "$FILE")

      # Markdown files with *valid* dates in their titles are posts to be published. This
      # allows circumventing this mechanism by providing a bogus date, e.g., 2025-xx-xx in
      # order to skip posts in the publication mechanism.
      if [[ $FILENAME =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        # Extract metadata and store it in a JSON metadata file. This generally includes
        # the post frontmatter, i.e., title, description, date and whether to process the
        # post's word count.
        POST_META_JSON=$(pandoc --template="$META_TEMPLATE" "$FILE")

        TITLE=$(echo "$POST_META_JSON" | jq -r '.title // empty')
        DATE=$(echo "$POST_META_JSON" | jq -r '.date // empty')
        DESC=$(echo "$POST_META_JSON" | jq -r '.description // empty')

        # Use fallbacks if metadata is missing
        [[ -z "$TITLE" ]] && TITLE=$(sanitize_title "$FILENAME")
        [[ -z "$DATE" ]] && DATE=$(extract_date "$FILENAME")
        [[ -z "$DESC" ]] && DESC="No description provided"

        log_info "Adding post: $TITLE ($DATE)"

        # Add comma if not first entry
        if [ "$FIRST" = true ]; then
          FIRST=false
        else
          JSON="$JSON,"
        fi

        # Create JSON object
        JSON_OBJECT=$(jq -n \
          --arg name "$FILENAME" \
          --arg url "${SITE_URL}/posts/$(basename "$FILE" .md).html" \
          --arg title "$TITLE" \
          --arg description "$DESC" \
          --arg date "$DATE" \
          --arg path "/posts/$(basename "$FILE" .md).html" \
          '{name: $name, url: $url, title: $title, description: $description, date: $date, path: $path}')

        # Append to JSON
        JSON="$JSON$JSON_OBJECT"
      fi
    fi
  done
fi

# Complete JSON in the worst way possible.
JSON="$JSON]}"

mkdir -p "$(dirname "$JSON_FILE")"
echo "$JSON" | jq . >"$JSON_FILE"
log_success "Generated posts index at $JSON_FILE"
