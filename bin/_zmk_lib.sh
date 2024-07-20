#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# Copyright (c) 2024 Thiago Alves
# SPDX-License-Identifier: MIT
#-------------------------------------------------------------------------------

# This file is a library of helper functions that are used by two or more
# scripts on the ZMK CLI stack.
#
# Sourcing this file will also export to your script a set of variables that
# can be used to determine which build configuration to use on the CLI
# commands.

# Function that prints an error message to `stderr` and exit the script with
# error code `1`.
#
# @param $* {string...} Text to be used as the failing message.
fail() {
  [[ "$OUT_LEVEL" != "none" ]] && printf "ERROR: %s\n\n" "$*" | fmt -w 80 >&2
  exit 1
}

# Function that prints an error message to `stderr`, followed by usage
# instructions of the script, and exit the script with error code `2`.
#
# @param $* {string...} Text to be used as the failing message.
usage_fail() {
  [[ "$OUT_LEVEL" != "none" ]] && printf "ERROR: %s\n\n" "$*" | fmt -w 80 >&2
  usage
  exit 2
}

# Starting from the giving directory (`$1`), traverse directories upwards in
# the tree, until we can find a `west.yml` file inside a `config` directory
# (`./config/west.yml`). If the `west.yml` file is found, this function will
# print the directory where it was found.
#
# @param $1 {path} The directory used to start the upward search.
find_west_root() {
  if [[ -f "$1/config/west.yml" ]]; then
    printf "%s" "$1"
  elif [[ -n "$1" ]]; then
    find_west_root "${1%/*}"
  fi
}

# Try to find the 'west' root directory on the current working directory, and
# fail if it is not found. When found, this function will print the absolute
# path of the root dir.
require_west_project() {
  local root_dir
  root_dir="$(find_west_root "$PWD")"
  [[ -n $root_dir ]] \
    || usage_fail "You must run the 'zmk' command from a ZMK user configuration project"
  printf "%s" "$root_dir"
}

# Given a shield name (`$1`), returns a modified string that the CLI uses as
# the `.uf2` artifact file name.
#
# @param $1 {string} A ZMK shield name.
artifact_name() {
  printf "%s" "zmk-$(printf "%s" "$1" | tr '_' '-')"
}

# Check if a config file (which is any file that lives in the `./config/`
# directory of the ZMK configuration) exists, and print its _basename_ in case
# it does.
#
# The file to check is given by two arguments, a core name `($1)`, and an
# extension `($2)`. This function also search for side variants of the file
# (core names with suffix `_left` or `_right`) as well.
#
# @param $1 {string} A core name for a config file.
# @param $2 {string} The extension of the file to be searched.
config_file() {
  local CONFIG_FILE="${1}.$2"
  if [[ -f "$WEST_ROOT/config/$CONFIG_FILE" ]]; then
    printf "%s" "$CONFIG_FILE"
  else
    CONFIG_FILE="${1%_left}.$2"
    if [[ -f "$WEST_ROOT/config/$CONFIG_FILE" ]]; then
      printf "%s" "$CONFIG_FILE"
    else
      CONFIG_FILE="${1%_right}.$2"
      if [[ -f "$WEST_ROOT/config/$CONFIG_FILE" ]]; then
        printf "%s" "$CONFIG_FILE"
      fi
    fi
  fi
}

