VS.KeysEmulatorParams = function() {
  const { emulatorConstants } = VS;

  this.defaultVcoAmp = 0.33;
  this.tempo = 56;
  this.voice = 'unison';
  this.octave = 3;
  this.detune = 0;
  this.portamento = 0;
  this.vco_eg_int = 0;
  this.filter = { cutoff: 20000, peak: 0 };
  this.vcf_eg_int = 0;
  this.lfo = {
    shape: 'triangle',
    pitchValue: 0,
    cutoffValue: 0,
    frequency: 0.1,
    triggerSync: false
  };
  this.envelope = { attack: 0, decayRelease: 0.07, sustain: 1 };

  this.vco =
    [
      null,
      { shape: 'sawtooth', amp: this.defaultVcoAmp, pitchMidi: 63, detune: 0, voiceDetune: 0 },
      { shape: 'sawtooth', amp: this.defaultVcoAmp, pitchMidi: 63, detune: -0.5, voiceDetune: 0 },
      { shape: 'sawtooth', amp: this.defaultVcoAmp, pitchMidi: 63, detune: 1, voiceDetune: 0 }
    ];
  this.delay = { time: 0.2, feedback: 0 }
  this.volume = 1;

  this.getPercentage = function(midiValue) {
    return midiValue / 127.0;
  };

  this.voiceChange = {
      poly: function() {
        this.vco[1].voiceDetune = 0;
        this.vco[3].voiceDetune = 0;
      }.bind(this),
      unison: function() {
        this.vco[1].voiceDetune = 0;
        this.vco[3].voiceDetune = 0;
      }.bind(this),

      octave: function() {
        this.vco[1].voiceDetune = 0;
        this.vco[3].voiceDetune = 1200;
      }.bind(this),

      fifth: function() {
        this.vco[1].voiceDetune = 0;
        this.vco[3].voiceDetune = 700;
        [1, 2, 3].forEach(function(i) {
          this.vco[i].shape = 'sawtooth';
        }.bind(this));
      }.bind(this),

      'unison ring': function() {
        this.vco[1].voiceDetune = -1200;
        this.vco[3].voiceDetune = 0;
        [1, 2, 3].forEach(function(i) {
          this.vco[i].shape = 'square';
        }.bind(this));
      }.bind(this),

      'poly ring': function() {
        this.vco[1].voiceDetune = 0;
        this.vco[3].voiceDetune = 0;
        [1, 2, 3].forEach(function(i) {
          this.vco[i].shape = 'square';
        }.bind(this));
      }.bind(this),
    };

  this.setvoice = function(midiValue) {
    const voiceMidiMap = {
      10: 'poly',
      30: 'unison',
      50: 'octave',
      70: 'fifth',
      100: 'unison ring',
      120: 'poly ring'
    };
    if (voiceMidiMap[midiValue] !== this.voice) {
      this.voice = voiceMidiMap[midiValue];
      this.voiceChange[this.voice]()
    }
  };

  this.settempo = function(midiValue) {
    this.tempo = calculateTempo(midiValue);
  };

  this.setattack = function(midiValue) {
    this.envelope.attack = this.getPercentage(midiValue) * 0.89;
  };

  this.setdecay_release = function(midiValue) {
    this.envelope.decayRelease =
      calculateMappedParameter('keysDecayReleaseTap', midiValue);
  };

  this.setsustain = function(midiValue) {
    this.envelope.sustain = this.getPercentage(midiValue);
  };

  this.setvcf_eg_int = function(midiValue) {
    this.vcf_eg_int = this.getPercentage(midiValue) * 6000;
  };

  this.setportamento = function(midiValue) {
    this.portamento = this.getPercentage(midiValue) * 0.258 + 0.008;
  };

  this.setoctave = function(midiValue) {
    this.octave = parseInt(VS.display.octaveString(midiValue)[3]);
  };

  this.setpeak = function(midiValue) {
    this.filter.peak = (this.getPercentage(midiValue)**2.5 * 30.0);
  };

  this.setcutoff = function(midiValue) {
    this.filter.cutoff = calculateMappedParameter('keysCutoff', midiValue);
  };

  this.setlfo_rate = function(midiValue) {
    this.lfo.frequency = calculateMappedParameter('keysLfoRate', midiValue);
  };

  this.setlfo_pitch_int = function(midiValue) {
    percentage = this.getPercentage(midiValue);
    this.lfo.pitchValue = percentage * 440;
  };

  this.setlfo_cutoff_int = function(midiValue) {
    this.lfo.cutoffValue = this.getPercentage(midiValue) * 6000;
  };

  this.setdetune = function(midiValue) {
    this.detune = midiValue;
    cents = this.getPercentage(midiValue) * 84;
    this.vco[2].detune = (cents * -1) - 0.5;
    this.vco[3].detune = cents + 1;
  };

  this.setdelay_time = function(midiValue) {
    // TODO: Implement machine specific values
    //  Max: 0.5
    //  Mid: ~ 0.2
    //  Min: 0.129
    this.delay.time = 0.129 + this.getPercentage(midiValue) * 0.371;
  }

  this.setdelay_feedback = function(midiValue) {
    this.delay.feedback = this.getPercentage(midiValue) * 0.6;
  }

  this.setvco_pitch = function(oscNumber, midiValue) {
    this.vco[oscNumber].pitchMidi = midiValue;
    this.vco[oscNumber].detune =
      emulatorConstants.pitchMap[this.vco[oscNumber].pitchMidi] * 100;
  };

  this.setvco_eg_int = function(midiValue) {
    this.vco_eg_int = this.getPercentage(midiValue) * 1200;
  };

  this.setvolume = function(value) {
    this.volume = this.getPercentage(value);
  };

  this.setlfo_wave = function(shape) {
    this.lfo.shape = shape;
  };

  this.setlfo_trigger_sync = function() {
    this.lfo.triggerSync = !this.lfo.triggerSync;
  };

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

  const parameterMaps = {
    keysCutoffMap: emulatorConstants.keysCutoffMap,
    keysDecayReleaseTapMap: emulatorConstants.keysDecayReleaseTapMap,
    keysLfoRateMap: emulatorConstants.keysLfoRateMap
  };

  const calculateMappedParameter = (paramName, midiValue) => {
    const map = parameterMaps[`${paramName}Map`];
    midiValue = Math.round(midiValue);

    if (map[midiValue] !== undefined) {
      return map[midiValue];
    }

    const entries = Object.entries(map).map(([key, value]) => [Number(key), value]);

    for (let i = 1; i < entries.length; i++) {
      const [midi, paramValue] = entries[i];
      const [lowerMidi, lowerParamValue] = entries[i - 1];

      if (midiValue < midi) {
        const slope = (paramValue - lowerParamValue) / (midi - lowerMidi);
        const cleanValue = Number(((midiValue - lowerMidi) * slope + lowerParamValue).toFixed(3));

        return map[midiValue] = cleanValue;
      }
    }
  };
};
