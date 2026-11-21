0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

# _zalias_flags: per alias name ("g:name" for global aliases), a bit set of
# 1 = expand on Space and 2 = no trailing space after the expansion.
typeset -gA _zalias_flags _zalias_descriptions _zalias_tipped \
  _zalias_prev_space _zalias_split_cache _zalias_function_descs _zalias_dir_defs _zalias_dir_state \
  _zalias_defined _zalias_pending_use
typeset -g _zalias_split_sig=''

# Field names of the records kept in _zalias_dir_defs (one per directory alias)
# and _zalias_dir_state (one per applied alias). See _zalias_record_pack.
typeset -ga _zalias_dir_fields=(value expand no_space description)
typeset -ga _zalias_dir_state_fields=(scope value expand no_space description
  saved_kind saved_value saved_flags saved_has_description saved_description)

((${fpath[(Ie)${0:h}/functions]})) || fpath=("${0:h}/functions" $fpath)
((${fpath[(Ie)${0:h}]})) || fpath+=("${0:h}")
autoload -Uz zalias zalias-expand-space _zalias_cheatsheet _zalias_read_desc_line \
  _zalias_collect_function_descriptions _zalias_preexec_hook _zalias_split_definition \
  _zalias_async _zalias_sql_quote _zalias_db_path _zalias_db _zalias_match_definition \
  _zalias_dir_apply _zalias_dir_load _zalias_dir_init _zalias_dir_define _zalias_dir_remove _zalias_dir_list \
  _zalias_dir_describe _zalias_record_pack _zalias_record_unpack _zalias_dir_key _zalias_dir_key_split _zalias_dir_scope _zalias_usage _zalias_search_hit _zalias_record_hook _zalias_stats _zalias_search _zalias_tag_list _zalias_remove

autoload -Uz add-zsh-hook

if zstyle -T ':zalias:' reminder; then
  add-zsh-hook preexec _zalias_preexec_hook
fi

# The hooks do nothing without sqlite3, so they are always registered; PATH may
# gain sqlite3 later in the rc file.
zmodload -F zsh/datetime p:EPOCHSECONDS 2> /dev/null
# Directory aliases load on the first prompt, after the rc file has defined its own aliases.
add-zsh-hook precmd _zalias_dir_init
add-zsh-hook chpwd _zalias_dir_apply
add-zsh-hook preexec _zalias_record_hook

zle -N zalias-expand-space
if zstyle -T ':zalias:' bind-space; then
  for _zalias_keymap in emacs viins; do
    _zalias_widget="${${(z)"$(bindkey -M "${_zalias_keymap}" ' ' 2>/dev/null)"}[-1]}"
    case "${_zalias_widget}" in
      '' | undefined-key | zalias-expand-space) ;;
      *) _zalias_prev_space[${_zalias_keymap}]="${_zalias_widget}" ;;
    esac
    bindkey -M "${_zalias_keymap}" ' ' zalias-expand-space
  done
  unset _zalias_keymap _zalias_widget
fi

if ((${+functions[compdef]})); then
  autoload -Uz _zalias
  compdef _zalias zalias
fi
