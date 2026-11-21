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
    The value "$(flag_bit gs 1)" should eq 1
  End

  It 'clears flags and description on redefine'
    zalias -d 'Git status' -e gs='git status'
    zalias gs='git status'
    The value "$(flag_bit gs 1)" should eq 0
    The value "${+_zalias_descriptions[gs]}" should eq 0
  End

  It 'sets the no-trailing-space flag with -b'
    zalias -b -e G='| grep'
    The value "$(flag_bit 'G' 2)" should eq 1
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
    The value "$(flag_bit 'G' 1)" should eq 0
    The value "$(flag_bit 'g:G' 1)" should eq 1
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

Describe '_zalias_async'
  BeforeEach 'load_plugin'

  It 'runs the command in the background without waiting'
    marker="$(mktemp -u)"
    slow() { sleep 0.3; : > "${marker}"; }
    start=$EPOCHREALTIME
    _zalias_async slow
    elapsed=$(((EPOCHREALTIME - start) * 1000))
    The value "$((elapsed < 200))" should eq 1
    sleep 0.6
    The path "${marker}" should be exist
    rm -f "${marker}"
  End
End

Describe '_zalias_sql_quote'
  BeforeEach 'load_plugin'

  It 'doubles single quotes'
    _zalias_sql_quote "a'b"
    The value "${REPLY}" should eq "'a''b'"
  End
End

Describe '_zalias_db'
  BeforeEach 'load_plugin'
  BeforeEach 'use_temp_db'
  AfterEach 'drop_temp_db'
  Skip if 'sqlite3 is missing' test -z "$(command -v sqlite3)"

  It 'creates the schema at version 2'
    _zalias_db ''
    The value "$(db_query 'PRAGMA user_version;')" should eq 2
    The value "$(db_query '.tables' | tr -s ' \n' ' ')" should include 'dir_alias'
  End

  It 'migrates a database at version 0'
    mkdir -p "${TEST_DB_DIR}"
    db_query 'CREATE TABLE unrelated(x);'
    _zalias_db ''
    The value "$(db_query 'PRAGMA user_version;')" should eq 2
  End

  It 'drops a version 1 database and starts fresh'
    mkdir -p "${TEST_DB_DIR}"
    db_query 'CREATE TABLE dir_alias(x); CREATE TABLE alias_usage(name); INSERT INTO alias_usage VALUES(1); PRAGMA user_version=1;'
    _zalias_db ''
    The value "$(db_query 'PRAGMA user_version;')" should eq 2
    The value "$(db_query 'SELECT count(*) FROM alias;')" should eq 0
    The value "$(db_query '.tables' | tr -s ' \n' ' ')" should not include 'alias_usage'
  End

  It 'stores directory alias flags in one column and keeps created_at on redefine'
    zalias -D --dir="${TEST_DB_DIR}" -e -b pp='echo one'
    first="$(db_query "SELECT flags || ',' || created_at FROM dir_alias;")"
    sleep 1
    zalias -D --dir="${TEST_DB_DIR}" -e -b pp='echo two'
    The value "${first%%,*}" should eq 3
    The value "$(db_query "SELECT flags || ',' || created_at FROM dir_alias;")" should eq "${first}"
    The value "$(db_query "SELECT value FROM dir_alias;")" should eq 'echo two'
  End

  It 'removes tags with their alias'
    zalias -t x gs='git status'
    zalias -r gs
    The value "$(db_query 'SELECT count(*) FROM alias_tag;')" should eq 0
  End

  It 'refuses a database from a newer plugin and leaves it unchanged'
    db_query 'PRAGMA user_version=99;'
    before="$(cksum < "${TEST_DB_DIR}/z.db")"
    When call zalias --stats
    The status should eq 1
    The stderr should include 'newer than this plugin'
    The value "$(cksum < "${TEST_DB_DIR}/z.db")" should eq "${before}"
  End

  It 'reports a missing sqlite3'
    old_path="${PATH}"
    PATH=/nonexistent
    rehash
    When call _zalias_db 'SELECT 1;'
    The status should eq 1
    The stderr should eq 'zalias: sqlite3 not found'
    PATH="${old_path}"
    rehash
  End
End

Describe '_zalias_match_definition'
  BeforeEach 'load_plugin'

  It 'sets REPLY to the longest matching alias'
    alias gco='git checkout' g='git'
    _zalias_match_definition 'git checkout main'
    The value "${REPLY}" should eq gco
  End
End

