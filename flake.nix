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
              mkdir -p sources
              curl https://src.fedoraproject.org/rpms/kernel/raw/main/f/kernel-x86_64-rhel.config -o sources/rhel
              curl https://src.fedoraproject.org/rpms/kernel/raw/main/f/kernel-x86_64-fedora.config -o sources/fedora
              curl https://raw.githubusercontent.com/clearlinux-pkgs/linux/master/config -o sources/clear
              curl https://raw.githubusercontent.com/clearlinux-pkgs/linux/master/config-fragment -o sources/clear-fragment
              curl https://raw.githubusercontent.com/archlinux/svntogit-packages/packages/linux/trunk/config -o sources/arch
            '';
          }
        ];

      };

    };
}


