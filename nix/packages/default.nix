#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
{
  callPackage,
  flake-root,
}: {
  pythonPackages = callPackage ./pythonPackages {};
  zmk-cli = callPackage ./zmk-cli.nix {inherit flake-root;};
}
