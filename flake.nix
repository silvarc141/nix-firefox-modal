{
  description = "firefox-modal, a small nix-configured Vimium-like privileged firefox modification for home-manager";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  outputs = {nixpkgs, ...}: {
    homeManagerModules = rec {
      firefoxModal = import ./home-manager.nix;
      default = firefoxModal;
    };
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    packages.x86_64-linux.firefox-modal-prefs = let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      generateFirefoxModalPrefs = import ./lib.nix {inherit lib;};
      moduleOptions = (import ./options.nix {inherit lib;}).programs.firefox.modal;
      defaultCfg = lib.mapAttrs (name: option: option.default) moduleOptions;
    in
      pkgs.writeTextFile {
        name = "firefox-modal-prefs.js";
        text = generateFirefoxModalPrefs defaultCfg;
      };
  };
}
