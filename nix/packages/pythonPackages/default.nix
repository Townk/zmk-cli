{callPackage}: rec {
  platformdirs3 = callPackage ./platformdirs3.nix {};
  keymap-drawer = callPackage ./keymap-drawer.nix {inherit platformdirs3;};
}
