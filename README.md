# zalias

A zsh plugin for aliases with descriptions.

- `zalias -d 'description' name=value` defines an alias and remembers what it is for
- `zalias` prints a cheatsheet of described aliases and functions, in a tmux popup when possible
- `zalias -e` aliases expand in place when you press Space; add `-b` to drop the Space
- A reminder names the alias you could have used when a typed command starts with its definition

## Install

Source `zalias.plugin.zsh`, or point your plugin manager at this repository:

```sh
git clone https://github.com/devastion/zalias.git ~/.zsh/zalias
echo 'source ~/.zsh/zalias/zalias.plugin.zsh' >> ~/.zshrc
```

The plugin adds its `functions` directory and the `_zalias` completion to `fpath`.

## Usage

```sh
zalias -d 'Quit' {q,quit}='exit'           # described alias
zalias -e -d 'Git status' gs='git status'  # expands on Space
zalias -e -b -d 'Pipe to grep' -g G='| grep'
zalias                                     # cheatsheet
zalias gs                                  # description of one alias or function
```

| Option | Meaning |
| --- | --- |
| `-e` | Expand the alias when Space is pressed |
| `-b` | Do not leave a Space after expansion |
| `-g` | Create a global alias |
| `-d text` | Set the alias description |

Redefining an alias with `zalias` resets the options you leave out, including its description.

## Configuration

```zsh
# Directories of autoload functions to list in the cheatsheet. A function is listed
# when the second line of its file is "# desc: <text>".
zstyle ':zalias:' function-dirs ~/.zsh/functions

# Turn off the "Tip: gs = git status" reminder.
zstyle ':zalias:' reminder no

# Do not bind Space; bind the zalias-expand-space widget yourself.
zstyle ':zalias:' bind-space no
bindkey -M viins ' ' zalias-expand-space
```

Set these before sourcing the plugin; `function-dirs` is read each time `zalias` runs.

Expansion uses the `_expand_alias` widget from compinit, so it needs the completion system loaded. The cheatsheet popup needs `tmux` and `less`; otherwise it prints to the terminal. Piped output is plain `name: description` lines. `NO_COLOR` turns off colours.

## License

MIT
