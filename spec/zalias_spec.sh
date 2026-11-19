# shellcheck shell=sh disable=SC2296

Describe 'zalias'
  BeforeEach 'load_plugin'

  It 'stores and prints a description'
    zalias -d 'Git status' -e gs='git status'
    When call zalias gs
    The output should eq 'Git status'
  End

  It 'sets the expand flag with -e'
    zalias -e gs='git status'
    The value "${+_zalias_expand_on_space[gs]}" should eq 1
  End

  It 'clears flags and description on redefine'
    zalias -d 'Git status' -e gs='git status'
    zalias gs='git status'
    The value "${+_zalias_expand_on_space[gs]}" should eq 0
    The value "${+_zalias_descriptions[gs]}" should eq 0
  End

  It 'sets the no-trailing-space flag with -b'
    zalias -b -e G='| grep'
    The value "${+_zalias_no_trailing_space[G]}" should eq 1
  End

  It 'fails with usage error on a description without a definition'
    When call zalias -d x
    The status should eq 2
    The stderr should be present
  End

  It 'tracks global and regular aliases of the same name separately'
    zalias -d 'Regular' G='git'
    zalias -g -e -d 'Global' G='| grep'
    The value "${+_zalias_descriptions[G]}" should eq 1
    The value "${+_zalias_descriptions[g:G]}" should eq 1
    The value "${+_zalias_expand_on_space[G]}" should eq 0
    The value "${+_zalias_expand_on_space[g:G]}" should eq 1
  End

  It 'prints the description of a global alias'
    zalias -g -d 'Pipe to grep' G='| grep'
    When call zalias G
    The output should eq 'Pipe to grep'
  End

  It 'defines several aliases in one call'
    zalias -d 'Quit' q='exit' quit='exit'
    The value "${_zalias_descriptions[q]}|${_zalias_descriptions[quit]}" should eq 'Quit|Quit'
  End

  It 'rejects unknown options'
    When call zalias -x a=b
    The status should eq 2
    The stderr should be present
  End

  It 'names the missing = when options come without a definition'
    When call zalias -e gs
    The status should eq 2
    The stderr should include 'expected name=value'
  End

  It 'lists descriptions in the cheatsheet'
    zalias -d x gs='git status'
    When call zalias
    The output should include 'gs: x'
  End
End

Describe '_zalias_split_definition'
  BeforeEach 'load_plugin'

  It 'splits words and honours quotes'
    When call _zalias_split_definition "ls -l 'a b'"
    The value "${(j:|:)reply}" should eq 'ls|-l|a b'
  End

  It 'rejects command substitution'
    When call _zalias_split_definition 'echo $(date)'
    The status should eq 1
  End

  It 'expands variables'
    FOO=bar
    When call _zalias_split_definition 'echo ${FOO}'
    The value "${(j:|:)reply}" should eq 'echo|bar'
  End
End

Describe '_zalias_preexec_hook'
  BeforeEach 'load_plugin'
  setup() {
    alias gco='git checkout' g='git' mv='mv -iv'
    _zalias_tipped=()
  }
  BeforeEach 'setup'

  It 'prefers the longest matching alias'
    When call _zalias_preexec_hook 'git checkout main'
    The stderr should eq 'Tip: gco = git checkout'
  End

  It 'does not tip for wrapper aliases'
    When call _zalias_preexec_hook 'mv -iv a b'
    The stderr should eq ''
  End

  It 'tips only once per alias'
    _zalias_preexec_hook 'git checkout main' 2>/dev/null
    When call _zalias_preexec_hook 'git checkout main'
    The stderr should eq ''
  End

  It 'does not tip without a match'
    When call _zalias_preexec_hook 'ls'
    The stderr should eq ''
  End
End

Describe '_zalias_collect_function_descriptions'
  BeforeEach 'load_plugin'

  It 'reads "# desc:" lines into the named array'
    dir="$(mktemp -d)"
    printf '#!/usr/bin/env zsh\n# desc: Say hi\n' > "${dir}/hi"
    printf '#!/usr/bin/env zsh\n# no description\n' > "${dir}/plain"
    printf '#!/usr/bin/env zsh\n# desc: private\n' > "${dir}/_private"
    zstyle ':zalias:' function-dirs "${dir}"
    _zalias_collect_function_descriptions
    rm -rf "${dir}"
    zstyle -d ':zalias:' function-dirs
    The value "${(kvj:,:)_zalias_function_descs}" should eq 'hi,Say hi'
  End
End

Describe '_zalias_cheatsheet'
  BeforeEach 'load_plugin'

  It 'prints aliases and functions as plain lines when piped'
    zalias -d 'Git status' gs='git status'
    zalias -g -d 'Pipe to grep' G='| grep'
    _zalias_function_descs=(hi 'Say hi')
    When call _zalias_cheatsheet
    The line 1 of output should eq 'G: Pipe to grep'
    The line 2 of output should eq 'gs: Git status'
    The line 3 of output should eq 'hi: Say hi'
  End
End

Describe '_zalias_preexec_hook cache'
  BeforeEach 'load_plugin'

  It 'notices aliases added after the first call'
    _zalias_tipped=()
    _zalias_preexec_hook 'git status' 2>/dev/null
    alias gs='git status'
    When call _zalias_preexec_hook 'git status'
    The stderr should eq 'Tip: gs = git status'
  End

  It 'sees variable changes in definitions that use ${VAR}'
    _zalias_tipped=()
    DIR=one
    alias --  'lv=ls ${DIR}'
    _zalias_preexec_hook 'ls one' 2>/dev/null
    DIR=two
    _zalias_tipped=()
    When call _zalias_preexec_hook 'ls two'
    The stderr should eq 'Tip: lv = ls ${DIR}'
  End

  It 'only rewrites a leading ~ that is a whole word or ~/'
    _zalias_tipped=()
    alias lh="ls ${HOME}/x"
    When call _zalias_preexec_hook 'ls ~/x'
    The stderr should eq "Tip: lh = ls ${HOME}/x"
  End
End

Describe 'zalias-expand-space'
  BeforeEach 'load_plugin'

  It 'remembers the previous Space binding when loaded'
    The value "${(t)_zalias_prev_space}" should include 'association'
  End
End
