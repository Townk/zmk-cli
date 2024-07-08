#!/usr/bin/env bash

fail() {
  [[ "$OUT_LEVEL" != "none" ]] && printf "ERROR: %s\n\n" "$*" | fmt -w 80 >&2
  exit 1
}

usage_fail() {
  [[ "$OUT_LEVEL" != "none" ]] && printf "ERROR: %s\n\n" "$*" | fmt -w 80 >&2
  usage
  exit 2
}

find_west_root() {
  if [[ -f "$1/config/west.yml" ]]; then
    printf "%s" "$1"
  elif [[ -n "$1" ]]; then
    find_west_root "${1%/*}"
  fi
}

require_west_project() {
  local root_dir
  root_dir="$(find_west_root "$PWD")"
  [[ -n $root_dir ]] \
    || usage_fail "You must run the 'zmk' command from a ZMK user configuration project"
  printf "%s" "$root_dir"
}

artifact_name() {
  print "%s" "zmk-$(printf "%s" "$1" | tr '_' '-')"
}

config_file() {
  local KEYMAP="${1}.$2"
  if [[ -f "$WEST_ROOT/config/$KEYMAP" ]]; then
    printf "%s" "$KEYMAP"
  else
    KEYMAP="${1%_left}.$2"
    if [[ -f "$WEST_ROOT/config/$KEYMAP" ]]; then
      printf "%s" "$KEYMAP"
    else
      KEYMAP="${1%_right}.$2"
      if [[ -f "$WEST_ROOT/config/$KEYMAP" ]]; then
        printf "%s" "$KEYMAP"
      fi
    fi
  fi
}

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