Describe '_zalias_record_hook'
  BeforeEach 'load_plugin'
  BeforeEach 'use_temp_db'
  AfterEach 'drop_temp_db'
  Skip if 'sqlite3 is missing' test -z "$(command -v sqlite3)"

  It 'counts alias uses'
    alias gs='git status'
    _zalias_record_hook 'gs -sb'
    _zalias_record_hook 'gs'
    The value "$(db_query "SELECT uses FROM alias WHERE name='gs';")" should eq 2
  End

  It 'prepares the database in the calling shell, not in the background job'
    unset _zalias_db_ready
    _zalias_record_hook 'ls'
    The value "${_zalias_db_ready-}" should end with "/z.db"
  End

  It 'counts a missed use when the definition was typed'
    alias gco='git checkout'
    _zalias_record_hook 'git checkout main'
    The value "$(db_query "SELECT missed FROM alias WHERE name='gco';")" should eq 1
  End

  It 'keys git commands by subcommand and skips variable assignments'
    _zalias_record_hook 'FOO=secret git status -sb'
    _zalias_record_hook 'ls -la'
    The value "$(db_query 'SELECT key FROM command_usage ORDER BY key;' | tr '\n' ,)" should eq 'git status,ls,'
  End

  It 'stores no command arguments'
    _zalias_record_hook 'curl -H token=abc https://x'
    The value "$(db_query 'SELECT key FROM command_usage;')" should eq curl
  End

  It 'counts a Space-expanded line as a use, not a missed use'
    alias gs='git status'
    _zalias_pending_use=(gs 1)
    _zalias_record_hook 'git status -sb'
    The value "$(db_query "SELECT uses || ',' || missed FROM alias WHERE name='gs';")" should eq '1,0'
    The value "${#_zalias_pending_use}" should eq 0
  End

  It 'keys sudo and path commands by the real command and basename'
    _zalias_record_hook 'sudo git status'
    _zalias_record_hook '/Users/me/clients/acme/deploy.sh now'
    The value "$(db_query 'SELECT key FROM command_usage ORDER BY key;' | tr '\n' ,)" should eq 'deploy.sh,git status,'
  End

  It 'does not count a quoted or escaped alias word as a use'
    alias gs='git status'
    _zalias_record_hook '\gs'
    The value "$(db_query "SELECT count(*) FROM alias WHERE name='gs';")" should eq 0
  End

  It 'skips keys with unsafe characters'
    _zalias_record_hook 'foo.bar=secret x'
    The path "${TEST_DB_DIR}/z.db" should not be exist
  End

  It 'records in the background without a sync flag'
    unset _zalias_sync
    alias gs='git status'
    _zalias_record_hook 'gs'
    for _ in {1..40}; do
      [[ "$(db_query "SELECT uses FROM alias WHERE name='gs';" 2> /dev/null)" == 1 ]] && break
      sleep 0.1
    done
    The value "$(db_query "SELECT uses FROM alias WHERE name='gs';")" should eq 1
  End

  It 'ignores empty, multi-line and space-prefixed commands'
    _zalias_record_hook ''
    _zalias_record_hook $'ls\nls'
    _zalias_record_hook ' ls'
    The path "${TEST_DB_DIR}/z.db" should not be exist
  End

  It 'writes nothing when stats are off'
    zstyle ':zalias:' stats no
    _zalias_record_hook 'ls'
    zstyle -d ':zalias:' stats
    The path "${TEST_DB_DIR}/z.db" should not be exist
  End
End

Describe 'zalias --stats'
  BeforeEach 'load_plugin'
  BeforeEach 'use_temp_db'
  AfterEach 'drop_temp_db'
  Skip if 'sqlite3 is missing' test -z "$(command -v sqlite3)"

  It 'lists unused and top aliases and uncovered commands'
    zalias -d x gs='git status' ll='ls -l' unused='true'
    _zalias_record_hook 'gs'
    _zalias_record_hook 'll'
    _zalias_record_hook 'll'
    _zalias_record_hook 'git status'
    _zalias_record_hook 'make build'
    _zalias_record_hook 'make build'
    _zalias_record_hook 'cat file'
    When call zalias --stats
    The line 1 of output should eq 'Never used'
    The line 2 of output should eq '  unused'
    The line 3 of output should eq 'Most used'
    The line 4 of output should eq '  2  ll'
    The line 5 of output should eq '  1  gs  (missed 1)'
    The line 6 of output should eq 'Typed without an alias'
    The line 7 of output should eq '  2  make'
    The line 8 of output should eq '  1  cat'
  End
