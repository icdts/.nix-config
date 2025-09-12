{
  inputs,
  username,
  userconfig,
}: 
  system: 
    {
      host-configuration,
      hardware-configuration,
    }:
      let
        syspkgs = import inputs.nixpkgs {
					inherit system;
					config.allowUnfree = true;
				};
        home-manager = import ../home.nix;
      in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
					specialArgs = { inherit inputs; };

          modules = [
            {
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
              boot.kernelPackages = syspkgs.linuxPackages_latest;
              networking.networkmanager.enable = true;

              time.timeZone = "America/Chicago";

              i18n.defaultLocale = "en_US.UTF-8";
              i18n.extraLocaleSettings = {
                LC_ADDRESS = "en_US.UTF-8";
                LC_IDENTIFICATION = "en_US.UTF-8";
                LC_MEASUREMENT = "en_US.UTF-8";
                LC_MONETARY = "en_US.UTF-8";
                LC_NAME = "en_US.UTF-8";
                LC_NUMERIC = "en_US.UTF-8";
                LC_PAPER = "en_US.UTF-8";
                LC_TELEPHONE = "en_US.UTF-8";
                LC_TIME = "en_US.UTF-8";
              };

              services.xserver = {
                xkb = {
                  layout = "us";
                  variant = "";
                };
              };

              services.openssh = {
                enable = true;
                settings.PermitRootLogin = "no";
                allowSFTP = true;
              };
              security.sudo = {
                wheelNeedsPassword = false;
                enable = true;
              };

              users.mutableUsers = true;
              users.users."${username}" = userconfig;

              system.stateVersion = "24.05";
              catppuccin = {
                enable = true;
                flavor = "mocha";
              };

              environment.systemPackages = with syspkgs; [
                git
								gnumake
              ];
              users.defaultUserShell = syspkgs.bash;

              fonts.enableDefaultPackages = true;
              fonts.packages = with syspkgs; [
                nerd-fonts.fira-code
                nerd-fonts.noto
              ];
            }

            hardware-configuration
            host-configuration
            inputs.home-manager.nixosModules.home-manager
            {
              # add home-manager settings here
              # home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${username}" = home-manager;
              home-manager.backupFileExtension = "home-manager.bk";
            }
            inputs.catppuccin.nixosModules.catppuccin
          ];
        }
