#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Site Metadata
default_title="NotAShelf's personal blog"
default_site_url="https://blog.notashelf.dev"
default_site_description="Notes on Nix, Linux and every other pie I put a finger in"
metadata_file="${METADATA_FILE:-meta.json}"

if [[ -f "$metadata_file" ]]; then
    echo "Metadata file exists, extracting site metadata."
    json_title=$(jq -r '.json_title // empty' "$metadata_file")
    site_url=$(jq -r '.site_url // empty' "$metadata_file")
    site_description=$(jq -r '.site_description // empty' "$metadata_file")
fi

json_title=${json_title:-$default_title}
site_url=${site_url:-$default_site_url}
site_description=${site_description:-$default_site_description}

# Work Directories
tmpdir="$(mktemp -d)"
workingdir="$(pwd)"
templatedir="$workingdir/templates"
outdir="$workingdir"/out
posts_dir="$outdir/posts"
pages_dir="$outdir/pages"

# A list of posts
json_file="$posts_dir/posts.json"

create_directory() {
    if [ ! -d "$1" ]; then
        echo "Creating directory: $1"
        mkdir -p "$1"
    fi
}

generate_pandoc_metadata() {
    # Pandoc template
    echo "\$meta-json\$" > "$outdir/metadata.pandoc-tpl"
    pd_template="$outdir/metadata.pandoc-tpl"
}

compile_stylesheet() {
    local stylesheetpath="$1"
    local outpath="$2"

    echo "Compiling stylesheet..."
    sassc --style=compressed "$stylesheetpath"/main.scss "$outpath"/style.css
}

copy_assets() {
    echo "Moving assets..."
    cp -r "$templatedir"/assets "$outdir"
}

copy_scripts() {
    echo "Moving scripts..."
    cp -r "$templatedir"/scripts "$outdir/static"
}

