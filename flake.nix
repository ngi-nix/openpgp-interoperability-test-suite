{
  description = "OpenPGP Interoperability Test Suite";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";

    sequoia-src = {
      url = "gitlab:sequoia-pgp/openpgp-interoperability-test-suite/main";
      flake = false;
    };

    sqop-src = {
      url = "gitlab:sequoia-pgp/sequoia-sop";
      flake = false;
    };

    gpgme-src = {
      url = "gitlab:sequoia-pgp/gpgme-sop";
      flake = false;
    };

    gosop-src = {
      url = "github:ProtonMail/gosop";
      flake = false;
    };

  };


  outputs =
    { self
    , nixpkgs
    , sequoia-src
    , rust-overlay
    , sqop-src
    , gpgme-src
    , gosop-src
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

      rust = rust-overlay.rust-bin.stable."1.48.0".default;

    in
    {

      overlay = final: prev: rec {

        openpgp-test-suite = with final;
          let
            builder = pkgs: pkgs.buildRustCrate.override {

              defaultCrateOverrides = pkgs.defaultCrateOverrides // {

                openpgp-interoperability-test-suite = attrs: {
                  src = "${sequoia-src}";

                  nativeBuildInputs = [
                    pkg-config
                    nettle
                    clang
                  ];

                  # required by custom build.rs in the nettle-sys crate
                  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

                  # required by the tera crate to load and output to html.
                  # these html templates are loaded at runtime.
                  prePatch = ''
                    substituteInPlace src/templates.rs \
                      --replace 'templates/**/*' "${sequoia-src}/templates/**/*"
                  '';

                };

              };

            };

            cargoNix = import ./Cargo.nix {
              inherit pkgs;
              buildRustCrateForPkgs = builder;
            };

          in
          cargoNix.rootCrate.build;

        # rust error at source, does not compile
        sqop = with final; callPackage ./implementations/sqop {
          inherit sqop-src;
        };

        gpgme-sop = with final; callPackage ./implementations/gpgme {
          inherit gpgme-src;
          inherit (pkgs) gpgme;
        };

        gosop = with final; callPackage ./implementations/gosop {
          inherit gosop-src;
        };

      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          openpgp-test-suite
          sqop
          gpgme-sop
          gosop;
      });

      defaultPackage =
        forAllSystems (system: self.packages."${system}".openpgp-test-suite);

    };

}
