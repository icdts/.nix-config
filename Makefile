.PHONY: all
all: clean update build switch

.PHONY: switch 
switch: 
	sudo nixos-rebuild switch --flake .

.PHONY: build
build:
	nixos-rebuild build --flake .

.PHONY: update
update:
	nix flake update

.PHONY: clean
clean:
	nix-collect-garbage -d --delete-older-than 30d
