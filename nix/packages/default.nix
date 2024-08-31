#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
{
  pkgs,
  callPackage,
  flake-root,
}: {
  keymap-drawer = pkgs.python3Packages.callPackage ./keymap-drawer.nix {};
  zmk-cli = callPackage ./zmk-cli.nix {inherit flake-root;};
}