# Things like robots.txt, browserconfig and manifest.json
copy_site_meta() {
    echo "Moving site meta..."
    cp "$templatedir"/meta/* "$outdir"
}

generate_posts_json() {
    echo -en "Generating posts index...\n"
    json='{"posts":['
    first=true
    for file in "$1"/notes/*.md; do
        filepath=$(realpath "$file")
        filename=$(basename "$file")
        echo -en "Processing file: $filename\n"
        if [[ $filename =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            # Extract metadata from post using pandoc
            post_meta_json=$(pandoc --template="$pd_template" "$filepath")

            json_title=$(echo "$post_meta_json" | jq -r '.title')
            json_date=$(echo "$post_meta_json" | jq -r '.date')
            json_desc=$(echo "$post_meta_json" | jq -r '.description')

            if [ "$first" = true ]; then
                first=false
            else
                json="$json,"
            fi

            echo -en "\nProcessing post in $filepath: \nTitle: $json_title \nDate: $json_date \nDescription: $json_desc\n"

            # Create JSON object without extra quotes
            json_object=$(jq -n \
                --arg name "$filename" \
                --arg url "$site_url/posts/$(basename "$file" .md).html" \
                --arg title "$json_title" \
                --arg description "$json_desc" \
                --arg date "$json_date" \
                --arg path "/posts/$(basename "$file" .md).html" \
                '{name: $name, url: $url, title: $title, description: $description, date: $date, path: $path}')

            # Append JSON object to the array
            json="$json$json_object"

            # Unset used variables
            unset json_title
            unset json_date
            unset json_desc
        fi
    done

    # Complete JSON array
    json="$json]}"
    # Format JSON with jq
    formatted_json=$(echo "$json" | jq .)
    echo "$formatted_json" >"$2"
}

# Index page refers to the "main" page generated
generate_index_page() {
    local workingdir="$1"
    local outdir="$2"

    echo -en "Generating index page...\n"
    pandoc --from gfm --to html \
        --standalone \
        --template "$templatedir"/html/page.html \
        --css "$templatedir"/style.css \
        --variable="index:true" \
        --metadata title="$json_title" \
        --metadata description="$site_description" \
        "$workingdir"/templates/pages/index.md -o "$outdir"/index.html
}

generate_other_pages() {
    local workingdir="$1"
    local tmpdir="$2"
    local outdir="$3"
    local templatedir="$4"

    echo -en "Generating other pages...\n"
    for file in "$workingdir"/notes/*.md; do
        filename=$(basename "$file")
        if [[ $filename != "README.md" ]]; then
            # Date in the file name implies that the page we are converting
            # is a blog post. Thus, we want to convert it to HTML and place it
            # in the posts directory where "blog" posts are expected to be.
            # Since it's supposed to have lots of content, it should be added
            # a table of contents section as well.
            if [[ $filename =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
                # Sanitize post title by removing date from filename
                sanitized_title=$(echo "$filename" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//; s/\.md$//; s/-/ /g; s/\b\w/\u&/g')
                echo -en "Sanitized title for $filename: $sanitized_title\n"
                echo "Converting $filename..."

                # We are converting a post, so apply the appropriate title for the page
                # and Pandoc Lua filters to 1. calculate word count and 2. apply anchors
                # to headings for easier navigation.
                pandoc --from gfm+smart --to html \
                    -L filters/wordcount.lua -M wordcount=process \
                    -L filters/anchor.lua \
                    --standalone \
                    --template "$templatedir"/html/page.html \
                    --css "$templatedir"/style.css \
                    --metadata title="Posts - $sanitized_title" \
                    --metadata description="$site_description" \
                    --highlight-style="$templatedir"/pandoc/custom.theme \
                    "$file" -o "$outdir"/posts/"$(basename "$file" .md)".html
            else
                # No date in filename, means this is a standalone page
                # convert it to html and place it in the pages directory
                if [[ $filename != "*-md" ]]; then
                    echo "Converting $filename..."
                    pandoc --from gfm --to html \
                        --standalone \
                        --template "$templatedir"/html/page.html \
                        --css "$templatedir"/style.css \
                        --metadata title="$filename" \
                        --metadata description="$site_description" \
                        "$file" -o "$outdir"/pages/"$(basename "$file" .md)".html
                fi
            fi
        fi
    done

    for file in "$templatedir"/pages/*.md; do
        filename=$(basename "$file")
        if [[ $filename != "404.md" && $filename != "pages.md" ]]; then
            pandoc --from gfm --to html \
                --standalone \
                --template "$templatedir"/html/page.html \
                --css "$templatedir"/style.css \
                --metadata title="$filename" \
                --metadata description="$site_description" \
                --highlight-style="$templatedir"/pandoc/custom.theme \
                "$file" -o "$outdir"/pages/"$(basename "$file" .md)".html
        fi
    done

    echo "Generating 404 page..."
    pandoc --from gfm --to html \
        --standalone \
        --template "$templatedir"/html/404.html \
        --css "$templatedir"/style.css \
        --metadata title="404 - Page Not Found" \
        --metadata description="$site_description" \
        "$templatedir"/pages/404.md -o "$outdir"/404.html

    echo "Generating posts page..."
    pandoc --from gfm --to html \
        --standalone \
        --template "$templatedir"/html/posts.html \
        --css "$templatedir"/style.css \
        --metadata title="Available Posts" \
        --metadata description="$site_description" \
        "$templatedir"/pages/posts.md -o "$outdir"/pages/posts.html
}

cleanup() {
    echo "Cleaning up..."
    rm -rf "$tmpdir"
}

trap cleanup EXIT

# Create directories
create_directory "$outdir"
create_directory "$posts_dir"
create_directory "$pages_dir"

# Generate pandoc metadata
generate_pandoc_metadata

# Compile stylesheet
compile_stylesheet "$templatedir"/scss "$outdir"

# Copy required assets and site meta
copy_assets
copy_scripts
copy_site_meta

# Generate HTML pages from available markdown templates
generate_index_page "$workingdir" "$outdir"
generate_other_pages "$workingdir" "$tmpdir" "$outdir" "$templatedir"

# Post data
generate_posts_json "$workingdir" "$json_file"

# Cleanup
cleanup

echo "All tasks completed successfully."

# tabs as spaces
# vim: ft=bash ts=2 sw=2 et
