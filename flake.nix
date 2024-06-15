{
  description = "vim-zellij-navigator";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    fenix,
    naersk,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [fenix.overlays.default];
      };
      supportedPlatforms = {
        aarch64-darwin = {
          rustTarget = "aarch64-apple-darwin";
        };
        aarch64-linux = {
          rustTarget = "aarch64-unknown-linux-gnu";
        };
        x86_64-darwin = {
          rustTarget = "x86_64-apple-darwin";
        };
        x86_64-linux = {
          rustTarget = "x86_64-unknown-linux-gnu";
        };
      };
      rustTarget = supportedPlatforms.${system}.rustTarget;
      apple_sdk = pkgs.darwin.apple_sdk.frameworks;
      rust-toolchain = with fenix.packages.${system};
        combine [
          stable.cargo
          stable.rustc
          stable.clippy
          stable.rustfmt
          targets.${rustTarget}.stable.rust-std
          targets.wasm32-wasi.stable.rust-std
        ];
      naersk' = pkgs.callPackage naersk {
        cargo = rust-toolchain;
        rustc = rust-toolchain;
      };
      buildInputs =
        [pkgs.openssl pkgs.curl]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [pkgs.libiconv apple_sdk.DiskArbitration apple_sdk.Foundation apple_sdk.Security apple_sdk.SystemConfiguration];
    in {
      packages.default = naersk'.buildPackage {
        src = ./.;
        buildInputs = buildInputs;
        nativeBuildInputs = [pkgs.pkg-config pkgs.perl];
        CARGO_BUILD_TARGET = "wasm32-wasi";
      };
      devShells.default = pkgs.mkShell {
        buildInputs = buildInputs;
        nativeBuildInputs = [rust-toolchain pkgs.rust-analyzer-nightly pkgs.pkg-config];
      };
    });
}