End

Describe 'directory aliases'
  BeforeEach 'load_plugin'
  BeforeEach 'use_temp_db'
  AfterEach 'drop_temp_db'
  Skip if 'sqlite3 is missing' test -z "$(command -v sqlite3)"

  setup_dirs() {
    ROOT="$(mktemp -d)"
    ROOT="${ROOT:A}"
    mkdir -p "${ROOT}/proj/sub" "${ROOT}/proj/sub/deep" "${ROOT}/other"
    ORIG_PWD="${PWD}"
    cd "${ROOT}/other" || return 1
  }
  teardown_dirs() {
    cd "${ORIG_PWD}" || return 1
    rm -rf "${ROOT}"
  }
  BeforeEach 'setup_dirs'
  AfterEach 'teardown_dirs'

  It 'defines the alias inside the scope and removes it outside'
    zalias -D --dir="${ROOT}/proj" -d 'Proj' pp='echo proj'
    The value "${+aliases[pp]}" should eq 0
    cd "${ROOT}/proj/sub" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'echo proj'
    The value "${_zalias_descriptions[pp]}" should eq 'Proj'
    cd "${ROOT}/other" && _zalias_dir_apply
    The value "${+aliases[pp]}" should eq 0
    The value "${+_zalias_descriptions[pp]}" should eq 0
  End

  It 'lets the deepest scope win'
    zalias -D --dir="${ROOT}/proj" pp='echo outer'
    zalias -D --dir="${ROOT}/proj/sub" pp='echo inner'
    cd "${ROOT}/proj/sub/deep" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'echo inner'
    cd "${ROOT}/proj" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'echo outer'
  End

  It 'restores a shadowed global alias with its flags'
    zalias -e -d 'Global gs' gs='git status'
    zalias -D --dir="${ROOT}/proj" gs='echo shadow'
    cd "${ROOT}/proj" && _zalias_dir_apply
    The value "${aliases[gs]}" should eq 'echo shadow'
    The value "$(flag_bit gs 1)" should eq 0
    cd "${ROOT}/other" && _zalias_dir_apply
    The value "${aliases[gs]}" should eq 'git status'
    The value "$(flag_bit gs 1)" should eq 1
    The value "${_zalias_descriptions[gs]}" should eq 'Global gs'
  End

  It 'does not restore an alias that was changed by hand'
    zalias -D --dir="${ROOT}/proj" pp='echo proj'
    cd "${ROOT}/proj" && _zalias_dir_apply
    alias pp='mine'
    cd "${ROOT}/other" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'mine'
  End

  It 'defaults to the current directory'
    cd "${ROOT}/proj"
    zalias -D pp='echo here'
    The value "$(db_query 'SELECT dir FROM dir_alias;')" should eq "${ROOT}/proj"
  End

  It 'loads stored aliases from the database'
    zalias -D --dir="${ROOT}/proj" -d 'Proj' pp='echo proj'
    _zalias_dir_defs=()
    _zalias_dir_load
    cd "${ROOT}/proj" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'echo proj'
  End

  It 'lists scoped aliases'
    zalias -D --dir="${ROOT}/proj" -d 'Proj' pp='echo proj'
    When call zalias -D --list
    The output should eq "${ROOT}/proj: pp=echo proj  # Proj"
  End

  It 'removes a scoped alias'
    zalias -D --dir="${ROOT}/proj" pp='echo proj'
    zalias -D --dir="${ROOT}/proj" -r pp
    The value "$(db_query 'SELECT count(*) FROM dir_alias;')" should eq 0
    The value "${#_zalias_dir_defs}" should eq 0
  End

  It 'rejects -D with -g'
    When call zalias -D -g G='| grep'
    The status should eq 2
    The stderr should include 'Usage'
  End

  It 'keeps values with quotes intact'
    zalias -D --dir="${ROOT}/proj" -d "it's" pp="echo 'a b'"
    The value "$(db_query 'SELECT value FROM dir_alias;')" should eq "echo 'a b'"
  End

  It 'shows inactive directory aliases in the cheatsheet and lookup'
    zalias -D --dir="${ROOT}/proj" -d 'Proj alias' pp='echo proj'
    When call zalias pp
    The output should eq "Proj alias [dir: ${ROOT}/proj]"
  End

  It 'marks active directory aliases in the cheatsheet'
    zalias -D --dir="${ROOT}/proj" -d 'Proj alias' pp='echo proj'
    cd "${ROOT}/proj" && _zalias_dir_apply
    When call _zalias_cheatsheet
    The output should include "pp: Proj alias [dir: ${ROOT}/proj]"
  End
