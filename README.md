# blog.notashelf.dev

Source code of my personal blog, built with [Pandoc](https://pandoc.org) and an
unnecessarily complicated Bash script. Rendered version is available at
https://blog.notashelf.dev

## Stack

The website contents are created from Markdown notes, available in
[notes/](./notes). We use pure **HTML** and **Javascript**. **SCSS** is used for
advanced styling, and Pandoc's **Lua** filters come into play when we want to
avoid Javascript, i.e., most static features of the site.

There are no weird libraries to render/modify/abuse content in runtime. What you
see is what you get. I do modify DOM in **_one_** instance, but nothing that
justifies libraries.

The site is built with a Bash script that generates post metadata, compiles
stylesheets and copies files in place. You are welcome to, but discouraged from,
looking into it for your own sake unless you plan to contribute.

## Building

The [tools directory](./tools) contains tools used to build the site.

The `gen.sh` script can be used to build the website, including compiling the
stylesheets and generating static pages from markdown. Upon running this
script[^1], the build result will be available in the `out/` directory relative
to the script.

`json2rss.py` is a small utility script to generate a RSS feed from post data
available in `out/posts/posts.json`.

For development purposes, the built static pages can be served via Python's
`http` module. Or you may spin up your own webserver through another means. It
is also possible to open your any browser and visit the `out/` directory in the
"search" tab. I disable `$HOME` access for good measure, but it is an option.

## Using

**Ha.**

## Contributing

Changes are usually welcome. Feel free to make an issue if you wish to ask a
question or create a pull request if something catches your eye. You may also
contribute by making post suggestions in the issues tab, I'll try to respond to
those.

### Hacking

The builder script (`gen.sh`) depends on `jq`, `pandoc` and `sassc` to be in
your path. Nix users may use `nix-shell` or `direnv allow` to use available
tools for reproducible dev environments.

Non-Nix users will have to get `jq`, `pandoc` and `sassc` from their package
manager.

## License

Available under the [CC BY License](LICENSE). Please do not modify or
redistribute post contents without my express permission.

[^1]: Make sure you always read bash scripts you see on the internet before
    actually running them.
