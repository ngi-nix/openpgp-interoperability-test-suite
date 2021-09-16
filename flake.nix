{
  description = "OpenPGP Interoperability Test Suite";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";

    # nettle-sys crate seems to use a custom build.rs script that breaks
    # rustPlatform.buildRustPackage, works fine with importCargo
    import-cargo.url = "github:edolstra/import-cargo";

    sequoia-src = {
      url = "gitlab:sequoia-pgp/openpgp-interoperability-test-suite/main";
      flake = false;
    };

  };


  outputs =
    { self
    , nixpkgs
    , sequoia-src
    , import-cargo
    , ...
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        }
      );

      inherit (import-cargo.builders) importCargo;

    in
    {

      overlay = final: prev: rec {

        openpgp-test-suite = with final; stdenv.mkDerivation {
          name = "openpgp-interoperability-test-suite";
          src = "${sequoia-src}";

          nativeBuildInputs = [
            (importCargo { lockFile = "${sequoia-src}/Cargo.lock"; inherit pkgs; }).cargoHome
            rustc
            cargo
            pkg-config
            nettle
            clang
            llvm
          ];

          # required by custom build.rs in the nettle-sys crate
          LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

          # required by the tera crate to load and output to html
          # these html templates are loaded at runtime
          prePatch = ''
            substituteInPlace src/templates.rs \
              --replace 'templates/**/*' "${sequoia-src}/templates/**/*"
          '';

          buildPhase = ''
            cargo build --release --offline
          '';

          installPhase = ''
            mkdir -p $out/bin
            install -Dm775 ./target/release/openpgp-interoperability-test-suite $out/bin/
          '';

        };

      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          openpgp-test-suite;
      });

      defaultPackage =
        forAllSystems (system: self.packages."${system}".openpgp-test-suite);

    };

}
