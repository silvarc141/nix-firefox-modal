//commented 3 hashes with text are tags for code generation

function setModeMain(modeId, ctx) {
  //#region Helpers for mode callbacks
  const gBrowser = ctx.window.gBrowser;
  //#endregion

  const nextModeId = modeId;
  const previousModeId = ctx.window.modalState.currentModeId;
  if (nextModeId === undefined) {
    Components.utils.reportError("Set mode ID is undefined");
    return;
  }
  if (nextModeId === ctx.window.modalState.currentModeId)
    return;
  if (previousModeId !== undefined) {
    try {
      switch (previousModeId) {
        /*###MODE_EXIT_CALLBACK*/
      };
    } catch (e) {
      Components.utils.reportError("Error: " + e + " (in onExit callback for mode with id: '" + previousModeId + "')");
    }
  }

  ctx.window.modalState.currentModeId = nextModeId;

  let indicator = ctx.document.getElementById('mode-indicator');
  if (indicator) indicator.remove();

  let modeName = "";
  switch (nextModeId) {
    /*###MODE_NAME*/
  };

  if (modeName !== "") {
    indicator = ctx.document.createElement('div');
    indicator.id = 'mode-indicator';
    indicator.style.cssText = '/*###INDICATOR_STYLE*/';
    indicator.textContent = modeName;
    ctx.document.documentElement.appendChild(indicator);
  }

  if (nextModeId !== undefined) {
    try {
      switch (nextModeId) {
        /*###MODE_ENTER_CALLBACK*/
      };
    } catch (e) {
      Components.utils.reportError("Error: " + e + " (in onEnter callback for mode with id: '" + nextModeId + "')");
    }
  }
};

function keyboardListen(event) {
  if (['Control', 'Shift', 'Alt', 'Meta'].includes(event.key)) {
    return;
  }

  let key = event.key;
  switch (key) {
    case 'Escape': key = 'Esc'; break;
    case 'Enter': key = 'CR'; break;
    case 'Return': key = 'CR'; break;
    case 'Backspace': key = 'BS'; break;
    case 'Delete': key = 'Del'; break;
    case 'ArrowLeft': key = 'Left'; break;
    case 'ArrowRight': key = 'Right'; break;
    case 'ArrowUp': key = 'Up'; break;
    case 'ArrowDown': key = 'Down'; break;
    case '<': key = 'lt'; break;
    case '>': key = 'gt'; break;
    case '|': key = 'Bar'; break;
  }

  let modifiers = [];
  if (event.ctrlKey) modifiers.push('C');
  if (event.altKey) modifiers.push('A');
  if (event.metaKey) modifiers.push('M');
  if (event.shiftKey && key.length !== 1) {
    modifiers.push('S');
  }

  if (modifiers.length > 0) {
    key = '<' + modifiers.join('-') + '-' + key + '>';
  } else if (key.length > 1) {
    key = '<' + key + '>';
  }

  let keyBuffer = this.modalState.keyBuffer;
  keyBuffer += key;

  const currentModeId = this.modalState.currentModeId;
  if (!currentModeId) return;

  const ctx = this.modalContext;

  //#region Helpers for mappings
  const gBrowser = ctx.window.gBrowser;

  function blockDefaultKey() {
    event.preventDefault();
    event.stopPropagation();
  };

  function setMode(modeId) {
    setModeMain(modeId, ctx)
  };
  //#endregion

  const mappings = [
    /*###MAPPINGS*/
  ];

  const matchingMappings = mappings.filter(x => x.modes && x.modes.includes(currentModeId) && x.key.startsWith(keyBuffer));
  const uniqueMatches = new Set(matchingMappings.map(x => x.key)).size;

  if (this.modalState.debug) {
    Components.utils.reportError("Debug: keybuffer: " + keyBuffer + " unique matches: " + uniqueMatches);
  }

  if (uniqueMatches === 0) keyBuffer = "";
  if (uniqueMatches === 1 && matchingMappings[0].key === keyBuffer) {
    if (matchingMappings.length > 1) {
      Components.utils.reportError("Overlapping keymaps: " + keyBuffer + " Proceeding with first");
    }
    keyBuffer = "";
    try {
      matchingMappings[0].command(ctx);
    } catch (e) {
      Components.utils.reportError("Error: " + e + " (in mode with id: '" + currentModeId + "', while executing command: '" + matchingMappings[0].command + "')");
    }
  }
  try {
    switch (currentModeId) {
      /*###MODE_KEY_CALLBACK*/
    };
  } catch (e) {
    Components.utils.reportError("Error: " + e + " (in onKey callback for mode with id: '" + currentModeId + "')");
  }

  this.modalState.keyBuffer = keyBuffer;
}

function mouseListen(event) {
  setModeMain('/*###MOUSE_MODE*/', this.modalContext);
}

function attach(ctx) {
  /*###PRE*/
  ctx.window.modalState = {
    currentModeId: undefined,
    keyBuffer: '',
    debug: false
  };

  ctx.window.modalContext = ctx;

  ctx.window.addEventListener('keydown', keyboardListen, true);
  ctx.window.addEventListener('mousedown', mouseListen, true);

  setModeMain('/*###INITIAL_MODE*/', ctx);

  /*###POST*/
}

// taken from: https://superuser.com/questions/1271147/change-key-bindings-keyboard-shortcuts-in-firefox-57
try {
  function ConfigJS() { globalThis.Services.obs.addObserver(this, 'chrome-document-global-created', false); }

  // unfortunately this doesn't seem to work well
  // vimium has it's own solution that requires communicating with user scripts, which would be out of scope to do securely
  globalThis.Services.prefs.setIntPref("accessibility.tabfocus", 1);

  ConfigJS.prototype = {
    observe: function(aSubject) { aSubject.addEventListener('DOMContentLoaded', this, { once: true }); },
    handleEvent: function(aEvent) {
      let ctx = {
        document: aEvent.originalTarget,
        window: aEvent.originalTarget.defaultView,
        systemPrincipal: globalThis.Services.scriptSecurityManager.getSystemPrincipal(),
      };

      if (!(/^(chrome:(?!\/\/(global\/content\/commonDialog|browser\/content\/webext-panels)\.x?html)|about:(?!blank))/i.test(ctx.window.location.href)))
        return;

      if (!ctx.window.Tabbrowser) {
        return;
      }

      attach(ctx)
    }
  };
  if (!globalThis.Services.appinfo.inSafeMode) { new ConfigJS(); }
} catch (ex) { Components.utils.reportError(ex); };
