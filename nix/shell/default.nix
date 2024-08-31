#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
{
  pkgs,
  keymap-drawer,
  zmk-cli,
}:
with pkgs; let
  dontCheckPython = drv: drv.overridePythonAttrs (old: {doCheck = false;});
in
  mkShell {
    packages = [
      cmake
      coreutils
      fzf
      gcc-arm-embedded
      ninja
      yq-go
      zmk-cli
      keymap-drawer
      (python3.withPackages (ps: [
        # From https://github.com/zmkfirmware/zephyr/blob/HEAD/scripts/requirements-base.txt
        ps.west
        ps.pyelftools
        ps.pyyaml
        ps.pykwalify
        ps.canopen
        ps.packaging
        ps.progress
        ps.psutil
        (dontCheckPython ps.pylink-square)
        ps.pyserial
        ps.requests
        ps.anytree
        ps.intelhex
      ]))
    ];

    env = {
      ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
      GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
    };
  }
