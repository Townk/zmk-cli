{
  description = "My awesome ZMK configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.zmk-cli.url = "github:Townk/zmk-cli";

  outputs = {
    self,
    nixpkgs,
    zmk-cli,
  }: {
    inherit (zmk-cli) devShell;
  };
}
