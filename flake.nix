{
  description = "NixOS kernel magic";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    devshell.url = "github:numtide/devshell";
  };

  outputs = { self, nixpkgs, devshell, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ devshell.overlay ];
      };

    in
    {

      devShell.${system} = pkgs.devshell.mkShell {

        commands = [
          {
            name = "fetch-kernel-configs";
            command = ''
              mkdir -p $DEVSHELL_ROOT/sources
              curl https://src.fedoraproject.org/rpms/kernel/raw/main/f/kernel-x86_64-rhel.config -o sources/rhel
              curl https://src.fedoraproject.org/rpms/kernel/raw/main/f/kernel-x86_64-fedora.config -o sources/fedora
              curl https://raw.githubusercontent.com/clearlinux-pkgs/linux/master/config -o sources/clear
              curl https://raw.githubusercontent.com/clearlinux-pkgs/linux/master/config-fragment -o sources/clear-fragment
              curl https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/linux/trunk/config -o sources/arch
            '';
          }
          {
            name = "clean-sources";
            command = ''
              mkdir -p $DEVSHELL_ROOT/sources-clean
              for f in $(find $DEVSHELL_ROOT/sources -type f); do
                 grep '^[^#]' $f | sort > $DEVSHELL_ROOT/sources-clean/$(basename $f)
              done
            '';
          }
          {
            name = "find-uniq-values";
            command = ''
              mkdir -p $DEVSHELL_ROOT/uniq
              cat $DEVSHELL_ROOT/sources-clean/* | sort | uniq -u > $DEVSHELL_ROOT/uniq/values
              cat $DEVSHELL_ROOT/uniq/values | cut -d= -f1 | sort | uniq > $DEVSHELL_ROOT/uniq/keys
            '';
          }
          {
            name = "show-diffs";
            command = ''
              for k in $(cat $DEVSHELL_ROOT/uniq/keys); do
                url="https://cateee.net/lkddb/web-lkddb/$(echo $k | sed 's|CONFIG_||g').html"
                echo $url
                ${pkgs.lynx}/bin/lynx $url -dump \
                  | awk '/General informations/,/Hardware/' \
                  | ${pkgs.bat}/bin/bat --pager=never --language md
                cd $DEVSHELL_ROOT/sources
                grep $k -r . --color=always
                read
              done
            '';
          }
        ];

      };

    };
}


