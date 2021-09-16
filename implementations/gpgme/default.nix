{ rustPlatform
, stdenv
, lib
, gpgme
, gpgme-src
}:
let
  version = "0.1.0";
in
rustPlatform.buildRustPackage {
  pname = "gpgme-sop";
  inherit version;
  nativeBuildInputs = [
    gpgme
  ];
  src = "${gpgme-src}";
  cargoSha256 = "770h3mp/z630f0C7N3xW/QOj1m2mfb0ZktDzp4kIy64=";
}
