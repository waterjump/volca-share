VS.KeysKeyboardController = function(options = {}) {
  const patch = options.patchParams;
  const emulatorConstants = options.emulatorConstants || VS.emulatorConstants;
  const onNoteDown = options.onNoteDown || function() {};
  const onOctaveChange = options.onOctaveChange || function() {};
  const getBindings = options.getBindings || function() { return []; };

  let enabled = options.enabled !== false;
  let keysDown = [];

  const bindings = () => {
    return getBindings().filter(binding => binding && binding.engine && binding.patchParams);
  };

  const octaveAdjustedKeyCode = (keycode) => {
    const octaveOffset = (patch.octave - 3) * 12;
    return emulatorConstants.keyMidiMap[keycode] + octaveOffset;
  };

  const transposeHeldNotes = (octaveOffset) => {
    if (keysDown.length === 0) { return; }

    keysDown = keysDown.map(key => key + octaveOffset);

    bindings().forEach(binding => {
      binding.engine.changeOctave(octaveOffset);
    });
  };

  this.noteOn = function(note) {
    onNoteDown(note);
    keysDown.push(note);

    bindings().forEach(binding => {
      const voice = binding.patchParams.voice;
      if (keysDown.length === 1) {
        // First note
        binding.engine.playNewNote(note);
      } else if (voice.includes('poly')) {
        // Add second or third poly note
        binding.engine.addNote(keysDown, note);
      } else {
        // Switch monophonic note
        binding.engine.changeCurrentNote(note);
      }
    });
  };

  this.noteOff = function(noteThatStopped) {
    keysDown = keysDown.filter(key => key !== noteThatStopped);

    bindings().forEach(binding => {
      const voice = binding.patchParams.voice;

      if (keysDown.length > 0) {
        if (voice.includes('poly')) {
          binding.engine.stopPolyNote(keysDown, noteThatStopped);
          return;
        }

        binding.engine.changeCurrentNote(keysDown[keysDown.length - 1]);
        return;
      }

      binding.engine.stopPolyNote(keysDown, noteThatStopped);
      binding.engine.stopNote();
    });
  };

  this.applyOctaveChange = function(change, keyStroke = true) {
    const octaveOffset = change * 12;
    onOctaveChange(change, keyStroke, octaveOffset);
    transposeHeldNotes(octaveOffset);
  };

  this.syncOctave = function() {
    onOctaveChange(0, false, 0);
  };

  this.octaveUp = function() {
    if (patch.octave >= 9) { return; }
    patch.octave += 1;
    this.applyOctaveChange(1);
  }.bind(this);

  this.octaveDown = function() {
    if (patch.octave <= -1) { return; }
    patch.octave -= 1;
    this.applyOctaveChange(-1);
  }.bind(this);

  const handleKeyDown = (event) => {
    if (!enabled || event.repeat) { return; }

    if (emulatorConstants.keyCodes.includes(event.keyCode)) {
      this.noteOn(octaveAdjustedKeyCode(event.keyCode));
    }

    if (event.keyCode === emulatorConstants.zKeyCode) { this.octaveDown(); }
    if (event.keyCode === emulatorConstants.xKeyCode) { this.octaveUp(); }
  };

  const handleKeyUp = (event) => {
    if (!enabled) { return; }

    if (emulatorConstants.keyCodes.includes(event.keyCode)) {
      this.noteOff(octaveAdjustedKeyCode(event.keyCode));
    }
  };

  this.enable = function() {
    enabled = true;
  };

  this.disable = function() {
    enabled = false;
  };

  this.isEnabled = function() {
    return enabled;
  };

  this.getKeysDown = function() {
    return keysDown.slice();
  };

  window.addEventListener('keydown', handleKeyDown);
  window.addEventListener('keyup', handleKeyUp);

  this.destroy = function() {
    window.removeEventListener('keydown', handleKeyDown);
    window.removeEventListener('keyup', handleKeyUp);
  };
};
