$(function() {
  VS.clicked = false;
  VS.dragging = false;
  VS.activeKnob = null;
  VS.clickedPoint = null;
  VS.currentPoint = null;
  VS.midiOut = new VS.MidiOut;
  VS.display = new VS.Display($('#led'));
  VS.sequences = new VS.Sequences;
  VS.form = new VS.Form;
  if ($('.bass.emulator').length > 0) {
    console.log('bass emulator code loading!');
    VS.emulatorConstants = new VS.EmulatorConstants;
    VS.emulatorParams = new VS.EmulatorParams;
    VS.bassEmulator = new VS.BassEmulator;
  }
  if ($('.keys.emulator').length > 0) {
    console.log('KEYS emulator code loading!');
    VS.emulatorConstants = new VS.EmulatorConstants;
    VS.emulatorParams = new VS.KeysEmulatorParams;
    VS.bassEmulator = new VS.KeysEmulator;
  }
});
