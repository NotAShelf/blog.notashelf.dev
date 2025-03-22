{
  # Reproducibility is not a concern, since nobody is *actually* supposed to reproduce
  # this project. Setting URL to "nixpkgs" allows getting nixpkgs from the local registry
  # which avoids fetching nixpkgs for simple maintenance work.
  inputs.nixpkgs.url = "nixpkgs";

  outputs = {
    nixpkgs,
    self,
    ...
  }: let
    inherit (nixpkgs) legacyPackages lib;

    # Compose for multiple systems. Less systems seem to be reducing the eval duration
    # for, e.g., Direnv but more may be added as seen necessary. If I ever get a Mac...
    systems = ["x86_64-linux"];
    forEachSystem = lib.genAttrs systems;
    pkgsForEach = legacyPackages;
  in {
    devShells = forEachSystem (system: let
      pkgs = pkgsForEach.${system};
    in {
      default = self.devShells.${system}.blog;
      blog = pkgs.mkShellNoCC {
        name = "blog-dev";
        packages = with pkgs; [
          # Utilities required by the build tooling
          jq
          sassc
          pandoc
          python3

          # Eslint_d
          nodejs-slim
        ];
      };
    });

    packages = forEachSystem (system: let
      pkgs = pkgsForEach.${system};
    in {
      json2rss = pkgs.stdenvNoCC.mkDerivation {
        pname = "json2rss";
        version = "0-unstable-2025-03-21";

        src = ./tools/json2rss.py;
        nativeBuildInputs = [pkgs.makeWrapper];

        buildCommand = ''
          mkdir -p $out/bin
          install -Dm755 $src $out/bin/json2rss

          wrapProgram $out/bin/json2rss \
            --prefix PATH : ${lib.makeBinPath [(pkgs.python3.withPackages (_: []))]} \
            --set METADATA_FILE ${./meta.json}
        '';

        meta.description = "Generate a rss feed from post metadata";
      };

      build-site = let
        # Files that we would like to avoid copying to the build sandbox
        # and therefore the nix store.
        junkfiles = [
          "flake.nix"
          "flake.lock"
          "LICENSE"
          ".gitignore"
          ".gitattributes"
          ".editorconfig"
          ".envrc"
          "README.md"
        ];

        repoDirFilter = name: type:
          !((type == "directory") && ((baseNameOf name) == "tools"))
          && !((type == "directory") && ((baseNameOf (dirOf name)) == ".github"))
          && !(builtins.any (r: (builtins.match r (baseNameOf name)) != null) junkfiles);

        cleanBlogSource = src:
          lib.cleanSourceWith {
            filter = repoDirFilter;
            src = lib.cleanSource src;
          };
      in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "build-site";
          version =
            if (self ? rev)
            then (builtins.substring 0 7 self.rev)
            else "dirty";

          # Required by the build tooling
          nativeBuildInputs = with pkgs; [
            pandoc
            sassc
            jq
          ];

          src = cleanBlogSource ./.;
          dontConfigure = true;

          # Prepare the environment for building
          patchPhase = let
            bash = lib.getExe pkgs.bash;
          in ''
            runHook prePatch

            # Create a modified copy of the Makefile to use bash explicitly
            # This works around a weird shell bug that I think is exclusive
            # to the Nix sandbox. Thank you Skye for the tip.
            sed -i 's|./build/process_post.sh|${bash} ./build/process_post.sh|g' Makefile
            sed -i 's|./build/process_page.sh|${bash} ./build/process_page.sh|g' Makefile
            sed -i 's|./build/generate_json.sh|${bash} ./build/generate_json.sh|g' Makefile

            runHook postPatch
          '';

          # This allows skipping the install phase since the default target will
          # handle the installation. We must explicitly disable the install phase
          # to avoid errors.
          makeFlags = ["OUT_DIR=$(out)"];
          dontInstall = true;

          meta.description = "Pure, reproducible builder for my blog";
        };
    });
  };
}
