{pkgs, ...}: let
  inherit (pkgs) lib writers;
  inherit (pkgs) stdenvNoCC pandoc jq sassc python314;
in {
  json2rss = stdenvNoCC.mkDerivation {
    pname = "json2rss";
    version = "0.1.0";

    src = ./json2rss.py;
    nativeBuildInputs = [pkgs.makeWrapper];

    buildCommand = ''
      mkdir -p $out/bin
      install -Dm755 $src $out/bin/json2rss

      wrapProgram $out/bin/json2rss \
        --prefix PATH : ${lib.makeBinPath [python314]} \
        --set METADATA_FILE ${./meta.json}
    '';

    meta.description = "Generate a rss feed from post metadata";
  };

  build-site = stdenvNoCC.mkDerivation {
    pname = "build-site";
    version = "0.1.0";

    src = ./gen.sh;
    nativeBuildInputs = [pkgs.makeWrapper];

    buildCommand = ''
      mkdir -p $out/bin
      makeWrapper $src $out/bin/build-site \
        --prefix PATH : ${lib.makeBinPath [pandoc jq sassc]} \
        --set METADATA_FILE ${./meta.json}
    '';

    meta.description = "Utility script to boostrap my website.";
  };
}
