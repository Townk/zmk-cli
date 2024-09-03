#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------
{
  pkgs,
  zephyr,
  keymap-drawer,
  zmk-cli,
}:
with pkgs;
  mkShell {
    packages = [
      (zephyr.sdk.override {
        targets = [
          "arm-zephyr-eabi"
        ];
      })
      zephyr.pythonEnv
      zephyr.hosttools-nix
      cmake
      ninja
      zmk-cli
      keymap-drawer
    ];
  }
