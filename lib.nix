{lib}: cfg: let
  inherit (lib) concatMapStringsSep filterAttrs hasPrefix;
  inherit (builtins) toJSON readFile replaceStrings attrNames match;

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
    callbacks = filterAttrs (id: mode: (mode.onExit or "") != "") cfg.modes;
  in
    concatMapStringsSep "\n" (
      id: ''
        case "${id}":
          ${mkCommand cfg.modes.${id}.onExit}
          break;''
    ) (attrNames callbacks);

  modeEnterCallbackInjection = let
    callbacks = filterAttrs (id: mode: (mode.onEnter or "") != "") cfg.modes;
  in
    concatMapStringsSep "\n" (
      id: ''
        case "${id}":
          ${mkCommand cfg.modes.${id}.onEnter}
          break;''
    ) (attrNames callbacks);

  modeKeyCallbackInjection = let
    callbacks = filterAttrs (id: mode: (mode.onKey or "") != "") cfg.modes;
  in
    concatMapStringsSep "\n" (
      id: ''
        case "${id}":
          ${mkCommand cfg.modes.${id}.onKey}
          break;''
    ) (attrNames callbacks);

  modeNameInjection = concatMapStringsSep "\n" (id: ''
    case "${id}":
      modeName = "${(cfg.modes.${id}.name or "")}";
      break;'') (attrNames cfg.modes);

  indicatorStyleInjection = cfg.modeIndicatorStyle;
  initialModeInjection = cfg.initialMode;
  mouseModeInjection = cfg.mouseMode;
in
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
  (readFile ./template.js)
