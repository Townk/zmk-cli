#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
{
  description = "Build environment for ZMK local builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    zephyr = {
      # Customize the version of Zephyr used by the flake here
      url = "github:zephyrproject-rtos/zephyr/v3.5.0";
      flake = false;
    };

    zephyr-nix = {
      url = "github:adisbladis/zephyr-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
      inputs.zephyr.follows = "zephyr";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    zephyr-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        flake-root = ./.;
        zephyr = zephyr-nix.packages.${system};
      in rec {
        packages = pkgs.callPackage ./nix/packages {inherit flake-root;};
        devShell = pkgs.callPackage ./nix/shell {
          inherit (packages) keymap-drawer zmk-cli;
          inherit zephyr;
        };
      }
    )
    // {
      templates = {
        default = {
          path = ./nix/template;
          description = "Flake template to build local ZMK config repositories";
          welcomeText = ''
            # Welcome to the ZMK CLI environment flake

            This flake offers a dev shell with the ZMK CLI utilities in the PATH plus the
            latest Keymap Drawer utility.

            To build your ZMK Configuration, first, bootstrap the ZMK requirements by
            running:

            ```sh
            $ zmk bootstrap
            ```

            Once the bootstrap is complete, build your configuration with:

            ```sh
            $ zmk build all
            ```

            After the build is complete, you can flash all you firmwares with:

            ```sh
            $ zmk flash all
            ```

            This will guide you to connect and put each one of your keyboards in bootload
            mode.

            Make sure to check the help information of each one of the ZMK CLI commands:

            - `zmk --help`
            - `zmk bootstrap --help`
            - `zmk build --help`
            - `zmk flash --help`
            - `zmk clean --help`
          '';
        };
      };
    };
}
