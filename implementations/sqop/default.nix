{ pkg-config
, nettle
, clang
, llvmPackages
, sqop-src
, pkgs
, rustc
}:

let
  builder = pkgs: pkgs.buildRustCrate.override {
    defaultCrateOverrides = pkgs.defaultCrateOverrides // {
      openpgp-interoperability-test-suite = attrs: {
        inherit rustc;
        src = "${sqop-src}";
        # required by custom build.rs in the nettle-sys crate
        LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
        nativeBuildInputs = [
          pkg-config
          nettle
          clang
        ];
      };
    };
  };

  cargoNix = import ./Cargo.nix {
    inherit pkgs;
    rootFeatures = [ "cli" ];
    buildRustCrateForPkgs = builder;
  };

in
cargoNix.rootCrate.build
