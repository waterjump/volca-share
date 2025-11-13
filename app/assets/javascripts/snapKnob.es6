VS.SnapKnob = function(element) {
  // Call the parent constructor with the current context
  VS.Knob.call(this, element);

  this.setLimits();
};

// Inherit from VS.Knob
VS.SnapKnob.prototype = Object.create(VS.Knob.prototype);

// Set the constructor back to SnapKnob for consistency
VS.SnapKnob.prototype.constructor = VS.SnapKnob;

VS.SnapKnob.prototype.setLimits = function(degree) {
  this.leftLimit = -90;
  this.rightLimit = 60;
};

// Static mapping objects - defined once and reused
VS.SnapKnob.ANGLE_TO_MIDI_MAP = {
  '-90': 10,
  '-60': 30,
  '-30': 50,
  '0': 70,
  '30': 100,
  '60': 120
};

VS.SnapKnob.MIDI_TO_ANGLE_MAP = {
  '10': -90,
  '30': -60,
  '50': -30,
  '70': 0,
  '100': 30,
  '120': 60
};

VS.SnapKnob.prototype.midiByDegree = function(degree) {
  return VS.SnapKnob.ANGLE_TO_MIDI_MAP[degree];
};

VS.SnapKnob.prototype.trueMidiByDegree = function(degree) {
  return this.midiByDegree(degree);
};

VS.SnapKnob.prototype.closestSnapMidiValue = function(num) {
  const options = Object.values(VS.SnapKnob.ANGLE_TO_MIDI_MAP);

  return options.reduce((closest, current) => {
    const closestDiff = Math.abs(num - closest);
    const currentDiff = Math.abs(num - current);

    if (currentDiff < closestDiff || (currentDiff === closestDiff && current > closest)) {
      return current;
    } else {
      return closest;
    }
  });
};

VS.SnapKnob.prototype.degreeForMidi = function(midi, limit = 140) {
  return VS.SnapKnob.MIDI_TO_ANGLE_MAP[midi];
};