End

Describe 'tags, search and remove'
  BeforeEach 'load_plugin'
  BeforeEach 'use_temp_db'
  AfterEach 'drop_temp_db'
  Skip if 'sqlite3 is missing' test -z "$(command -v sqlite3)"

  It 'lists aliases by tag'
    zalias -t git -t vcs -d 'Status' gs='git status'
    zalias -d 'Other' ll='ls -l'
    When call zalias --tag vcs
    The output should eq 'gs: Status'
  End

  It 'hides tagged aliases that are no longer defined'
    zalias -t git gs='git status'
    unalias gs
    When call zalias --tag git
    The status should eq 1
    The output should eq ''
  End

  It 'searches names, definitions and descriptions case-insensitively'
    zalias -d 'Show Status' gs='git status'
    zalias ll='ls -l'
    When call zalias -s STATUS
    The output should include 'gs: Show Status'
    The output should not include 'll'
  End

  It 'returns 1 when search finds nothing'
    When call zalias -s zzz-nothing-zzz
    The status should eq 1
    The output should eq ''
  End

  It 'removes an alias with its state, usage and tags'
    zalias -t git -e -d 'Status' gs='git status'
    _zalias_record_hook 'gs'
    zalias -r gs
    The value "${+aliases[gs]}" should eq 0
    The value "${+_zalias_descriptions[gs]}" should eq 0
    The value "$(flag_bit gs 1)" should eq 0
    The value "$(db_query 'SELECT count(*) FROM alias;')" should eq 0
    The value "$(db_query 'SELECT count(*) FROM alias_tag;')" should eq 0
  End

  It 'fails to remove an unknown alias'
    When call zalias -r nope-nope
    The status should eq 1
    The stderr should include 'no such alias'
  End
End

Describe 'plugin hooks'
  BeforeEach 'load_plugin'

  It 'registers the recording and directory hooks'
    The value "${preexec_functions[*]}" should include _zalias_record_hook
    The value "${chpwd_functions[*]}" should include _zalias_dir_apply
    The value "${precmd_functions[*]}" should include _zalias_dir_init
  End

  It 'unhooks _zalias_dir_init after its first run'
    precmd_functions+=(_zalias_dir_init)
    _zalias_dir_init
    The value "${precmd_functions[*]}" should not include _zalias_dir_init
  End
End

Describe 'without sqlite3'
  BeforeEach 'load_plugin'

  nosql() { PATH=/nonexistent; rehash; }
  restore() { PATH="${ORIG_PATH}"; rehash; }
  BeforeEach 'ORIG_PATH="${PATH}"'
  BeforeEach 'nosql'
  AfterEach 'restore'

  It 'still defines aliases and lists the cheatsheet'
    zalias -d 'Git status' gs='git status'
    When call zalias gs
    The output should eq 'Git status'
  End

  It 'fails --stats with the sqlite3 message'
    When call zalias --stats
    The status should eq 1
    The stderr should include 'sqlite3 not found'
  End

  It 'fails -D --list with the sqlite3 message'
    When call zalias -D --list
    The status should eq 1
    The stderr should include 'sqlite3 not found'
  End

  It 'records nothing and prints nothing'
    When call _zalias_record_hook 'ls'
    The status should eq 0
    The stderr should eq ''
    The output should eq ''
  End
End

