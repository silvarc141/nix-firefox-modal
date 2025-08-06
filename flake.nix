{
  description = "firefox-modal, a small nix-configured Vimium-like privileged firefox modification for home-manager";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  outputs = {...}: { homeManagerModules.firefoxModal = import ./.; };
}
