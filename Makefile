.PHONY: all
all: switch

.PHONY: switch 
switch: build
	sudo nixos-rebuild switch --flake .

.PHONY: build
build: clean update
	nixos-rebuild build --flake .

.PHONY: update
update:
	nix flake update

.PHONY: clean
clean:
	nix-collect-garbage --delete-older-than 30d
