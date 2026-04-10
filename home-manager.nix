{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  options = import ./options.nix { inherit lib; };

  config = mkIf (config.programs.firefox.enable && config.programs.firefox.modal.enable) {
    programs.firefox.package =
      let
        cfg = config.programs.firefox.modal;
        generateFirefoxModalPrefs = import ./lib.nix { inherit lib; };
        modalSource = generateFirefoxModalPrefs cfg;
        wrappedPackage = pkgs.firefox.override { extraPrefs = modalSource; };
      in
      pkgs.runCommand "${wrappedPackage.name}-no-sandbox"
        {
          nativeBuildInputs = [ pkgs.bash ];
        }
        ''
          mkdir -p $out
          ln -s ${wrappedPackage}/* $out/
          rm $out/lib/firefox/defaults/pref/autoconfig.js
          cat ${wrappedPackage}/lib/firefox/defaults/pref/autoconfig.js > $out/lib/firefox/defaults/pref/autoconfig.js
          echo 'pref("general.config.sandbox_enabled", false);' >> $out/lib/firefox/defaults/pref/autoconfig.js
        '';
  };
}
