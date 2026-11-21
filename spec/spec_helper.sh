# shellcheck shell=sh
# Loaded by ShellSpec (running under zsh). Plugin code is zsh-only, so it is
# sourced from inside a function that switches to zsh emulation.

load_plugin() {
  emulate -L zsh
  fpath=("${SHELLSPEC_PROJECT_ROOT}/functions" $fpath)
  source "${SHELLSPEC_PROJECT_ROOT}/zalias.plugin.zsh"
}

spec_helper_precheck() {
  load_plugin
}

# Points the plugin at a fresh database and runs recording in the foreground.
use_temp_db() {
  TEST_DB_DIR="$(mktemp -d)"
  zstyle ':zalias:' db "${TEST_DB_DIR}/z.db"
  zstyle -d ':zalias:' stats
  unset _zalias_db_ready
  _zalias_sync=1
  _zalias_dir_defs=() _zalias_dir_state=() _zalias_defined=()
}

drop_temp_db() {
  rm -rf "${TEST_DB_DIR}"
  zstyle -d ':zalias:' db
  unset _zalias_sync _zalias_db_ready
}

db_query() {
  command sqlite3 -batch -init /dev/null "${TEST_DB_DIR}/z.db" "$1"
}

# Print 1 when bit $2 (1 = expand on space, 2 = no trailing space) is set in
# the flags of alias $1, else 0.
flag_bit() {
  local -i flags="${_zalias_flags[${1}]:-0}"
  print -r -- $(((flags & ${2}) ? 1 : 0))
}
