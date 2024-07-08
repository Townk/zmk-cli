{
  pkgs,
  flake-root,
}:
with pkgs;
  stdenv.mkDerivation {
    pname = "zmk-cli";
    version = "0.3.0";
    src = flake-root;
    phases = ["unpackPhase" "installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      cp "$src/bin/_zmk_lib.sh" "$out/bin/"
      cp "$src/bin/zmk" "$out/bin/"
      cp "$src/bin/zmk-bootstrap" "$out/bin/"
      cp "$src/bin/zmk-build" "$out/bin/"
      cp "$src/bin/zmk-clean" "$out/bin/"
      cp "$src/bin/zmk-flash" "$out/bin/"
    '';
  }
