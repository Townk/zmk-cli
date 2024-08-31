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
  buildPythonApplication,
  fetchFromGitHub,
  lib,
  pcpp,
  platformdirs,
  poetry-core,
  pydantic,
  pydantic-settings,
  pyparsing,
  pyyaml,
}:
buildPythonApplication rec {
  pname = "keymap-drawer";
  version = "0.18.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "caksoylar";
    repo = "${pname}";
    rev = "061feefee1d1cbbae60a01fac57762ab6e7da440";
    sha256 = "sha256-y/rHw9a7ylevsQn56hEqCCh1QTcKiahOdHtrXvCANuU=";
  };

  build-system = [poetry-core];

  propagatedBuildInputs = [
    pcpp
    platformdirs
    pydantic
    pydantic-settings
    pyparsing
    pyyaml
  ];

  meta = {
    homepage = "https://github.com/caksoylar/keymap-drawer";
    description = "Visualize keymaps that use advanced features like hold-taps and combos, with automatic parsing ";
    license = lib.licenses.mit;
  };
}
