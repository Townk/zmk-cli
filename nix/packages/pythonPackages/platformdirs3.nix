# Keymap-drawer uses version 3 of `platformdirs` but NixPkgst only has
# version 4.2 available. It's easier to brging the package from GitHub than
# creating a flake input for an old version of NixPkgs, just to get this one
# dependency
{
  pkgs,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  name = "platformdirs";
  version = "3.11.0";

  src = pkgs.fetchFromGitHub {
    owner = "platformdirs";
    repo = "${name}";
    rev = "${version}";
    sha256 = "sha256-rMPpxwPbqAtvr3RtKQDisqQnCxnBfZdolMUPpDE+tR4=";
  };

  format = "pyproject";

  nativeBuildInputs = with python3Packages; [
    hatchling
    hatch-vcs
  ];

  meta = with pkgs; {
    homepage = "https://github.com/platformdirs/platformdirs/tree/3.11.0";
    description = "A small Python module for determining appropriate platform-specific dirs";
    license = lib.licenses.mit;
  };
}