# This function uses `yq` to parse the `build.yaml` file that a ZMK
# configuration should have to use the ZMK GitHub action to build it, and fill
# six auxiliar array variables that will hold values of each build
# configuration declared there.
#
# The variables filled by this function are:
#
# - ZMK_ALL_LABELS
# - ZMK_ALL_BOARDS
# - ZMK_ALL_SHIELDS
# - ZMK_ALL_EXTRA_SHIELDS
# - ZMK_ALL_CMAKE_ARGS
# - ZMK_ALL_ARTIFACTS
#
# All items in these arrays are aligned, meaning that for each index in one of
# these variables, it is guarantee that the other variables also have items on
# the same index, and all these values belong to the same build configuration.
#
# This function detects the correct keymap and conf files, even when those are
# passes as CMake arguments on the build configuration.
extract_all_build_config() {
  ZMK_ALL_LABELS=()
  ZMK_ALL_BOARDS=()
  ZMK_ALL_SHIELDS=()
  ZMK_ALL_EXTRA_SHIELDS=()
  ZMK_ALL_CMAKE_ARGS=()
  ZMK_ALL_ARTIFACTS=()

  local -a CONFIGURED_BUILDS
  local -a SHIELD
  local -a CMAKE_ARGS

  local SHIELD_BUILD
  local BOARD
  local SHIELD_STR
  local CMAKE_ARGS_STR
  local ARTIFACT_NAME
  local NICKNAME
  local KEYMAP
  local CONF
  local CMAKE_FLAG
  local FLAG_VAL
  local LABEL

  readarray CONFIGURED_BUILDS < <(yq -o=j -I=0 ".include[]" "$WEST_ROOT/build.yaml")
  for SHIELD_BUILD in "${CONFIGURED_BUILDS[@]}"; do
    BOARD="$(echo "${SHIELD_BUILD}" | yq '.board' -)"
    SHIELD_STR="$(echo "${SHIELD_BUILD}" | yq '.shield' -)"
    CMAKE_ARGS_STR="$(echo "${SHIELD_BUILD}" | yq '.cmake-args' -)"
    ARTIFACT_NAME="$(echo "${SHIELD_BUILD}" | yq '.artifact-name' -)"
    NICKNAME="$(echo "${SHIELD_BUILD}" | yq '.nickname' -)"

    IFS=' ' read -r -a SHIELD <<< "$SHIELD_STR"
    if [[ "$CMAKE_ARGS_STR" = 'null' ]]; then
      CMAKE_ARGS_STR=''
      CMAKE_ARGS=()
    else
      read -r -a CMAKE_ARGS < <(echo -n "$CMAKE_ARGS_STR")
    fi
    if [[ "$ARTIFACT_NAME" = "null" ]]; then
      ARTIFACT_NAME="$(artifact_name "${SHIELD[0]}")"
    fi

    KEYMAP="$(config_file "${SHIELD[0]}" "keymap")"
    CONF="$(config_file "${SHIELD[0]}" "conf")"
    if [[ "${#CMAKE_ARGS[@]}" -gt 0 ]]; then
      for CMAKE_FLAG in "${CMAKE_ARGS[@]}"; do
        IFS='=' read -r -a FLAG_VAL <<< "$CMAKE_FLAG"
        if [[ "${FLAG_VAL[0]}" = "-DKEYMAP_FILE" ]]; then
          KEYMAP="${FLAG_VAL[1]##*/}"
        elif [[ "${FLAG_VAL[0]}" = "-DEXTRA_CONF_FILE" ]]; then
          if [[ -n "$CONF" ]]; then
            CONF="${CONF} + "
          fi
          CONF="${CONF}${FLAG_VAL[1]##*/}"
        fi
      done
    fi

    if [[ "$NICKNAME" = "null" ]]; then
      LABEL="$ARTIFACT_NAME.uf2"
    else
      LABEL="$NICKNAME"
    fi
    LABEL="$LABEL ($BOARD, ${SHIELD[0]}"
    if [[ -n "$KEYMAP" ]]; then
      LABEL="$LABEL, $KEYMAP"
    fi
    if [[ -n "$CONF" ]]; then
      LABEL="$LABEL, $CONF"
    fi
    LABEL="$LABEL)"

    ZMK_ALL_LABELS+=("$LABEL")
    ZMK_ALL_BOARDS+=("$BOARD")
    ZMK_ALL_SHIELDS+=("${SHIELD[0]}")
    unset 'SHIELD[0]'
    ZMK_ALL_EXTRA_SHIELDS+=("${SHIELD[*]}")
    ZMK_ALL_CMAKE_ARGS+=("$CMAKE_ARGS_STR")
    ZMK_ALL_ARTIFACTS+=("$ARTIFACT_NAME")
  done
}

