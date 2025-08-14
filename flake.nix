{
  description = "A nix flake for https://github.com/gitmachtl/cardano-signer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    srcRepo = pkgs:
      pkgs.fetchFromGitHub {
        owner = "gitmachtl";
        repo = "cardano-signer";
        rev = "v1.29.0";
        sha256 = "sha256-y8yUsmSakaR6foKh/KnRTHctZu3nN/gI0h87wt88suU=";
      };

    shortRevOrRelTag = rev:
      if nixpkgs.lib.hasPrefix "v" rev
      then rev
      else builtins.substring 0 7 rev;
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
      with pkgs; {
        packages = rec {
          default = cardano-signer;

          cardano-signer = let
            cardano-signer' = mkYarnPackage rec {
              name = "cardano-signer";
              version = "${shortRevOrRelTag src.rev}";

              src = srcRepo pkgs;

              nativeBuildInputs = [makeWrapper];

              packageJSON = "${src.outPath}/src/package.json";
              yarnLock = ./yarn-${shortRevOrRelTag src.rev}.lock;

              yarnFlags = ["--frozen-lockfile" "--production"];

              installPhase = ''
                # Expected module output path
                mkdir -p $out/libexec/cardano-signer

                # Reshape the deps dir
                mv deps/cardano-signer/src/* deps/cardano-signer/
                rmdir deps/cardano-signer/src
                rm -rf deps/cardano-signer/node_modules
                rm deps/cardano-signer/cardano-signer

                # Assemble under the libexec target
                cp -r deps node_modules $out/libexec/cardano-signer/

                # Create a bin wrapper
                makeWrapper ${nodejs}/bin/node $out/bin/cardano-signer \
                --add-flags "$out/libexec/cardano-signer/deps/cardano-signer/cardano-signer.js" \
                --set NODE_PATH "$out/libexec/cardano-signer/node_modules"
              '';
            };
          in
            runCommand "cardano-signer-${shortRevOrRelTag (srcRepo pkgs).rev}" {} ''
              # Clean up unneeded tarball
              mkdir $out
              cp -r ${cardano-signer'}/* $out
              chmod -R +w $out/tarballs
              rm -rf $out/tarballs
            '';
        };

        devShells.default = let
          update-yarn-lock = writeShellApplication {
            name = "update-yarn-lock";
            text = ''
              PKG_JSON="${(srcRepo pkgs).outPath}/src/package.json"
              cp "$PKG_JSON" .
              chmod +w package.json
              yarn install
              cp -f yarn.lock yarn-${shortRevOrRelTag (srcRepo pkgs).rev}.lock
              rm -rf yarn.lock package.json node_modules
            '';
          };
        in
          mkShell {
            packages = [
              coreutils
              figlet
              gnutar
              gzip
              jq
              lolcat
              nodejs
              update-yarn-lock
              yarn
            ];

            shellHook = ''
              figlet <<< "Cardano-signer devShell." | lolcat
              echo
              echo "Build:"
              echo
              echo "  nix build -L .#cardano-signer"
              echo
              echo "Run Locally:"
              echo
              echo "  result/bin/cardano-signer \"\''${ARGS[@]}\""
              echo
              echo "Run from repo remotely:"
              echo
              echo "  nix run github:johnalotoski/cardano-signer -- \"\''${ARGS[@]}\""
              echo
              echo "Update (see README.md for more details):"
              echo
              echo "  update-yarn-lock"
              echo
            '';
          };
      });
}
