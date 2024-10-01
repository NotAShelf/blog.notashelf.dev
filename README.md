# blog.notashelf.dev

Source code of my personal blog, built with [Pandoc](https://pandoc.org) and an
unnecessarily complicated Bash script. Rendered version is available at
https://blog.notashelf.dev

## Stack

The website contents are pure **HTML** and **Javascript**. **SCSS** is used for
styling. There are no weird libraries to render/modify/abuse content in runtime.
What you see is what you get. I do modify DOM in **_one_** instance, but nothing
that justifies libraries.

The site is built with a Bash script that generates post metadata, compiles
stylesheets and copies files in place. You are welcome to, but discouraged from
looking into the script unless you plan to run it.

## Building

The `gen.sh` script can be used to build the website, including compiling the
stylesheets and generating static pages from markdown. Upon running this
script[^1], the build result will be available in the `out/` directory relative
to the script.

You may serve the built static pages via Python's `http` module, or spin up your
own webserver through another means. You can also open your web browser and
visit the `out/` directory in the "search" tab. I disable `$HOME` access for
good measure, but it could be an option for you.

### Using

Ha.

## Contributing

Changes are welcome, feel free to make an issue if you wish to ask a question or
create a pull request if something catches your eye. You may also "contribute"
by making post suggestions in the issues tab.

### Hacking

The builder script (`gen.sh`) depends on `jq`, `pandoc` and `sassc` to be in
your path. Nix users may use `nix-shell` or `direnv allow` to use available
tools for reproducible dev environments.

Non-Nix users will have to get `jq`, `pandoc` and `sassc` from their package
manager.

## License

Available under the [CC BY License](LICENSE). Please do not modify or
redistribute post contents without my express permission.

[^1]:
    Make sure you always read bash scripts you see on the internet before
    actually running them.
