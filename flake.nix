{
  description = "OpenPGP Interoperability Test Suite";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    sequoia-src = {
      url = "gitlab:sequoia-pgp/openpgp-interoperability-test-suite/main";
      flake = false;
    };

  };


  outputs =
    { self
    , nixpkgs
    , sequoia-src
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

      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          openpgp-test-suite;
      });

      defaultPackage =
        forAllSystems (system: self.packages."${system}".openpgp-test-suite);

    };

}
