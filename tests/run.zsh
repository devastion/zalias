#!/usr/bin/env zsh
emulate -L zsh
local root=${0:A:h:h} fails=0
fpath=($root/functions $fpath)
source $root/zalias.plugin.zsh

check() {
  if [[ "$2" == "$3" ]]; then print "ok   $1"; else print "FAIL $1: expected [$2] got [$3]"; ((fails++)); fi
}

zalias -d 'Git status' -e gs='git status'
check description "Git status" "$(zalias gs)"
check expand-flag 1 "${+_zalias_expand_on_space[gs]}"
zalias gs='git status'
check redefine-clears-flag 0 "${+_zalias_expand_on_space[gs]}"
check redefine-clears-desc 0 "${+_zalias_descriptions[gs]}"
zalias -b -e G='| grep'
check no-space-flag 1 "${+_zalias_no_trailing_space[G]}"
zalias -d x 2>/dev/null; check usage-error 2 $?

_zalias_split_definition "ls -l 'a b'"; check split "ls|-l|a b" "${(j:|:)reply}"
_zalias_split_definition 'echo $(date)'; check split-rejects-subshell 1 $?
FOO=bar _zalias_split_definition 'echo ${FOO}'; check split-var "echo|bar" "${(j:|:)reply}"

alias gco='git checkout' g='git' mv='mv -iv'
_zalias_tipped=()
check tip-prefers-longest "Tip: gco = git checkout" "$(_zalias_preexec_hook 'git checkout main' 2>&1)"
check no-tip-wrapper "" "$(_zalias_preexec_hook 'mv -iv a b' 2>&1)"
_zalias_preexec_hook 'git checkout main' 2>/dev/null
check tip-once "" "$(_zalias_preexec_hook 'git checkout main' 2>&1)"
check no-tip-nomatch "" "$(_zalias_preexec_hook 'ls' 2>&1)"

zalias -d x gs='git status'
check cheatsheet-plain "gs: x" "$(zalias | grep '^gs:')"

((fails == 0)) || { print "$fails failed"; exit 1; }
print "all passed"