# Given a set of terms, this function can filter all build configurations
# extracted with the `extract_all_build_config` function and keep just the ones
# that match the terms.
#
# Each term in the arguments is used with an `AND` operation. For instance, if
# you pass the term `corne`, this function will filter all build configurations
# defined for any Corne keyboard. Now, if you give the terms `corne` and`oled`,
# this function will first filter all the Corne builds, then it will filter the
# result further to include only the ones with the term `oled` in its
# description.
#
# The remaining configurations are stored on the following variables:
#
# - ZMK_LABELS
# - ZMK_BOARDS
# - ZMK_SHIELDS
# - ZMK_EXTRA_SHIELDS
# - ZMK_CMAKE_ARGS
# - ZMK_ARTIFACTS
#
# @param $1 {"left"|"right"|"both"|""} A part target string that will
#        pre-filter shields for the given part. If this parameter is empty or
#        the string "both", there will be no filtering based on which side of
#        the keyboard to build.
# @param $* {string...} A set of terms to use to filter all build
#        configurations stored on the `ZMK_ALL_*` variables.
filter_build_configs() {
  [[ "$#" -gt 0 ]] || fail "Missing build part target on filter config function"
  local KB_PART_TARGET="$1"
  shift

  if [[ "$#" -gt 0 ]]; then
    local -a FILTERED_ZMK_LABELS=("${ZMK_ALL_LABELS[@]}")
    local -a FILTERED_ZMK_BOARDS=("${ZMK_ALL_BOARDS[@]}")
    local -a FILTERED_ZMK_SHIELDS=("${ZMK_ALL_SHIELDS[@]}")
    local -a FILTERED_ZMK_EXTRA_SHIELDS=("${ZMK_ALL_EXTRA_SHIELDS[@]}")
    local -a FILTERED_ZMK_CMAKE_ARGS=("${ZMK_ALL_CMAKE_ARGS[@]}")
    local -a FILTERED_ZMK_ARTIFACTS=("${ZMK_ALL_ARTIFACTS[@]}")
    local -a FILTER_IDX=()
    local KB
    local BUILD_ALL='n'

    for KB in "$@"; do
      if [[ "$KB" = "all" ]]; then
        ZMK_BOARDS=("${ZMK_ALL_BOARDS[@]}")
        ZMK_SHIELDS=("${ZMK_ALL_SHIELDS[@]}")
        ZMK_EXTRA_SHIELDS=("${ZMK_ALL_EXTRA_SHIELDS[@]}")
        ZMK_CMAKE_ARGS=("${ZMK_ALL_CMAKE_ARGS[@]}")
        ZMK_ARTIFACTS=("${ZMK_ALL_ARTIFACTS[@]}")
        BUILD_ALL='y'
        break
      fi
    
      FILTER_IDX=()
    
      for idx in "${!FILTERED_ZMK_LABELS[@]}"; do
        case "${FILTERED_ZMK_LABELS[$idx]}" in
          *$KB*)
            case "${FILTERED_ZMK_SHIELDS[$idx]}" in
              *_left) [[ "$KB_PART_TARGET" = "right" ]] && FILTER_IDX+=("$idx") ;;
              *_right) [[ "$KB_PART_TARGET" = "left" ]] && FILTER_IDX+=("$idx") ;;
              settings_reset) [[ -n "$KB_PART_TARGET" ]] && FILTER_IDX+=("$idx") ;;
            esac
            ;;
          *) FILTER_IDX+=("$idx") ;;
        esac
      done
    
      for idx in "${FILTER_IDX[@]}"; do
        unset "FILTERED_ZMK_LABELS[$idx]"
        unset "FILTERED_ZMK_BOARDS[$idx]"
        unset "FILTERED_ZMK_SHIELDS[$idx]"
        unset "FILTERED_ZMK_EXTRA_SHIELDS[$idx]"
        unset "FILTERED_ZMK_CMAKE_ARGS[$idx]"
        unset "FILTERED_ZMK_ARTIFACTS[$idx]"
      done
    done
    
    if [[ "$BUILD_ALL" = "n" ]]; then
      ZMK_BOARDS=("${FILTERED_ZMK_BOARDS[@]}")
      ZMK_SHIELDS=("${FILTERED_ZMK_SHIELDS[@]}")
      ZMK_EXTRA_SHIELDS=("${FILTERED_ZMK_EXTRA_SHIELDS[@]}")
      ZMK_CMAKE_ARGS=("${FILTERED_ZMK_CMAKE_ARGS[@]}")
      ZMK_ARTIFACTS=("${FILTERED_ZMK_ARTIFACTS[@]}")
    fi
  fi
}

