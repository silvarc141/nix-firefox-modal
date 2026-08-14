{
  description = "firefox-modal, a small nix-configured Vimium-like privileged firefox modification for home-manager";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs.lib) genAttrs;
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      homeManagerModules = rec {
        firefoxModal = import ./home-manager.nix;
        default = firefoxModal;
      };
      formatter = genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      packages = genAttrs allSystems (system: {
        firefox-modal-prefs =
          let
            lib = nixpkgs.lib;
            pkgs = nixpkgs.legacyPackages.${system};
            generateFirefoxModalPrefs = import ./lib.nix { inherit lib; };
            moduleOptions = (import ./options.nix { inherit lib; }).programs.firefox.modal;
            defaultCfg = lib.mapAttrs (name: option: option.default) moduleOptions;
          in
          pkgs.writeTextFile {
            name = "firefox-modal-prefs.js";
            text = generateFirefoxModalPrefs defaultCfg;
          };
      });
    };
}
