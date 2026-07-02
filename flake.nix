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

            # Wrap the 'arc' binary so it ALWAYS has access to this specific
            # version of PHP, regardless of the user's system environment.
            #
            # We point makeWrapper at the real script (still named "arc")
            # instead of wrapping it in place. Arcanist selects its toolset
            # from basename(argv[0]) (see ArcanistRuntime::newToolset), and
            # bin/arc is a "#!/usr/bin/env php" shebang script: the kernel
            # passes the exec'd pathname to PHP as argv[0], ignoring exec -a.
            # wrapProgram would rename the target to ".arc-wrapped", so PHP
            # would see basename ".arc-wrapped" and reject the toolset.
            mkdir -p $out/bin
            makeWrapper $out/libexec/arcanist/bin/arc $out/bin/arc \
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
