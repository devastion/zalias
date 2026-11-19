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
