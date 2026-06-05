#!/usr/bin/env bash
set -euo pipefail

# Agent-X Uninstaller — Ground Control Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/uninstall.sh | bash

INSTALL_DIR="${AGENTX_INSTALL_DIR:-$HOME/.agentx}"
BIN_DIR="${AGENTX_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/agentx"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agentx"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/agentx"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${CYAN}▸${NC} %s\n" "$1"; }
ok()    { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}⚠${NC} %s\n" "$1"; }

# ─── Removal Functions ─────────────────────────────────────────────

remove_installation() {
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed installation: $INSTALL_DIR"
  else
    info "No installation found at $INSTALL_DIR (skipped)"
  fi
}

remove_binary() {
  if [ -e "$BIN_DIR/agentx" ]; then
    rm -f "$BIN_DIR/agentx"
    ok "Removed binary: $BIN_DIR/agentx"
  else
    info "No binary found at $BIN_DIR/agentx (skipped)"
  fi
}

remove_global_package() {
  if command -v npm >/dev/null 2>&1; then
    npm uninstall -g @agentx/cli >/dev/null 2>&1 && ok "Removed global npm package" || true
  fi
  if command -v pnpm >/dev/null 2>&1; then
    pnpm remove -g @agentx/cli >/dev/null 2>&1 && ok "Removed global pnpm package" || true
  fi
}

remove_all_data() {
  local removed=false

  [ -d "$CONFIG_DIR" ] && rm -rf "$CONFIG_DIR" && ok "Removed config: $CONFIG_DIR" && removed=true
  [ -d "$DATA_DIR" ]   && rm -rf "$DATA_DIR"   && ok "Removed data: $DATA_DIR"   && removed=true
  [ -d "$CACHE_DIR" ]  && rm -rf "$CACHE_DIR"  && ok "Removed cache: $CACHE_DIR"  && removed=true

  if [ "$removed" = false ]; then
    info "No user data found (skipped)"
  fi
}

clean_path_entries() {
  local shell_files=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")

  for rc in "${shell_files[@]}"; do
    if [ -f "$rc" ] && grep -q "# Agent-X" "$rc" 2>/dev/null; then
      sed -i.bak '/# Agent-X/d' "$rc"
      sed -i.bak "\|${BIN_DIR}|d" "$rc"
      rm -f "${rc}.bak"
      ok "Removed PATH entry from $rc"
    fi
  done
}

# ─── Main ───────────────────────────────────────────────────────────

main() {
  printf "  ${BOLD}✧  DECOMMISSION SEQUENCE  ✧${NC}\n"
  printf "  ${DIM}Agent-X recall and scrub${NC}\n"
  printf "\n"

  MODE=""

  if [ -t 0 ]; then
    printf "  What would you like to do?\n"
    printf "\n"
    printf "    ${BOLD}1${NC}) Just uninstall Agent-X (keep config, data, credentials)\n"
    printf "    ${BOLD}2${NC}) Full wipe — remove everything including config, credentials, and user data\n"
    printf "\n"
    printf "  Enter choice [1/2]: "
    read -r choice
    case "$choice" in
      2|full|wipe) MODE="full" ;;
      *) MODE="package" ;;
    esac
    printf "\n"
  else
    # Non-interactive — check AGENTX_UNINSTALL_MODE env var
    MODE="${AGENTX_UNINSTALL_MODE:-package}"
  fi

  if [ "$MODE" = "full" ]; then
    info "Initiating full wipe sequence..."
  else
    info "Initiating package removal (keeping user data)..."
  fi
  printf "\n"

  remove_binary
  remove_installation
  remove_global_package
  clean_path_entries

  printf "\n"

  if [ "$MODE" = "full" ]; then
    info "Proceeding with data removal..."
    remove_all_data
  else
    info "Preserving user data at:"
    [ -d "$CONFIG_DIR" ] && printf "    • Config:  $CONFIG_DIR\n"
    [ -d "$DATA_DIR" ]   && printf "    • Data:    $DATA_DIR\n"
    [ -d "$CACHE_DIR" ]  && printf "    • Cache:   $CACHE_DIR\n"
    [ ! -d "$CONFIG_DIR" ] && [ ! -d "$DATA_DIR" ] && [ ! -d "$CACHE_DIR" ] && printf "    (none found)\n"
  fi

  printf "\n"
  printf "  ${BOLD}✧  DECOMMISSION COMPLETE  ✧${NC}\n"
  printf "  ${DIM}Open a new terminal for PATH changes to take effect.${NC}\n"
  printf "  ${DIM}Safe travels, commander.${NC}\n"
  printf "\n"
}

main "$@"
