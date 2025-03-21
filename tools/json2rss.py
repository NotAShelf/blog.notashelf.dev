#!/usr/bin/env python3

import os
import argparse
import json
import hashlib
import xml.etree.ElementTree as ET
from datetime import datetime, timezone


def generate_rss(posts_json_path, output_rss_path, metadata_json_path=None):
    try:
        with open(posts_json_path, "r") as file:
            data = json.load(file)
    except FileNotFoundError:
        print(f"Error: Posts JSON file not found at {posts_json_path}")
        return

    # Load metadata from JSON if it's available
    metadata = {
        "title": "NotAShelf's personal blog",
        "link": "https://blog.notashelf.dev/",
        "description": "Notes on Nix, Linux and every other pie I put a finger in",
        "language": "en-us",
    }

    if metadata_json_path:
        try:
            with open(metadata_json_path, "r") as meta_file:
                metadata.update(json.load(meta_file))
        except Exception as e:
            print(f"Warning: Could not load metadata file: {e}")

    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = metadata.get(
        "title", "NotAShelf's personal blog"
    )
    ET.SubElement(channel, "link").text = metadata.get(
        "link", "https://blog.notashelf.dev/"
    )
    ET.SubElement(channel, "description").text = metadata.get(
        "description", "Notes on Nix, Linux and every other pie I put a finger in"
    )
    ET.SubElement(channel, "language").text = metadata.get("language", "en-us")
    ET.SubElement(channel, "pubDate").text = datetime.now(timezone.utc).strftime(
        "%a, %d %b %Y %H:%M:%S +0000"
    )

    # Add each post to the feed as an item
    posts = data.get("posts", [])
    for post in reversed(posts):
        item = ET.SubElement(channel, "item")
        ET.SubElement(item, "title").text = post.get("title", "")
        ET.SubElement(item, "link").text = post.get("url", "")
        ET.SubElement(item, "description").text = post.get("description", "")

        pub_date = datetime.strptime(
            post.get("date", "1970-01-01"), "%Y-%m-%d"
        ).strftime("%a, %d %b %Y %H:%M:%S +0000")
        ET.SubElement(item, "pubDate").text = pub_date

        feed_url = metadata.get("link", "https://blog.notashelf.dev/") + "feed.xml"
        ET.SubElement(
            channel,
            "{http://www.w3.org/2005/Atom}link",
            rel="self",
            href=feed_url,
        )

        # This should be deterministic enough for our case.
        unique_string = (
            f"{post.get('title', '')}{post.get('date', '')}{post.get('url', '')}"
        )
        guid_hash = hashlib.sha256(unique_string.encode("utf-8")).hexdigest()
        ET.SubElement(item, "guid").text = guid_hash

    # ElementTree -> string
    rss_tree = ET.ElementTree(rss)
    rss_tree.write(output_rss_path, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate an RSS feed from a JSON file."
    )
    parser.add_argument(
        "--posts_path",
        help="Path to the posts.json file",
        default="out/posts/posts.json",
    )
    parser.add_argument(
        "--feed_path", help="Path to the output RSS feed file", default="out/feed.xml"
    )
    parser.add_argument(
        "--metadata",
        help="Path to the metadata.json file",
        default="tools/meta.json",
    )

    args = parser.parse_args()
    posts_json_path = os.environ.get("POSTS__PATH", args.posts_path)
    output_rss_path = os.environ.get("FEED_PATH", args.feed_path)
    metadata_json_path = os.environ.get("METADATA_FILE", args.metadata)

    generate_rss(posts_json_path, output_rss_path, metadata_json_path)
