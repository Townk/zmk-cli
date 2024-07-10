#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
# NixPkgs does not offer `keymap-drawer` as a python package nor a stand-alone
# application, so we have tp pull the package into our environment using
# github.
#
# This has the additional benefit of using the latest fixes on the project
# before the maintainer publishes a new bersion to PyPI.
{
  pkgs,
  python3Packages,
  platformdirs3,
}:
python3Packages.buildPythonPackage rec {
  name = "keymap-drawer";
  version = "v0.17.0";

  src = pkgs.fetchFromGitHub {
    owner = "caksoylar";
    repo = "${name}";
    rev = "main";
    sha256 = "sha256-eyCOkoVjK32cbLmC+Vgrge5ikW9nhxWc0XElUa76Ksw=";
  };

  format = "pyproject";

  nativeBuildInputs = with python3Packages; [
    poetry-core
  ];

  propagatedBuildInputs = with python3Packages; [
    pcpp
    platformdirs3
    pydantic
    pydantic-settings
    pyparsing
    pyyaml
  ];

  meta = with pkgs; {
    homepage = "https://github.com/caksoylar/keymap-drawer";
    description = "Visualize keymaps that use advanced features like hold-taps and combos, with automatic parsing ";
    license = lib.licenses.mit;
  };
}
