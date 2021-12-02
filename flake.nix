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

      root = "$PRJ_ROOT";
    in
    {

      devShell.${system} = pkgs.devshell.mkShell {

        commands = [
          {
            name = "fetch-kernel-configs";
            command = ''
              mkdir -p ${root}/sources
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
              mkdir -p ${root}/sources-clean
              for f in $(find ${root}/sources -type f); do
                 grep '^[^#]' $f | sort > ${root}/sources-clean/$(basename $f)
              done
            '';
          }
          {
            name = "find-uniq-values";
            command = ''
              mkdir -p ${root}/uniq
              cat ${root}/sources-clean/* | sort | uniq -u > ${root}/uniq/values
              cat ${root}/uniq/values | cut -d= -f1 | sort | uniq > ${root}/uniq/keys
            '';
          }
          {
            name = "show-diffs";
            command = ''
              for k in $(cat ${root}/uniq/keys); do
                url="https://cateee.net/lkddb/web-lkddb/$(echo $k | sed 's|CONFIG_||g').html"
                echo $url
                ${pkgs.lynx}/bin/lynx $url -dump \
                  | awk '/General informations/,/Hardware/' \
                  | ${pkgs.bat}/bin/bat --pager=never --language md
                cd ${root}/sources-clean
                grep $k -wr . --color=always
                read
              done
            '';
          }
          {
            name = "update";
            command = ''
              fetch-kernel-configs
              clean-sources
              find-uniq-values
            '';
          }
        ];

      };

    };
}


