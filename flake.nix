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

    packages.${system} = import ./tools/all-tools.nix {
      inherit pkgs;
    };
  };
}
