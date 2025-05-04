let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
in
pkgs.mkShell {
  packages = with pkgs; [
    borgbackup
  ];
  shellHook = ''
    read -e -p "enter path to files you want to backup: " source_path
    read -e -p "enter path to borg repository: " repo_path
    read -e -p "enter path to password store borg keyphrase [backup/borg]: " pass_path_borg_keyphrase
    export repo_path="$(realpath "$repo_path")"
    export pass_path_borg_keyphrase=''${pass_path_borg_keyphrase:-"backup/borg"}
    export BORG_PASSCOMMAND="pass show $pass_path_borg_keyphrase"

    echo '$source_path='"$source_path"
    echo '$repo_path='"$repo_path"
    echo '$pass_path_borg_keyphrase='"$pass_path_borg_keyphrase"

    backup_create() {
      read -e -p "enter name of new borg archive [{hostname}_{now}]: " archive_name
      export archive_name=''${archive_name:-"{hostname}_{now}"}
      echo '$archive_name='$archive_name
      borg create --stats --progress --checkpoint-interval=300 --verbose "$repo_path"::"$archive_name" "$source_path"
      backup_list
    }

    backup_list() {
      borg list "$repo_path"
    }

    backup_extract_latest() {
      latest_archive="$(borg list "$repo_path" | tail -1 | awk '{print $1}')"
      read -e -p "enter path where to unpack backup: " extract_to
      mkdir -p "$extract_to"
      pushd "$extract_to"
      borg extract --progress --verbose "$repo_path"::"$latest_archive"
      popd
    }

    # fuse broken on my machine somehow?
    backup_mount_latest() {
      read -e -p "enter path where to mount backup: " mount_point
      mkdir -p "$mount_point"
      latest_archive="$(borg list "$repo_path" | tail -1 | awk '{print $1}')"
      borg mount --verbose "$repo_path"::"$latest_archive" "$mount_point"
    }

    backup_unmount() {
      read -e -p "enter path to mount point: " mount_point
      borg umount "$mount_point"
    }

    backup_prune() {
      borg prune         \
        --dry-run        \
        --progress       \
        --list           \
        --keep-weekly  1 \
        --keep-monthly 1 \
        --keep-yearly  1 \
        "$repo_path"
      read -e -p "do you want to run this prune? y/n [n]: " answer
      export answer=''${answer:-"n"}
      if [[ "$answer" = "Y" ]] || [[ "$answer" = "y" ]]; then
        borg prune         \
          --progress       \
          --list           \
          --keep-weekly  1 \
          --keep-monthly 1 \
          --keep-yearly  1 \
          "$repo_path"
        borg compact "$repo_path"
      fi
    }

    routine_backup() {
      backup_create
      backup_prune
    }

    backup_init() {
      borg init --encryption=repokey "$repo_path"
    }

  '';
}
