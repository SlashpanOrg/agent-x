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

# ─── Satellite dish ASCII ───────────────────────────────────────────

satellite_banner() {
  printf "\n"
  printf "  ${DIM}               .${NC}\n"
  printf "  ${DIM}              / \\${NC}\n"
  printf "  ${DIM}             /   \\${NC}\n"
  printf "  ${DIM}            /     \\${NC}\n"
  printf "  ${DIM}           /_______\\${NC}\n"
  printf "  ${DIM}              | |${NC}\n"
  printf "  ${DIM}             /   \\${NC}\n"
  printf "  ${DIM}            /     \\${NC}\n"
  printf "  ${DIM}           /  ${RED}✕${NC}  \\${NC}\n"
  printf "  ${DIM}          ${RED}/_______\\${NC}\n"
  printf "  ${DIM}             |   |${NC}\n"
  printf "  ${DIM}             |   |${NC}\n"
  printf "  ${DIM}            /     \\${NC}\n"
  printf "  ${DIM}           /       \\${NC}\n"
  printf "  ${DIM}          /  ${DIM}~ ~ ~${NC}  \\${NC}\n"
  printf "  ${DIM}         /  ${DIM}~ ~ ~ ~${NC}  \\${NC}\n"
  printf "  ${DIM}        /  ${DIM}~ ~ ~ ~ ~${NC}  \\${NC}\n"
  printf "  ${DIM}       /                 \\${NC}\n"
  printf "  ${DIM}      /  ${RED}SIGNAL LOST${NC}    \\${NC}\n"
  printf "  ${DIM}     /___________________\\${NC}\n"
  printf "\n"
}

# ─── Removal ────────────────────────────────────────────────────────

remove_installation() {
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Decommissioned installation: $INSTALL_DIR"
  else
    info "No installation found at $INSTALL_DIR (skipped)"
  fi
}

remove_binary() {
  if [ -e "$BIN_DIR/agentx" ]; then
    rm -f "$BIN_DIR/agentx"
    ok "Removed navigation beacon: $BIN_DIR/agentx"
  else
    info "No binary found at $BIN_DIR/agentx (skipped)"
  fi
}

remove_global_package() {
  if command -v npm >/dev/null 2>&1; then
    npm uninstall -g @agentx/cli >/dev/null 2>&1 && ok "Scrubbed global npm package" || true
  fi
  if command -v pnpm >/dev/null 2>&1; then
    pnpm remove -g @agentx/cli >/dev/null 2>&1 && ok "Scrubbed global pnpm package" || true
  fi
}

remove_data() {
  local removed=false

  if [ -d "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
    ok "Wiped mission config: $CONFIG_DIR"
    removed=true
  fi

  if [ -d "$DATA_DIR" ]; then
    rm -rf "$DATA_DIR"
    ok "Wiped telemetry data: $DATA_DIR"
    removed=true
  fi

  if [ -d "$CACHE_DIR" ]; then
    rm -rf "$CACHE_DIR"
    ok "Wiped cached telemetry: $CACHE_DIR"
    removed=true
  fi

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
      ok "Removed navigation waypoint from $rc"
    fi
  done
}

# ─── Main ───────────────────────────────────────────────────────────

main() {
  satellite_banner

  printf "  ${RED}╔═══════════════════════════════════════════════╗${NC}\n"
  printf "  ${RED}║${NC}      ${BOLD}✧  DECOMMISSION SEQUENCE  ✧${NC}            ${RED}║${NC}\n"
  printf "  ${RED}║${NC}      ${DIM}Agent-X recall and scrub${NC}               ${RED}║${NC}\n"
  printf "  ${RED}╚═══════════════════════════════════════════════╝${NC}\n"
  printf "\n"

  info "Initiating decommission sequence..."
  printf "\n"

  remove_binary
  remove_installation
  remove_global_package
  printf "\n"

  if [ -d "$CONFIG_DIR" ] || [ -d "$DATA_DIR" ] || [ -d "$CACHE_DIR" ]; then
    printf "  ${YELLOW}Orbital debris detected:${NC}\n"
    [ -d "$CONFIG_DIR" ] && printf "    • Mission config:  $CONFIG_DIR\n"
    [ -d "$DATA_DIR" ]   && printf "    • Telemetry data:  $DATA_DIR\n"
    [ -d "$CACHE_DIR" ]  && printf "    • Cached telemetry: $CACHE_DIR\n"
    printf "\n"

    if [ -t 0 ]; then
      printf "  Scrub orbital debris (sessions, config, memories)? [y/N] "
      read -r answer
      if [[ "$answer" =~ ^[Yy] ]]; then
        remove_data
      else
        info "Orbital debris preserved"
      fi
    else
      warn "Running non-interactively — preserving orbital debris"
      info "To also scrub debris, run: rm -rf $CONFIG_DIR $DATA_DIR $CACHE_DIR"
    fi
  fi

  printf "\n"
  clean_path_entries

  printf "\n"
  printf "  ${YELLOW}╔═══════════════════════════════════════════════╗${NC}\n"
  printf "  ${YELLOW}║${NC}                                               ${YELLOW}║${NC}\n"
  printf "  ${YELLOW}║${NC}       ${BOLD}✧  DECOMMISSION COMPLETE  ✧${NC}           ${YELLOW}║${NC}\n"
  printf "  ${YELLOW}║${NC}       ${DIM}Agent-X has left the building.${NC}         ${YELLOW}║${NC}\n"
  printf "  ${YELLOW}║${NC}                                               ${YELLOW}║${NC}\n"
  printf "  ${YELLOW}╚═══════════════════════════════════════════════╝${NC}\n"
  printf "\n"
  printf "  ${DIM}Open a new terminal for PATH changes to take effect.${NC}\n"
  printf "  ${DIM}Safe travels, commander.${NC}\n"
  printf "\n"
}

main "$@"
