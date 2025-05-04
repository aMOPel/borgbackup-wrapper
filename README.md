# borgbackup-wrapper

wrapped borgbackup cli in a simple interactive nix-shell

# usage

0. read the source in [`./shell.nix`](./shell.nix)
1. enter nix-shell

```sh
nix-shell
```

2. fill in requested data
3. use abstracted borg commands. use shell autocomplete (`<tab>`)

```sh
backup_<tab>
```
