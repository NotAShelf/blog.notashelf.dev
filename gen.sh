#!/usr/bin/env bash
set -e
set -u
set -o pipefail

# Site Meta
title="NotAShelf's personal blog"
site_url="https://blog.notashelf.dev"
site_description="Notes on Nix, Linux and every other pie I put a finger in"

# Directories
tmpdir="$(mktemp -d)"
workingdir="$(pwd)"
templatedir="$workingdir/templates"
outdir="$workingdir"/out
posts_dir="$outdir/posts"
pages_dir="$outdir/pages"

# A list of posts
json_file="$posts_dir/posts.json"

# pandoc template
echo "\$meta-json\$" > "$workingdir/metadata.pandoc-tpl"
pd_template="$workingdir/metadata.pandoc-tpl"

create_directory() {
	if [ ! -d "$1" ]; then
		echo "Creating directory: $1"
		mkdir -p "$1"
	fi
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

# Things like robots.txt, browserconfig and manifest.json
copy_site_meta() {
	echo "Moving site meta..."
	cp "$templatedir"/meta/* "$outdir"
}

generate_posts_json() {
	echo "Generating posts index..."
	json='{"posts":['
	first=true
	for file in "$1"/notes/*.md; do
		filename=$(basename "$file")
		if [[ $filename =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
			# extract metadata from post using pandoc
   			post_meta_json = $(pandoc --template=$pd_template $filename | jq '.title,.date')
			
			if [ "$first" = true ]; then
				first=false
			else
				json="$json,"
			fi

			# JSON object with data we may want to use like a json feed file
			# this doesn't, however, actually follow jsonfeed spec
			# that is done so by the generate_jsonfeed_spec function
			json_object=$(jq -n \
				--arg name "$filename" \
				--arg url "$site_url/posts/$(basename "$file" .md).html" \
				--arg date "$date" \
				--arg title "$sanitized_title" \
				--arg path "/posts/$(basename "$file" .md).html" \
				'{name: $name, url: $url, date: $date, title: $title, path: $path}')

			# Append JSON object to the array
			json="$json$json_object"
		fi
	done
	json="$json]}"
	# Format JSON with jq
	formatted_json=$(echo "$json" | jq .)
	echo "$formatted_json" >"$2"
}

# Index page refers to the "main" page generated
generate_index_page() {
	local workingdir="$1"
	local outdir="$2"

	echo "Generating index page..."
	pandoc --from gfm --to html \
		--standalone \
		--template "$templatedir"/html/page.html \
		--css "$templatedir"/style.css \
		--variable="index:true" \
		--metadata title="$title" \
		--metadata description="$site_description" \
		"$workingdir"/templates/pages/index.md -o "$outdir"/index.html
}

generate_other_pages() {
	local workingdir="$1"
	local tmpdir="$2"
	local outdir="$3"
	local templatedir="$4"

	echo "Generating other pages..."
	for file in "$workingdir"/notes/*.md; do
		filename=$(basename "$file")
		if [[ $filename != "README.md" ]]; then
			if [[ $filename =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
				# Sanitize post title by removing date from filename
				sanitized_title=$(echo "$filename" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//; s/\.md$//; s/-/ /g; s/\b\w/\u&/g')

				# Date in the file name implies that the page we are converting
				# is a blog post. Thus, we want to convert it to HTML and place it
				# in the posts directory where "blog" posts are expected to be.
				# Since it's supposed to have lots of content, it should be added
				# a table of contents section as well.
				echo "Converting $filename..."
				pandoc --from gfm --to html \
					--standalone \
					--template "$templatedir"/html/page.html \
					--css "$templatedir"/style.css \
					--metadata title="Posts - $sanitized_title" \
					--metadata description="$site_description" \
					--highlight-style="$templatedir"/pandoc/custom.theme \
					"$file" -o "$outdir"/posts/"$(basename "$file" .md)".html
			else
				if [[ $filename != "*-md" ]]; then
					echo "Converting $filename..."
					# No date in filename, means this is a standalone page
					# convert it to html and place it in the pages directory
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
		--metadata title="Nyx | Available Posts" \
		--metadata description="$site_description" \
		"$templatedir"/pages/pages.md -o "$outdir"/pages.html
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

# Compile stylesheet
compile_stylesheet "$templatedir"/scss "$outdir"

copy_assets
copy_site_meta

# Generate HTML pages from available markdown templates
generate_index_page "$workingdir" "$outdir"
generate_other_pages "$workingdir" "$tmpdir" "$outdir" "$templatedir"

# Post data
generate_posts_json "$workingdir" "$json_file"

# Cleanup
cleanup

echo "All tasks completed successfully."
