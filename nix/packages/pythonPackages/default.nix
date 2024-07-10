#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
{callPackage}: rec {
  platformdirs3 = callPackage ./platformdirs3.nix {};
  keymap-drawer = callPackage ./keymap-drawer.nix {inherit platformdirs3;};
}
