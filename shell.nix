{pkgs ? import <nixpkgs> {}}:
pkgs.mkShellNoCC {
  buildInputs = builtins.attrValues {inherit (pkgs) jq sassc pandoc;};
}
