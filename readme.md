## OpenPGP Interoperability Test Suite

This repository contains a nix flake to build and run the
[openpgp-interoperability-test-suite](https://gitlab.comsequoia-pgp/openpgp-interoperability-test-suite).

If you are unfamiliar with Nix Flakes, consider looking
through the following:

 - [NixOS Wiki on Flakes](https://nixos.wiki/wiki/Flakes)
 - [Introduction to Flakes by Eelco Dolstra](https://www.tweag.io/blog/2020-05-25-flakes/)

### Building

Build the package via:

```
$ nix build github:ngi-nix/openpgp-interoperability-test-suite
$ ./result/bin/openpgp-interoperability-test-suite --help
openpgp-interoperability-test-suite 0.1.0
The OpenPGP Interoperability Test Suite

USAGE:
    openpgp-interoperability-test-suite [OPTIONS]

FLAGS:
    -h, --help       Prints help information
    -V, --version    Prints version information

OPTIONS:
        --config <config>                Select config file to use [default: config.json]
        --html-out <html-out>            Write the results to a HTML file
        --json-in <json-in>              Read results from a JSON file instead of running the tests
        --json-out <json-out>            Write results to a JSON file
        --retain-tests <retain-tests>    Prunes the tests, retaining those matching the given regular expression
```

### Running

To test the `sqop` implementation for example:

1. Write the following `config.json` file:

```
{
  "drivers": [
    {
      "path": "sqop"
    }
  ],
  "rlimits": {
    "DATA": 1073741824
  }
}
```

2. Enter a shell with the desired implementation, `sqop`,
   for example:

```
$ nix-shell -p sequoia
```

3. Generate HTML or JSON outputs:

```
$ nix run github:ngi-nix/openpgp-interoperability-test-suite \
  -- --config config.json \
  --html-out out.html
  
# generates a HTML report in out.html
```
