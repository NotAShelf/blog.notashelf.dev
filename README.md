# blog.notashelf.dev

Source code of my personal blog, built with Pandoc and an overcomplicated bash
script. Rendered version is available at https://blog.notashelf.dev

## Building

The `gen.sh` script can be used to build the website, including compiling the
stylesheets and generating static pages from markdown. Upon running this
script[^1], the build result will be available in the `out/` directory relative
to the script.

You may serve the built static pages via Python's `http` module, or spin up your
own webserver through another means.

## Contributing

Changes are welcome, feel free to make an issue if you wish to ask a question or
create a pull request if something catches your eye.

## License

Available under the [CC BY License](LICENSE).

[^1]:
    Make sure you always read bash scripts you see on the internet before
    actually running them.
