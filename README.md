# zalias

A zsh plugin for aliases with descriptions.

- `zalias -d 'description' name=value` defines an alias and remembers what it is for
- `zalias` prints a cheatsheet of described aliases and functions, in a tmux popup when possible
- `zalias -e` aliases expand in place when you press Space; add `-b` to drop the Space
- `zalias --stats` shows aliases you never use and commands you type often that no alias covers (needs `sqlite3`)
- `zalias -D` defines aliases that only exist inside a directory and its subdirectories (needs `sqlite3`)
- A reminder names the alias you could have used when a typed command starts with its definition (definitions are parsed once and cached until the alias table changes; those containing `${VAR}` are re-read on every command)

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
| `-t tag` | Tag the alias; repeat for several tags |
| `-D` | Scope the alias to a directory (current one, or `--dir=path`) |
| `-r` | Remove aliases (with `-D`, directory aliases) |
| `-s text` | Search names, definitions and descriptions |
| `--tag tag` | List defined aliases with a tag |
| `--stats` | Show usage statistics |
| `--list` | With `-D`, list directory aliases |

```sh
zalias -D -d 'Run dev server' dev='npm run dev'        # only in this directory tree
zalias -D --dir ~/work/api -d 'Migrate' mig='make migrate'
zalias -D --list
zalias -D -r dev
zalias -t git -d 'Git status' gs='git status'          # tag, then: zalias --tag git
zalias -s status                                       # search
zalias --stats
```

Directory aliases are stored in the database, not in files inside the repository, so entering a checkout cannot define aliases. They load at the first prompt, so they replace aliases from your rc file; when you leave the directory the alias you had before comes back. A deeper directory wins over a shallower one, and a directory alias never replaces a global (`-g`) alias of the same name. `--dir` must name an existing directory, and a leading `~` is expanded. Another shell sees changes after it restarts.

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

# Database for usage counts, tags and directory aliases (default below).
zstyle ':zalias:' db ~/.local/share/zalias/zalias.db

# Stop recording usage (the database is then only used for tags and directory aliases).
zstyle ':zalias:' stats no
```

Set these before sourcing the plugin; `function-dirs` is read each time `zalias` runs.

Usage recording stores counts only (the database file is private to you, mode 600). Global aliases (`-g`) are not recorded, so `--stats` does not list them as unused: per alias, and per command (first word, plus the subcommand for `git`, `docker`, `npm`, `cargo` and `kubectl`). It never stores arguments, and it skips commands that start with a space. The write runs in a background job. The database (schema version 2) needs `sqlite3`. A version 1 database from an older release is deleted and recreated empty on first use, with no migration: its usage counts and directory aliases are lost. Export anything you want to keep first; without it the plugin works as before and the new commands print `zalias: sqlite3 not found`.

When the plugin binds Space, it remembers the widget that was bound before (for example `magic-space`) and calls it for ordinary Spaces. Source the plugin after your own Space binding.

Global aliases (`-g`) keep their own description and flags, so `G` as a global alias and `G` as a regular alias do not share them.

Expansion uses the `_expand_alias` widget from compinit, so it needs the completion system loaded. Source the plugin before `compinit` so the `_zalias` completion is found through `fpath`. The cheatsheet popup needs tmux 3.2 or later and `less`; otherwise it prints to the terminal. Piped output is plain `name: description` lines. `NO_COLOR` turns off colours.

## Testing

Tests use [ShellSpec](https://github.com/shellspec/shellspec) and run under zsh:

```sh
shellspec
```

## License

MIT
