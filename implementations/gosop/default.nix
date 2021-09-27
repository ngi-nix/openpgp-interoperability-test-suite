{ buildGoModule
, gosop-src
, ...
}:

buildGoModule {
  pname = "gosop";
  version = "2.1.1";
  src = "${gosop-src}";
  vendorSha256 = "yOG1y/9bGEBNQ/s1mNn56oRbDgmmbIuW+mvR0yaGSP0=";
}
