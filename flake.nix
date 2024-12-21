{
  # Reproducibility is not a concern, since nobody is *actually* supposed to reproduce
  # this project. Setting URL to "nixpkgs" allows getting nixpkgs from the local registry
  # which avoids fetching nixpkgs for simple maintenance work.
  inputs.nixpkgs.url = "nixpkgs";

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShellNoCC {
      name = "blog";
      packages = with pkgs; [
        jq
        sassc
        pandoc

        # For eslint
        nodejs-slim
      ];
    };
  };
}
