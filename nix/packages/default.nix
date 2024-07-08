{
  callPackage,
  flake-root,
}: {
  pythonPackages = callPackage ./pythonPackages {};
  zmk-cli = callPackage ./zmk-cli.nix {inherit flake-root;};
}
