{
  nixpkgs ?
    builtins.fetchTarball {
      name = "nixpkgs-stable";
      url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
      sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
    },
  pkgs ? import nixpkgs {config = {};},
}:
pkgs.mkShellNoCC {
  buildInputs = builtins.attrValues {inherit (pkgs) jq sassc pandoc;};
}
