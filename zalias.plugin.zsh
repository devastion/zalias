0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

typeset -gA _zalias_expand_on_space _zalias_no_trailing_space _zalias_descriptions _zalias_tipped

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
  bindkey -M emacs ' ' zalias-expand-space
  bindkey -M viins ' ' zalias-expand-space
fi

if ((${+functions[compdef]})); then
  autoload -Uz _zalias
  compdef _zalias zalias
fi