# This function is similar to the `filter_build_configs` function, except it
# uses `fzf` with multi-selection to allow the user to choose which shields to
# build interactively.
#
# After filtering all the configurations parsed by the
# `extract_all_build_config` function, it will store the remainning values on
# the following variables:
#
# - ZMK_LABELS
# - ZMK_BOARDS
# - ZMK_SHIELDS
# - ZMK_EXTRA_SHIELDS
# - ZMK_CMAKE_ARGS
# - ZMK_ARTIFACTS
#
# @param $1 {"left"|"right"|"both"|""} A part target string that will
#        pre-filter shields for the given part. If this parameter is empty or
#        the string "both", there will be no filtering based on which side of
#        the keyboard to build.
filter_build_configs_interactively() {
  [[ "$#" -gt 0 ]] || fail "Missing build part target on filter config function"
  local KB_PART_TARGET="$1"
  shift

  readarray CHOICES < <(
    for idx in "${!ZMK_ALL_LABELS[@]}"; do
      case "${ZMK_ALL_SHIELDS[$idx]}" in
        *_left)
          [[ "$KB_PART_TARGET" != "right" ]] && printf "%d\t%s\n" "$idx" "${ZMK_ALL_LABELS[$idx]}"
          ;;
        *_right)
          [[ "$KB_PART_TARGET" != "left" ]] && printf "%d\t%s\n" "$idx" "${ZMK_ALL_LABELS[$idx]}"
          ;;
        settings_reset)
          [[ -z "$KB_PART_TARGET" ]] && printf "%d\t%s\n" "$idx" "${ZMK_ALL_LABELS[$idx]}"
          ;;
        *)
          printf "%d\t%s\n" "$idx" "${ZMK_ALL_LABELS[$idx]}"
          ;;
      esac
    done | fzf -m --ansi -d "\t" --with-nth 2..
  )
  if [[ "${#CHOICES[@]}" -eq 0 ]]; then
    fail "User canceled"
  fi
  for OPT in "${CHOICES[@]}"; do
    read -r -a RECORD <<< "${OPT}"
    idx="${RECORD[0]}"
    ZMK_BOARDS+=("${ZMK_ALL_BOARDS[$idx]}")
    ZMK_SHIELDS+=("${ZMK_ALL_SHIELDS[$idx]}")
    ZMK_EXTRA_SHIELDS+=("${ZMK_ALL_EXTRA_SHIELDS[$idx]}")
    ZMK_CMAKE_ARGS+=("${ZMK_ALL_CMAKE_ARGS[$idx]}")
    ZMK_ARTIFACTS+=("${ZMK_ALL_ARTIFACTS[$idx]}")
  done
}

declare -a ZMK_ALL_LABELS
declare -a ZMK_ALL_BOARDS
declare -a ZMK_ALL_SHIELDS
declare -a ZMK_ALL_EXTRA_SHIELDS
declare -a ZMK_ALL_CMAKE_ARGS
declare -a ZMK_ALL_ARTIFACTS
declare -a ZMK_BOARDS
declare -a ZMK_SHIELDS
declare -a ZMK_EXTRA_SHIELDS
declare -a ZMK_CMAKE_ARGS
declare -a ZMK_ARTIFACTS

export OUT_LEVEL="normal"
export ZMK_ALL_LABELS=()
export ZMK_ALL_BOARDS=()
export ZMK_ALL_SHIELDS=()
export ZMK_ALL_EXTRA_SHIELDS=()
export ZMK_ALL_CMAKE_ARGS=()
export ZMK_ALL_ARTIFACTS=()
export ZMK_BOARDS=()
export ZMK_SHIELDS=()
export ZMK_EXTRA_SHIELDS=()
export ZMK_CMAKE_ARGS=()
export ZMK_ARTIFACTS=()
