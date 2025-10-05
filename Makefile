.PHONY: all
all: clean update build switch

.PHONY: update
update:
	nix flake update

.PHONY: clean
clean:
	sudo nix-collect-garbage -d --delete-older-than 30d

.PHONY: build
build:
	nixos-rebuild build --flake .#rnl

.PHONY: switch
switch:
	sudo nixos-rebuild switch --flake .#rnl

.PHONY: sd-image
sd-image:
	nix build .#nixosConfigurations.voron24.config.system.build.sdImage --out-link sdcard

.PHONY: deploy-voron24
deploy-voron24:
	sudo nixos-rebuild switch --sudo --target-host rn@voron24.local --flake .#voron24
