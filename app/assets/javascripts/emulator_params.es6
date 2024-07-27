VS.EmulatorParams = function() {
  this.defaultVcoAmp = 0.33;

  this.tempo = 56;
  this.envelope = { attack: 0, decayRelease: 0.07, cutoffEgInt: 0 };
  this.filterEgCoefficient = 1.35;
  this.octave = 3;
  this.filter = { cutoff: 20000, peak: 0 };
  this.lfo = {
    shape: 'triangle',
    targetAmp: false,
    targetPitch: false,
    targetCutoff: true,
    ampValue: 0,
    pitchValue: 0,
    cutoffValue: 0,
    frequency: 0.1
  };
  this.vco =
    [
      null,
      { shape: 'sawtooth', amp: this.defaultVcoAmp, pitchMidi: 63, detune: 0 },
      { shape: 'sawtooth', amp: this.defaultVcoAmp, pitchMidi: 63, detune: 0 },
      { shape: 'square', amp: this.defaultVcoAmp, pitchMidi: 63, detune: 0 }
    ];
  this.sustainOn = false;
  this.ampEgOn = false;
  this.volume = 1;
  this.stepRecEnabled = false;
  this.stepRecIndex = 1;

  this.getPercentage = function(midiValue) {
    return midiValue / 127.0;
  };
  this.settempo = function(midiValue) {
    this.tempo = calculateTempo(midiValue);
  };
  this.setattack = function(midiValue) {
    // Based on collected data from Volca Bass
    this.envelope.attack = this.getPercentage(midiValue) * 0.86;
  };
  this.setdecay_release = function(midiValue) {
    // Keeping these old formulas bc I might do a before and after.
    // let oldValue = 5 * this.getPercentage(midiValue)**3 + 0.05;
    this.envelope.decayRelease =
      calculateMappedParameter('decayRelease', midiValue);
  };
  this.setcutoff_eg_int = function(midiValue) {
    // let oldValueInHz = this.getPercentage(midiValue)**2 * 10000;
    // TODO: This needs adjusting.  NOTE: It's in cents now.  Not Hz.
    this.envelope.cutoffEgInt = 1200 * (midiValue / 20.0);
  };
  this.setoctave = function(midiValue) {
    this.octave = parseInt(VS.display.octaveString(midiValue)[3]);
  };
  this.setpeak = function(midiValue) {
    this.filter.peak = (this.getPercentage(midiValue)**2.5 * 30.0);
  };
  this.setcutoff = function(midiValue) {
    // Note: Curve calculated using audacity data from actual synth, and
    //   plugged into WolframAlpha: https://tinyurl.com/y2qp9ebp
    this.filter.cutoff =
      Math.min(...[22050, 3.28311 * (Math.E**(0.0802801 * midiValue))]);
  };
  this.setlfo_rate = function(midiValue) {
    // let oldValue = (this.getPercentage(midiValue)**3 * 35) + 0.1;
    this.lfo.frequency = calculateMappedParameter('lfoRate', midiValue);
  };
  this.setlfo_int = function(midiValue) {
    percentage = this.getPercentage(midiValue);
    this.lfo.pitchValue = percentage * 900;
    this.lfo.cutoffValue = percentage**2 * 4800;
    this.lfo.ampValue = percentage;
  };
  this.setvco_pitch = function(oscNumber, midiValue) {
    this.vco[oscNumber].pitchMidi = midiValue;
    this.vco[oscNumber].detune =
      emulatorConstants.pitchMap[patch.vco[oscNumber].pitchMidi] * 100;
  };
  this.setvco1_pitch = function(midiValue) {
    this.setvco_pitch(1, midiValue);
  };
  this.setvco2_pitch = function(midiValue) {
    this.setvco_pitch(2, midiValue);
  };
  this.setvco3_pitch = function(midiValue) {
    this.setvco_pitch(3, midiValue);
  };
  this.setvco_active = function(oscNumber, value) {
    if (value === 'true') {
      this.vco[oscNumber].amp = this.defaultVcoAmp;
    } else {
      this.vco[oscNumber].amp = 0;
    }
  };
  this.setvco1_active = function(value) {
    this.setvco_active(1, value);
  };
  this.setvco2_active = function(value) {
    this.setvco_active(2, value);
  };
  this.setvco3_active = function(value) {
    this.setvco_active(3, value);
  };
  this.setvolume = function(value) {
    this.volume = this.getPercentage(value);
  };
  this.setlfo_target_amp = function(value) {
    this.lfo.targetAmp = (value === 'true');
  };
  this.setlfo_target_pitch = function(value) {
    this.lfo.targetPitch = (value === 'true');
  };
  this.setlfo_target_cutoff = function(value) {
    this.lfo.targetCutoff = (value === 'true');
  };
  this.setlfo_wave = function(shape) {
    this.lfo.shape = shape;
  };
  this.setvco1_wave = function(shape) {
    this.vco[1].shape = shape;
  };
  this.setvco2_wave = function(shape) {
    this.vco[2].shape = shape;
  };
  this.setvco3_wave = function(shape) {
    this.vco[3].shape = shape;
  };
  this.setsustain_on = function(value) {
    this.sustainOn = (value === 'true');
  };
  this.setamp_eg_on = function(value) {
    this.ampEgOn = (value === 'true');
  }

  // UTILITY FUNCTIONS
  const calculateTempo = function(superMidi) {
    let value;
    if (superMidi <= 160) {
      value = 56 + (0.5 * superMidi);
    } else if (superMidi > 160 && superMidi <= 246) {
      value = 136 + (superMidi - 160);
    } else if (superMidi > 246 && superMidi <= 255) {
      value = 222 + (superMidi - 246) * 2;
    }
    return value;
  }
};
