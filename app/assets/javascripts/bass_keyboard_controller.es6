VS.BassKeyboardController = function(options = {}) {
  const patch = options.patchParams;
  const emulatorConstants = options.emulatorConstants || VS.emulatorConstants;
  const onNoteDown = options.onNoteDown || function() {};
  const onOctaveChange = options.onOctaveChange || function() {};
  const onStepRecordNote = options.onStepRecordNote || function() {};
  const getBinding = options.getBinding || function() { return null; };

  let enabled = options.enabled !== false;
  let keysDown = [];

  const binding = () => {
    const currentBinding = getBinding();
    if (!currentBinding || !currentBinding.engine || !currentBinding.patchParams) {
      return null;
    }

    return currentBinding;
  };

  const octaveAdjustedKeyCode = (keycode) => {
    const octaveOffset = (patch.octave - 3) * 12;
    return emulatorConstants.keyMidiMap[keycode] + octaveOffset;
  };

  const transposeHeldNotes = (octaveOffset) => {
    const currentBinding = binding();
    if (!currentBinding || keysDown.length === 0) { return; }

    keysDown = keysDown.map(key => key + octaveOffset);
    currentBinding.engine.changeOctave(octaveOffset);
  };

  this.noteOn = function(note) {
    const currentBinding = binding();
    if (!currentBinding || currentBinding.engine.getSequencerPlaying()) { return; }

    onNoteDown(note);
    currentBinding.engine.setNotePlaying(note);

    if (!keysDown.includes(note)) {
      keysDown.push(note);
    }

    onStepRecordNote();

    if (keysDown.length === 1) {
      currentBinding.engine.playNewNote();
    } else {
      currentBinding.engine.changeCurrentNote();
    }
  };

  this.noteOff = function(noteThatStopped) {
    const currentBinding = binding();
    if (!currentBinding || currentBinding.engine.getSequencerPlaying()) { return; }

    keysDown = keysDown.filter(key => key !== noteThatStopped);

    if (keysDown.length > 0) {
      currentBinding.engine.setNotePlaying(keysDown[keysDown.length - 1]);
      currentBinding.engine.changeCurrentNote();
      return;
    }

    currentBinding.engine.stopNote();
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
