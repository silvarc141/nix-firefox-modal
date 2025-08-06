{
  lib,
  config,
  pkgs,
  ...
}: let 
  inherit (lib) mkEnableOption mkOption types concatMapStringsSep mkIf filterAttrs hasPrefix;
  inherit (builtins) toJSON readFile replaceStrings attrNames match;
in {
  options.programs.firefox.modal = {
    enable = mkEnableOption "Firefox modal keyboard mapping system";
    initialMode = mkOption {
      type = types.str;
      description = "Id of mode that should be set at the start";
      default = "n";
    };
    mouseMode = mkOption {
      type = types.str;
      description = "Id of mode that should be set when a mouse button is used";
      default = "i";
    };
    modeIndicatorStyle = mkOption {
      type = types.str;
      description = "";
      default = "position: fixed; bottom: 10px; right: 10px; background: #333; color: white; padding: 5px 10px; z-index: 9999; border-radius: 3px;";
    };
    modes = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            default = "";
            description = "Display name of the mode";
          };
          blockDefaultBindings = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to block default Firefox shortcuts in this mode";
          };
          onEnter = mkOption {
            type = types.str;
            default = "";
            description = "JavaScript code to execute when entering this mode";
          };
          onExit = mkOption {
            type = types.str;
            default = "";
            description = "JavaScript code to execute when exiting this mode";
          };
          onKey = mkOption {
            type = types.str;
            default = "";
            description = "JavaScript code to execute on every keypress in this mode";
          };
        };
      });
      default = {
        n = {
          name = "NORMAL";
          onEnter = "gBrowser.selectedBrowser.focus()";
          onKey = "blockDefaultKey()";
        };
        a = {
          name = "ADDRESS";
          onEnter = "Browser:OpenLocation";
          # block some annoying shortcuts
          onKey =
            # js
            ''
              if (keyBuffer == "<C-[>"
                || keyBuffer == "<C-]>"
                || keyBuffer == "<C-w>"
                || keyBuffer == "<C-t>"
                || keyBuffer == "<C-n>"
                || keyBuffer == "<C-p>"
                || keyBuffer == "<Tab>"
              ) blockDefaultKey()
            '';
        };
        s = {
          name = "SEARCH";
          onEnter = ''gBrowser.getFindBar().then(bar => { bar.startFind(0) })'';
          onExit = "gBrowser.getFindBar().then(x => { x.hidden = true; })";
          onKey = "if (modifiers.length > 0) blockDefaultKey()";
        };
        l = {
          name = "LINK";
          onEnter = ''gBrowser.getFindBar().then(bar => { bar.startFind(2) })'';
          onExit = "gBrowser.getFindBar().then(x => { x.hidden = true; })";
          onKey = "if (modifiers.length > 0) blockDefaultKey()";
        };
        i = {};
      };
      description = "Mode definitions";
    };
    mappings = mkOption {
      type = types.listOf (types.submodule {
        options = {
          key = mkOption {
            type = types.str;
            description = "Vim-style keyboard mapping";
          };
          command = mkOption {
            type = types.str;
            description = ''
              Possible values:
              - Commands in formats "cmd_*" (ex. cmd_scrollPageDown) or "*:*" (ex. "Browser:Forward"). May be discovered by searching "mainCommandSet" or "mainKeyset" in Firefox's browser toolbox (not web dev tools!).
              - JavaScript to execute. Look at ${./template.js} for variables in scope.
              More resources:
              "gBrowser. " - https://searchfox.org/mozilla-central/source/browser/components/tabbrowser/content/tabbrowser.js
            '';
          };
          modes = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Modes where this mapping is active";
          };
          description = mkOption {
            type = types.str;
            default = "";
            description = "Description of the mapping";
          };
        };
      });
      default = [
        # Debug
        {
          key = "<C-A-D>";
          command = "this.modalState.debug = !this.modalState.debug";
          modes = ["n"];
        }
        # Mode switching
        {
          key = "<C-A-B>";
          command = "setMode('b')";
          modes = ["n"];
        }
        {
          key = "<Esc>";
          command = "setMode('n'); blockDefaultKey()";
          modes = ["a" "i" "s" "h" "l"];
        }
        {
          key = "<C-[>";
          command = "setMode('n'); blockDefaultKey()";
          modes = ["a" "i" "s" "h" "l"];
        }
        {
          key = "<CR>";
          command = "setMode('n')";
          modes = ["a" "l"];
        }
        {
          key = "<CR>";
          command = "setMode('n'); blockDefaultKey()";
          modes = ["s"];
        }
        {
          key = "a";
          command = "setMode('a')";
          modes = ["n"];
        }
        {
          key = "/";
          command = "setMode('s')";
          modes = ["n"];
        }
        {
          key = "f";
          command = "setMode('l')";
          modes = ["n"];
        }
        {
          key = "i";
          command = "setMode('i');";
          modes = ["n"];
        }
        # Scroll
        {
          key = "j";
          command = "cmd_scrollPageDown";
          modes = ["n"];
        }
        {
          key = "k";
          command = "cmd_scrollPageUp";
          modes = ["n"];
        }
        {
          key = "gg";
          command = "cmd_moveTop";
          modes = ["n"];
        }
        {
          key = "G";
          command = "cmd_moveBottom";
          modes = ["n"];
        }
        # Find
        {
          key = "n";
          command = ''ctx.window.gLazyFindCommand("onFindAgainCommand", false)'';
          modes = ["n"];
        }
        {
          key = "N";
          command = ''ctx.window.gLazyFindCommand("onFindAgainCommand", true)'';
          modes = ["n"];
        }
        # Tabs
        {
          key = "o";
          command =
            # js
            ''
              gBrowser.selectedTab = gBrowser.addTab('about:newtab', { triggeringPrincipal: ctx.systemPrincipal });
              setMode('a');
            '';
          modes = ["n"];
        }
        {
          key = "d";
          command = "gBrowser.removeTab(gBrowser.selectedTab)";
          modes = ["n"];
        }
        {
          key = "u";
          command = "History:RestoreLastClosedTabOrWindowOrSession";
          modes = ["n"];
        }
        {
          key = "r";
          command = "gBrowser.reload()";
          modes = ["n"];
        }
        {
          key = "h";
          command = "gBrowser.tabContainer.advanceSelectedTab(-1, true)";
          modes = ["n"];
        }
        {
          key = "l";
          command = "gBrowser.tabContainer.advanceSelectedTab(1, true)";
          modes = ["n"];
        }
        {
          key = ".";
          command = "gBrowser.duplicateTab(gBrowser.selectedTab)";
          modes = ["n"];
        }
        {
          key = "<C-p>";
          command = "ctx.window.gURLBar.controller.view.selectBy(-1); blockDefaultKey()";
          modes = ["a"];
        }
        {
          key = "<C-n>";
          command = "ctx.window.gURLBar.controller.view.selectBy(1); blockDefaultKey()";
          modes = ["a"];
        }
        {
          key = "P";
          command =
            # js
            ''
              let tab = gBrowser.selectedTab
              if (tab.pinned) {
                gBrowser.unpinTab(tab)
              } else {
                gBrowser.pinTab(tab)
              }
            '';
          modes = ["n"];
        }
        {
          key = "p";
          command =
            # js
            ''
              ctx.window.navigator.clipboard.readText().then(text => {
                gBrowser.selectedTab = gBrowser.addTab(text, { triggeringPrincipal: ctx.systemPrincipal });
              });
            '';
          modes = ["n"];
        }
        {
          key = "y";
          command = "ctx.window.navigator.clipboard.writeText(gBrowser.selectedBrowser.currentURI.spec);";
          modes = ["n"];
        }
        # Navigation
        {
          key = "<C-i>";
          command = "Browser:Forward";
          modes = ["n"];
        }
        {
          key = "<C-o>";
          command = "Browser:Back";
          modes = ["n"];
        }
      ];
      description = "Vim-style keyboard mappings";
    };
    extraJSConfigPre = mkOption {
      type = types.str;
      default = "";
      description = "JavaScript code to inject before the main block";
    };
    extraJSConfigPost = mkOption {
      type = types.str;
      default = "";
      description = "JavaScript code to inject after the main block";
    };
  };

  config = mkIf (config.programs.firefox.enable && config.programs.firefox.modal.enable) {
    programs.firefox.package = let
      cfg = config.programs.firefox.modal;

      mkCommand = cmd:
        if (hasPrefix "cmd_" cmd)
        then "ctx.window.goDoCommand('${cmd}')"
        else if ((match "[A-Z][a-z]+:[A-Za-z0-9_]+" cmd) != null)
        then
          # js
          ''
            const element = ctx.document.getElementById('${cmd}'); 
            if (element) element.doCommand();
            else Components.utils.reportError('Could not find element by id for command: ${cmd}');''
        else cmd;

      preInjection = cfg.extraJSConfigPre;
      postInjection = cfg.extraJSConfigPost;

      mappingsInjection = concatMapStringsSep ",\n" (mapping: ''
        {
          key: "${mapping.key}",
          command: (ctx) => {${mkCommand mapping.command}},
          modes: ${toJSON mapping.modes}
        }'')
      cfg.mappings;

      modeExitCallbackInjection = let
        callbacks = filterAttrs (id: mode: mode.onExit != "") cfg.modes;
      in
        concatMapStringsSep "\n" (
          id: ''
            case "${id}":
              ${mkCommand cfg.modes.${id}.onExit}
              break;''
        ) (attrNames callbacks);

      modeEnterCallbackInjection = let
        callbacks = filterAttrs (id: mode: mode.onEnter != "") cfg.modes;
      in
        concatMapStringsSep "\n" (
          id: ''
            case "${id}":
              ${mkCommand cfg.modes.${id}.onEnter}
              break;''
        ) (attrNames callbacks);

      modeKeyCallbackInjection = let
        callbacks = filterAttrs (id: mode: mode.onKey != "") cfg.modes;
      in
        concatMapStringsSep "\n" (
          id: ''
            case "${id}":
              ${mkCommand cfg.modes.${id}.onKey}
              break;''
        ) (attrNames callbacks);

      modeNameInjection = concatMapStringsSep "\n" (id: ''
        case "${id}":
          modeName = "${cfg.modes.${id}.name}";
          break;'') (attrNames cfg.modes);

      indicatorStyleInjection = cfg.modeIndicatorStyle;

      initialModeInjection = cfg.initialMode;

      mouseModeInjection = cfg.mouseMode;

      final =
        replaceStrings (map (x: "/*###${x}*/") [
          "PRE"
          "POST"
          "MAPPINGS"
          "MODE_EXIT_CALLBACK"
          "MODE_ENTER_CALLBACK"
          "MODE_KEY_CALLBACK"
          "MODE_NAME"
          "INDICATOR_STYLE"
          "INITIAL_MODE"
          "MOUSE_MODE"
        ]) [
          preInjection
          postInjection
          mappingsInjection
          modeExitCallbackInjection
          modeEnterCallbackInjection
          modeKeyCallbackInjection
          modeNameInjection
          indicatorStyleInjection
          initialModeInjection
          mouseModeInjection
        ]
        (readFile ./template.js);
    in
      pkgs.firefox.override {extraPrefs = final;};
  };
}
