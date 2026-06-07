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

        arcanistPkg = pkgs.stdenv.mkDerivation {
          pname = "arcanist";
          version = self.shortRev;

          src = self;

          # need makeWrapper to bundle PHP with the executable
          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            # Copy the entire arcanist directory to libexec so its internal
            # PHP file references (like __DIR__) keep working.
            mkdir -p $out/libexec/arcanist
            cp -a . $out/libexec/arcanist

            # Expose the 'arc' binary to the standard bin directory
            mkdir -p $out/bin
            ln -s $out/libexec/arcanist/bin/arc $out/bin/arc

            # Wrap the binary so that it ALWAYS has access to this specific
            # version of PHP, regardless of the user's system environment.
            wrapProgram $out/bin/arc \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.php ]}

            runHook postInstall
          '';
        };
      in
      {
        packages.default = arcanistPkg;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.php
          ];

          shellHook = ''
            export PATH="$PWD/bin:$PATH"
            echo "arcanist dev shell ($(php --version | head -n1))"
          '';
        };
      });
}
