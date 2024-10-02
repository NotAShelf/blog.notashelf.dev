{
  # Pin nixpkgs for reproducibility.
  nixpkgs ?
    builtins.fetchTarball {
      name = "nixpkgs-stable";
      url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
      sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
    },
  pkgs ? import nixpkgs {config = {};},
}: let
  generate-pages = pkgs.writeShellScriptBin "generate-pages" (builtins.readFile ./gen.sh);
in
  pkgs.mkShellNoCC {
    packages = [
      # The builder script as a Nix package
      generate-pages

      # Build dependencies
      pkgs.sassc # compiling stylesheets
      pkgs.pandoc # converting markdown to html
      pkgs.jq # parsing json
    ];
  }
