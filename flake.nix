{
  description = "Small exercises to get you used to reading and writing Rust code";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, flake-utils, nixpkgs, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
          ];
        };

        cargoBuildInputs = with pkgs; lib.optionals stdenv.isDarwin [
          darwin.apple_sdk.frameworks.CoreServices
        ];

        rustVersion = pkgs.rust-bin.stable.latest;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustVersion.complete;
          rustc = rustVersion.complete;
        };
        rustlings =
          rustPlatform.buildRustPackage {
            name = "rustlings";
            version = "5.5.1";

            nativeBuildInputs = [ pkgs.git ];
            buildInputs = cargoBuildInputs;

            src = with pkgs.lib; cleanSourceWith {
              src = self;
              # a function that returns a bool determining if the path should be included in the cleaned source
              filter = path: type:
                let
                  # filename
                  baseName = builtins.baseNameOf (toString path);
                  # path from root directory
                  path' = builtins.replaceStrings [ "${self}/" ] [ "" ] path;
                  # checks if path is in the directory
                  inDirectory = directory: hasPrefix directory path';
                in
                inDirectory "src" ||
                inDirectory "tests" ||
                hasPrefix "Cargo" baseName ||
                baseName == "info.toml";
            };

            cargoLock.lockFile = ./Cargo.lock;
          };
      in
      {
        devShell = pkgs.mkShell {
          RUST_SRC_PATH = "${rustVersion.rust-src}";

          buildInputs = [
            rustVersion.complete
            rustlings
          ] ++ cargoBuildInputs;
        };
      });
}
