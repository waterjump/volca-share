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

VS.SnapKnob.prototype.midiByDegree = function(degree) {
  angleToMidiMap = {
    '-90': 10,
    '-60': 30,
    '-30': 50,
    '0': 70,
    '30': 100,
    '60': 120
  };
  return angleToMidiMap[degree];
};

VS.SnapKnob.prototype.degreeForMidi = function(midi, limit) {
  midiToAngleMap = {
    '10': -90,
    '30': -60,
    '50': -30,
    '70': 0,
    '100': 30,
    '120': 60
  };

  return midiToAngleMap[midi];
};