Describe 'review fixes'
  BeforeEach 'load_plugin'
  BeforeEach 'use_temp_db'
  AfterEach 'drop_temp_db'
  Skip if 'sqlite3 is missing' test -z "$(command -v sqlite3)"

  setup_dirs() {
    ROOT="$(mktemp -d)"
    ROOT="${ROOT:A}"
    mkdir -p "${ROOT}/proj" "${ROOT}/other"
    ORIG_PWD="${PWD}"
    cd "${ROOT}/other" || return 1
  }
  teardown_dirs() {
    cd "${ORIG_PWD}" || return 1
    rm -rf "${ROOT}"
  }
  BeforeEach 'setup_dirs'
  AfterEach 'teardown_dirs'

  It 'expands ~ in --dir'
    HOME="${ROOT}" zalias -D --dir='~/proj' pp='echo p'
    The value "$(db_query 'SELECT dir FROM dir_alias;')" should eq "${ROOT}/proj"
  End

  It 'rejects a --dir that is not a directory'
    When call zalias -D --dir="${ROOT}/missing" pp='echo p'
    The status should eq 1
    The stderr should include 'not a directory'
  End

  It 'rejects -D with -t, and query modes with extra arguments'
    When call zalias -D -t x pp='echo p'
    The status should eq 2
    The stderr should include 'Usage'
  End

  It 'rejects -s with a definition'
    When call zalias -s foo a=b
    The status should eq 2
    The stderr should include 'Usage'
  End

  It 'creates the database and its folder private'
    zalias -t x gs='git status'
    The value "$(stat -c %a "${TEST_DB_DIR}/z.db" 2> /dev/null || stat -f %Lp "${TEST_DB_DIR}/z.db")" should eq 600
  End

  It 'recreates the schema when the database file is deleted'
    _zalias_db ''
    rm -f "${TEST_DB_DIR}"/z.db*
    zalias -t x gs='git status'
    The value "$(db_query 'SELECT count(*) FROM alias_tag;')" should eq 1
  End

  It 'strips row and field separators from stored values'
    zalias -D --dir="${ROOT}/proj" -d $'a\x1fb' pp='echo p'
    _zalias_dir_defs=()
    _zalias_dir_load
    cd "${ROOT}/proj" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'echo p'
    The value "${_zalias_descriptions[pp]}" should eq 'ab'
  End

  It 'reloads rows with an empty description'
    zalias -D --dir="${ROOT}/proj" -e pp='echo p'
    _zalias_dir_defs=()
    _zalias_dir_load
    cd "${ROOT}/proj" && _zalias_dir_apply
    The value "${aliases[pp]}" should eq 'echo p'
    The value "$(flag_bit pp 1)" should eq 1
    The value "${+_zalias_descriptions[pp]}" should eq 0
  End

  It 'keeps a global alias when a directory alias has the same name'
    zalias -g G='| grep'
    zalias -D --dir="${ROOT}/proj" G='echo dir'
    cd "${ROOT}/proj" && _zalias_dir_apply
    The value "${galiases[G]}" should eq '| grep'
  End

  It 'drops directory flags and description from a hand-changed alias'
    zalias -D --dir="${ROOT}/proj" -e -d 'Dir' pp='echo p'
    cd "${ROOT}/proj" && _zalias_dir_apply
    alias pp='mine'
    cd "${ROOT}/other" && _zalias_dir_apply
    The value "$(flag_bit pp 1)" should eq 0
    The value "${+_zalias_descriptions[pp]}" should eq 0
  End

  It 'removes a directory alias that another shell stored'
    zalias -D --dir="${ROOT}/proj" pp='echo p'
    _zalias_dir_defs=()
    When call zalias -D --dir="${ROOT}/proj" -r pp
    The status should eq 0
    The value "$(db_query 'SELECT count(*) FROM dir_alias;')" should eq 0
  End

  It 'removes nothing when one of several names is unknown'
    zalias -t x gs='git status'
    When call zalias -r gs nope-nope
    The status should eq 1
    The stderr should include 'no such alias'
    The value "${+aliases[gs]}" should eq 1
  End

  It 'does not list global aliases as never used'
    zalias -g G='| grep'
    zalias unused='true'
    When call zalias --stats
    The output should include 'unused'
    The output should not include '  G'
  End
End

Describe 'record helpers'
  BeforeEach 'load_plugin'

  It 'round-trips a record through pack and unpack'
    roundtrip() {
      # shellcheck disable=SC2034 # read by name through ${(P)1}
      local -a fields=(a b c)
      local -A rec
      local REPLY
      _zalias_record_pack fields one '' 'three words'
      _zalias_record_unpack fields "${REPLY}"
      print -r -- "[${rec[a]}][${rec[b]}][${rec[c]}]"
    }
    When call roundtrip
    The output should eq '[one][][three words]'
  End

  It 'refuses a record with the wrong number of fields'
    wrong() { local REPLY; _zalias_record_pack _zalias_dir_fields only; }
    When call wrong
    The status should be failure
  End

  It 'splits a directory key'
    split() {
      local REPLY
      _zalias_dir_key /tmp/dir name
      _zalias_dir_key_split "${REPLY}"
      print -r -- "${reply[1]}|${reply[2]}"
    }
    When call split
    The output should eq '/tmp/dir|name'
  End
End
