{
  description = "Arcanist - command-line tool for Phorge";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.php
            pkgs.git
          ];

          shellHook = ''
            export PATH="$PWD/bin:$PATH"
            echo "arcanist dev shell ($(php --version | head -n1))"
          '';
        };
      });
}
