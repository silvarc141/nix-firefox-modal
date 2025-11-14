{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
in {
  options = import ./options.nix {inherit lib;};

  config = mkIf (config.programs.firefox.enable && config.programs.firefox.modal.enable) {
    programs.firefox.package = let
      cfg = config.programs.firefox.modal;
      generateFirefoxModalPrefs = import ./lib.nix {inherit lib;};
      final = generateFirefoxModalPrefs cfg;
    in
      pkgs.firefox.override {extraPrefs = final;};
  };
}
