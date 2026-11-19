0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

typeset -gA _zalias_expand_on_space _zalias_no_trailing_space _zalias_descriptions _zalias_tipped \
  _zalias_prev_space _zalias_split_cache _zalias_function_descs
typeset -g _zalias_split_sig=''

((${fpath[(Ie)${0:h}/functions]})) || fpath=("${0:h}/functions" $fpath)
((${fpath[(Ie)${0:h}]})) || fpath+=("${0:h}")
autoload -Uz zalias zalias-expand-space _zalias_cheatsheet _zalias_read_desc_line \
  _zalias_collect_function_descriptions _zalias_preexec_hook _zalias_split_definition

if zstyle -T ':zalias:' reminder; then
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _zalias_preexec_hook
fi

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
