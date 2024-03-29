VS.BassEmulator = function() {
  const { sequences } = VS;

  // =====================
  // Declare map constants
  // =====================

  let keyMidiMap = {
    65: 48, // C
    87: 49, // C#
    83: 50, // D
    69: 51, // D#
    68: 52, // E
    70: 53, // F
    84: 54, // F#
    71: 55, // G
    89: 56, // G#
    72: 57, // A
    85: 58, // A#
    74: 59, // B
    75: 60, // C
    79: 61, // C#
    76: 62  // D
  }

  // Key is vco pitch MIDI value.  Value is detune value in semitones.
  const pitchMap = {
     0: -12,    1: -12,    2: -11,    3: -10,    4: -9,     5: -8,     6: -7,     7: -6,     8: -5,     9: -4,
    10: -3,    11: -2,    12: -1,    13: -0.96, 14: -0.92, 15: -0.88, 16: -0.84, 17: -0.80, 18: -0.78, 19: -0.76,
    20: -0.74, 21: -0.72, 22: -0.70, 23: -0.68, 24: -0.66, 25: -0.64, 26: -0.62, 27: -0.60, 28: -0.58, 29: -0.56,
    30: -0.54, 31: -0.52, 32: -0.50, 33: -0.48, 34: -0.46, 35: -0.44, 36: -0.42, 37: -0.40, 38: -0.38, 39: -0.36,
    40: -0.34, 41: -0.32, 42: -0.30, 43: -0.28, 44: -0.26, 45: -0.24, 46: -0.22, 47: -0.20, 48: -0.18, 49: -0.16,
    50: -0.14, 51: -0.12, 52: -0.10, 53: -0.08, 54: -0.06, 55: -0.04, 56: -0.02, 57: 0,     58: 0,     59: 0,
    60: 0,     61: 0,     62: 0,     63: 0,     64: 0,     65: 0,     66: 0,     67: 0,     68: 0,     69: 0,
    70: 0,     71: 0.02,  72: 0.04,  73: 0.06,  74: 0.08,  75: 0.10,  76: 0.12,  77: 0.14,  78: 0.16,  79: 0.18,
    80: 0.20,  81: 0.22,  82: 0.24,  83: 0.26,  84: 0.28,  85: 0.30,  86: 0.32,  87: 0.34,  88: 0.36,  89: 0.38,
    90: 0.40,  91: 0.42,  92: 0.44,  93: 0.46,  94: 0.48,  95: 0.50,  96: 0.52,  97: 0.54,  98: 0.56,  99: 0.58,
    100: 0.60, 101: 0.62, 102: 0.64, 103: 0.66, 104: 0.68, 105: 0.70, 106: 0.72, 107: 0.74, 108: 0.76, 109: 0.78,
    110: 0.80, 111: 0.84, 112: 0.88, 113: 0.92, 114: 0.96, 115: 1,    116: 2,    117: 3,    118: 4,    119: 5,
    120: 6,    121: 7,    122: 8,    123: 9,    124: 10,   125: 11,   126: 12,   127: 12
  }

  const zKeyCode = 90;
  const xKeyCode = 88;

  const octaveMap = {
    "-1": 8,
    0: 9,
    1: 21,
    2: 33,
    3: 45,
    4: 57,
    5: 69,
    6: 81,
    7: 93,
    8: 105,
    9: 118
  };

  const octaveKnobMidiMap = {
    '-1': 0,
    0: 0,
    1: 0,
    2: 33,
    3: 55,
    4: 77,
    5: 99,
    6: 127,
    7: 127,
    8: 127,
    9: 127
  };

  const keyCodes = Object.keys(keyMidiMap).map(Number);

  const parameterMaps = {
    decayReleaseMap: {
      0: 0.07, 10: 0.075, 20: 0.085, 30: 0.091, 40: 0.1, 50: 0.11, 60: 0.13,
      70: 0.15, 80: 0.18, 90: 0.215, 100: 0.29, 110: 0.44, 115: 0.56, 120: 0.84,
      122: 1.04, 125: 1.65, 127: 2.64
    },
    lfoRateMap: {
      0: 0.0383, 10: 0.23, 20: 0.421, 30: 0.612, 40: 0.803, 50: 1, 60: 1.186,
      70: 1.377, 80: 1.569, 90: 1.757, 100: 6.757, 110: 20, 115: 35.71,
      120: 60, 127: 94
    }
  };

  const decayReleaseGainCurve = [
    1, 0.89, 0.8, 0.73, 0.65, 0.58, 0.52, 0.46, 0.41, 0.36, 0.31, 0.26, 0.22,
    0.18, 0.15, 0.12, 0.09, 0.07, 0.05, 0.03, 0.02, 0.01, 0.005, 0.0001
  ];

  const calculateMappedParameter = function(paramName, midiValue) {
    let entries, midi, paramValue, lowerMidi, lowerParamValue, slope;
    let midiDifference, rawValue, cleanValue;
    let map = parameterMaps[`${paramName}Map`];

    midiValue = Math.round(midiValue);

    if (map[midiValue] !== undefined) {
      return map[midiValue];
    } else {
      entries =
        Object.keys(map).map((key) => [key, map[key]]);

      for (let index = 0; index < entries.length; index++) {
        midi = entries[index][0];
        if (midiValue < midi) {
          paramValue = entries[index][1];
          lowerMidi = entries[index - 1][0];
          lowerParamValue = entries[index - 1][1];
          slope =
            (paramValue - lowerParamValue) /
              (parseFloat(midi) - parseFloat(lowerMidi));
          midiDifference = midiValue - lowerMidi;
          rawValue = (midiDifference * slope) + lowerParamValue;
          cleanValue = Number(rawValue.toFixed(3));

          map[Number(midiValue)] = cleanValue;
          return cleanValue;
        }
      }
    }
  };

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


  // ===========================================
  // Setup patch object to hold parameter values
  // ===========================================

  const defaultVcoAmp = 0.33;

  const patch = {
    tempo: 56,
    envelope: { attack: 0, decayRelease: 0.07, cutoffEgInt: 0 },
    filterEgCoefficient: 1.35,
    octave: 3,
    filter: { cutoff: 20000, peak: 0 },
    lfo: {
      shape: 'triangle',
      targetAmp: false,
      targetPitch: false,
      targetCutoff: true,
      ampValue: 0,
      pitchValue: 0,
      cutoffValue: 0,
      frequency: 0.1
    },
    vco:
      [
        null,
        { shape: 'sawtooth', amp: defaultVcoAmp, pitchMidi: 63, detune: 0 },
        { shape: 'sawtooth', amp: defaultVcoAmp, pitchMidi: 63, detune: 0 },
        { shape: 'square', amp: defaultVcoAmp, pitchMidi: 63, detune: 0 }
      ],
    sustainOn: false,
    ampEgOn: false,
    volume: 1,

    getPercentage: function(midiValue) {
      return midiValue / 127.0;
    },
    settempo: function(midiValue) {
      this.tempo = calculateTempo(midiValue);
    },
    setattack: function(midiValue) {
      // Based on collected data from Volca Bass
      this.envelope.attack = this.getPercentage(midiValue) * 0.86;
    },
    setdecay_release: function(midiValue) {
      // Keeping these old formulas bc I might do a before and after.
      // let oldValue = 5 * this.getPercentage(midiValue)**3 + 0.05;
      this.envelope.decayRelease =
        calculateMappedParameter('decayRelease', midiValue);
    },
    setcutoff_eg_int: function(midiValue) {
      // let oldValueInHz = this.getPercentage(midiValue)**2 * 10000;
      // TODO: This needs adjusting.  NOTE: It's in cents now.  Not Hz.
      this.envelope.cutoffEgInt = 1200 * (midiValue / 20.0);
    },
    setoctave: function(midiValue) {
      this.octave = parseInt(VS.display.octaveString(midiValue)[3]);
    },
    setpeak: function(midiValue) {
      this.filter.peak = (this.getPercentage(midiValue)**2.5 * 30.0);
    },
    setcutoff: function(midiValue) {
      // Note: Curve calculated using audacity data from actual synth, and
      //   plugged into WolframAlpha: https://tinyurl.com/y2qp9ebp
      this.filter.cutoff =
        Math.min(...[22050, 3.28311 * (Math.E**(0.0802801 * midiValue))]);
    },
    setlfo_rate: function(midiValue) {
      // let oldValue = (this.getPercentage(midiValue)**3 * 35) + 0.1;
      this.lfo.frequency = calculateMappedParameter('lfoRate', midiValue);
    },
    setlfo_int: function(midiValue) {
      percentage = this.getPercentage(midiValue);
      this.lfo.pitchValue = percentage * 900;
      this.lfo.cutoffValue = percentage**2 * 4800;
      this.lfo.ampValue = percentage;
    },
    setvco_pitch: function(oscNumber, midiValue) {
      this.vco[oscNumber].pitchMidi = midiValue;
      this.vco[oscNumber].detune = pitchMap[patch.vco[oscNumber].pitchMidi] * 100;
    },
    setvco1_pitch: function(midiValue) {
      this.setvco_pitch(1, midiValue);
    },
    setvco2_pitch: function(midiValue) {
      this.setvco_pitch(2, midiValue);
    },
    setvco3_pitch: function(midiValue) {
      this.setvco_pitch(3, midiValue);
    },
    setvco_active: function(oscNumber, value) {
      if (value === 'true') {
        this.vco[oscNumber].amp = defaultVcoAmp;
      } else {
        this.vco[oscNumber].amp = 0;
      }
    },
    setvco1_active: function(value) {
      this.setvco_active(1, value);
    },
    setvco2_active: function(value) {
      this.setvco_active(2, value);
    },
    setvco3_active: function(value) {
      this.setvco_active(3, value);
    },
    setvolume: function(value) {
      this.volume = this.getPercentage(value);
    },
    setlfo_target_amp: function(value) {
      this.lfo.targetAmp = (value === 'true');
    },
    setlfo_target_pitch: function(value) {
      this.lfo.targetPitch = (value === 'true');
    },
    setlfo_target_cutoff: function(value) {
      this.lfo.targetCutoff = (value === 'true');
    },
    setlfo_wave: function(shape) {
      this.lfo.shape = shape;
    },
    setvco1_wave: function(shape) {
      this.vco[1].shape = shape;
    },
    setvco2_wave: function(shape) {
      this.vco[2].shape = shape;
    },
    setvco3_wave: function(shape) {
      this.vco[3].shape = shape;
    },
    setsustain_on: function(value) {
      this.sustainOn = (value === 'true');
    },
    setamp_eg_on: function(value) {
      this.ampEgOn = (value === 'true');
    }
  };

  const sequence = [];

  this.getSequence = function() {
    return sequence;
  };

  const populateSequenceObject = function() {
    $('.step:visible').each(function(index, step) {
      sequence.push(
        {
          index: index,
          note: $(step).find('.note-display').data('starting-note'),
          slide: $(step).find('.slide .light').data('active'),
          stepMode: $(step).find('.step-mode .light').data('active'),
          activeStep: $(step).find('.active-step .light').data('active')
        }
      );
    });
  }

  const setSequenceView = function() {
    if (sequence.length !== 16) { return }

    sequence.forEach(step => {
      jElement = $(`#step_${step.index}`)
      jElement.find('.note-display').data('starting-note', step.note);
      jElement.find('.note-display').html(VS.midiNoteNumbers[step.note]);
      jElement.find('.slide .light').data('active', step.slide);
      jElement.find('.slide .light').addClass(step.slide ? 'lit' : '');
      jElement.find('.step-mode .light').data('active', step.stepMode);
      jElement.find('.step-mode .light').removeClass(step.stepMode ? '' : 'lit');
      jElement.find('.active-step .light').data('active', step.activeStep);
      jElement.find('.active-step .light').removeClass(step.activeStep ? '' : 'lit');
    });
  };

  $('#toggle-sequences, #play').on('click tap', function() {
    setSequenceView();
    if (sequence.length === 0) {
      populateSequenceObject();
    }
  });

  const volcaInterface = {
    lightAndCheck: function(paramName) {
      let light = $(`#${paramName}_light`);
      let checkbox = $(`input#patch_${paramName}`)
      if (!(light.hasClass('lit'))) { light.toggleClass('lit') }
      if (!(checkbox.prop('checked'))) { checkbox.prop('checked', true) }
    },
    unlightAndUncheck: function(paramName) {
      let light = $(`#${paramName}_light`);
      let checkbox = $(`input#patch_${paramName}`)
      if (light.hasClass('lit')) { light.toggleClass('lit') }
      if (checkbox.prop('checked')) { checkbox.prop('checked', false) }
    }
  }

  // TODO: Put this in a class?
  const letterToBoolean = function(letter){
    return letter.toLowerCase() === 't';
  };

  const processSequenceFromQueryString = function(urlParams) {
    const rawValue = urlParams.get('sequence');
    if (rawValue === null) { return; }
    if (rawValue.match(/^(\d{1,3}[tf]{3}\|){15}(\d{1,3}[tf]{3})$/) === null) {
      console.log('Sequence param is malformed.  Ignoring.');
      return;
    }

    const steps = rawValue.split('|');
    $(steps).each((index, step) => {
      let note = parseInt(step.match(/^\d+/)[0]);
      if (note > 127) {
        note = 127;
      }
      sequence.push(
        {
          index: index,
          note: note,
          slide: letterToBoolean(step.match(/[tf]/g)[0]),
          stepMode: letterToBoolean(step.match(/[tf]/g)[1]),
          activeStep: letterToBoolean(step.match(/[tf]/g)[2])
        }
      );
    });
  };

  const processQueryString = function() {
    let urlParams;
    try {
      urlParams = new URLSearchParams(window.location.search);
    } catch (_) {
      urlParams = {
        get: function(name) {
          name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
          var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
          var results = regex.exec(location.search);
          return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
        }
      };
    }

    const qsKnobs = [
      'attack', 'decay_release', 'cutoff_eg_int', 'octave', 'peak', 'cutoff',
      'lfo_rate', 'lfo_int', 'vco1_pitch','vco2_pitch', 'vco3_pitch', 'volume'
    ];

    qsKnobs.forEach(function(qsParam) {
      const rawValue = urlParams.get(qsParam);
      const parsedValue = parseInt(rawValue);
      if (0 <= parsedValue && parsedValue <= 127) {
        patch[`set${qsParam}`](parsedValue);

        new VS.Knob($(`#${qsParam}`)).setKnob(parsedValue);
      } else {
        new VS.Knob($(`#${qsParam}`)).setKnob();
      }
    });

    const tempoParam = parseInt(urlParams.get('tempo'));
    if (0 <= tempoParam && tempoParam <= 255) {
      patch.settempo(tempoParam);
      new VS.Knob($('#tempo')).setKnob(tempoParam);
    }

    const qsVcoActiveParams = ['vco1_active', 'vco2_active', 'vco3_active'];

    qsVcoActiveParams.forEach(function(qsParam) {
      const rawValue = urlParams.get(qsParam);
      if (['true', 'false'].indexOf(rawValue) !== -1) {
        patch[`set${qsParam}`](rawValue);

        // NOTE: Might be able to trigger the event in form.es6 if it differs
        //   from default.  That way the data attributes and css classes will
        //   be handled there and I can removed a lot of this stuff.  Maybe.
        const button = $(`#${qsParam}_button`);
        const vcoKnob = function() {
          const number = qsParam.charAt(3);
          return $(`#vco${number}_pitch`);
        }();

        button.data('active', (rawValue === 'true'));

        if (rawValue === 'true') {
          if (!(button.hasClass('lit'))) { button.toggleClass('lit') }
          if (!(vcoKnob.hasClass('lit'))) { vcoKnob.toggleClass('lit') }
          if (vcoKnob.hasClass('unlit')) { vcoKnob.toggleClass('unlit') }
        } else {
          if (button.hasClass('lit')) { button.toggleClass('lit') }
          if (vcoKnob.hasClass('lit')) { vcoKnob.toggleClass('lit') }
          if (!(vcoKnob.hasClass('unlit'))) { vcoKnob.toggleClass('unlit') }
        }
      }
    });

    const qsBooleanParameters = [
      'lfo_target_amp', 'lfo_target_pitch', 'lfo_target_cutoff', 'sustain_on',
      'amp_eg_on'
    ];
    qsBooleanParameters.forEach(function(qsParam) {
      const qsValue = urlParams.get(qsParam);
      if (['true', 'false'].indexOf(qsValue) !== -1) {
        patch[`set${qsParam}`](qsValue);

        if (qsValue === 'true') {
          volcaInterface.lightAndCheck(qsParam);
        } else {
          volcaInterface.unlightAndUncheck(qsParam);
        }
      }
    });

    // LFO wave from query string
    const rawValue = urlParams.get('lfo_wave');
    if (['triangle', 'square'].indexOf(rawValue) !== -1) {
      patch.setlfo_wave(rawValue);

      if (rawValue == 'square') {
        volcaInterface.lightAndCheck('lfo_wave');
      } else {
        volcaInterface.unlightAndUncheck('lfo_wave');
      }
    }

    const vcoGroupParam = urlParams.get('vco_group');
    if (['one', 'two', 'three'].indexOf(vcoGroupParam) !== -1) {
      // TODO: Set vco group on patch object when it is supported

      $('.light[data-radio]').each(function() {
        $(this).removeClass('lit');
        $(`:radio[value=${vcoGroupParam}]`).prop('checked', false);
      });
      $(`:radio[value=${vcoGroupParam}]`).prop('checked', true);
      $(`label[for="patch_vco_group_${vcoGroupParam}"]`).find('span .light').addClass('lit');
    }

    const qsVcoWaves = ['vco1_wave', 'vco2_wave', 'vco3_wave'];

    qsVcoWaves.forEach(function(qsParam) {
      const rawValue = urlParams.get(qsParam);

      if (['square', 'sawtooth'].indexOf(rawValue) !== -1) {
        patch[`set${qsParam}`](rawValue);

        if (rawValue == 'square') {
          volcaInterface.lightAndCheck(qsParam);
        } else {
          volcaInterface.unlightAndUncheck(qsParam);
        }
      }
    });

    processSequenceFromQueryString(urlParams);
  };

  processQueryString();

  // =======================
  // END query string params
  // =======================

  let keysDown = [];
  const builtInDecay = 0.1;

  // =====================================
  // Setup web audio nodes (from here down)
  // =====================================

  const audioCtx = new AudioContext();
  const myToneCtx = new Tone.Context({context: audioCtx, lookAhead: 0.1})
  Tone.setContext(myToneCtx);
  Tone.start();
  const notePlaying = new Tone.Param(audioCtx.createGain().gain);
  const attackEndTime = new Tone.Param(audioCtx.createGain().gain);

  let masterAmp = audioCtx.createGain();
  masterAmp.connect(audioCtx.destination);

  // An amp used for modulating amplitude without overriding
  //  the master Amp level
  let preAmp = audioCtx.createGain();
  preAmp.connect(masterAmp);

  const filter = audioCtx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(patch.filter.cutoff, audioCtx.currentTime);
  filter.Q.value = patch.filter.peak;
  filter.connect(preAmp);

  const filterEgAmp = audioCtx.createGain();
  filterEgAmp.gain.setValueAtTime(patch.envelope.cutoffEgInt, audioCtx.currentTime);
  filterEgAmp.connect(filter.detune);

  const filterEg = audioCtx.createConstantSource();
  filterEg.offset.setValueAtTime(0, audioCtx.currentTime);
  filterEg.connect(filterEgAmp);
  filterEg.start();

  const filterEgOffsetParam = new Tone.Param(filterEg.offset);

  const ampEg = audioCtx.createGain();
  ampEg.gain.setValueAtTime(0, audioCtx.currentTime);
  ampEg.connect(filter);

  const ampEgGainParam = new Tone.Param(ampEg.gain);
  ampEgGainParam.setValueAtTime(0, audioCtx.currentTime);

  // Oscillator mute button amps (will go to gain 0 on mute button click)
  let osc1MuteAmp = audioCtx.createGain()
  osc1MuteAmp.gain.value = patch.vco[1].amp;
  osc1MuteAmp.connect(ampEg);
  let osc2MuteAmp = audioCtx.createGain()
  osc2MuteAmp.gain.value = patch.vco[2].amp;
  osc2MuteAmp.connect(ampEg);
  let osc3MuteAmp = audioCtx.createGain()
  osc3MuteAmp.gain.value = patch.vco[3].amp;
  osc3MuteAmp.connect(ampEg);

  const oscMuteAmps = [null, osc1MuteAmp, osc2MuteAmp, osc3MuteAmp];

  let osc = [null, null, null, null];

  const ampLfoPitch = audioCtx.createGain()
  const setAmpLfoPitchGain = function() {
    if (patch.lfo.targetPitch) {
      // Affect pitch
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, audioCtx.currentTime);
    } else {
      // Do not affect pitch
      ampLfoPitch.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  setAmpLfoPitchGain();

  const ampLfoCutoff = audioCtx.createGain()
  const setAmpLfoCutoffGain = function() {
    if (patch.lfo.targetCutoff) {
      // Affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, audioCtx.currentTime);
    } else {
      // Do not affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  setAmpLfoCutoffGain();
  ampLfoCutoff.connect(filter.detune);

  // Creates a curve that goes from -1, -1 to 1, 0.
  const makeLfoAmpCurve = function() {
    let n_samples = 44100;
    let curve = new Float32Array(n_samples)
    let i = 0;
    for ( ; i < n_samples; ++i ) {
      curve[i] = i / (n_samples - 1) - 1;
    }
    return curve;
  };

  const lfoAmpWaveShaper = audioCtx.createWaveShaper();
  lfoAmpWaveShaper.curve = makeLfoAmpCurve();

  const ampLfoAmp = audioCtx.createGain()
  const setAmpLfoAmpGain = function() {
    if (patch.lfo.targetAmp) {
      // Affect amp
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, audioCtx.currentTime);
    } else {
      // Do not affect amp
      ampLfoAmp.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  setAmpLfoAmpGain();

  lfoAmpWaveShaper.connect(ampLfoAmp);
  ampLfoAmp.connect(preAmp.gain);

  let oscLfo;

  const setupOscLfo = function() {
    oscLfo = audioCtx.createOscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, audioCtx.currentTime);
    oscLfo.connect(ampLfoPitch);
    oscLfo.connect(ampLfoCutoff);
    oscLfo.connect(lfoAmpWaveShaper);
    oscLfo.start();
  }

  setupOscLfo();

  // Setup oscilators
  [1, 2, 3].forEach(function(oscNumber) {
    let oscillator = audioCtx.createOscillator();
    oscillator.type = patch.vco[oscNumber].shape;
    oscillator.detune.setValueAtTime(
      patch.vco[oscNumber].detune,
      audioCtx.currentTime
    );

    oscillator.frequency.setValueAtTime(0, audioCtx.currentTime);

    osc[oscNumber] = oscillator;
    osc[oscNumber].connect(oscMuteAmps[oscNumber]);
    ampLfoPitch.connect(osc[oscNumber].detune);
    osc[oscNumber].start();
  });

  // controls frequency of all three vcos rather than looping through them.
  const oscFreqNode = audioCtx.createConstantSource();
  oscFreqNode.offset.setValueAtTime(440, audioCtx.currentTime);
  oscFreqNode.connect(osc[1].frequency);
  oscFreqNode.connect(osc[2].frequency);
  oscFreqNode.connect(osc[3].frequency);
  oscFreqNode.start();

  const oscFreqNodeOffsetParam = new Tone.Param(oscFreqNode.offset);

  // ==========================
  //  get browser capabilities
  // ==========================
  const browserFeatures = {};

  const checkCustomCurveClearing = function() {
    let dummyGain = audioCtx.createGain();
    dummyGain.gain.setValueCurveAtTime([0, 0.5, 0], audioCtx.currentTime, 2.6);
    try {
      dummyGain.gain.cancelScheduledValues(audioCtx.currentTime + 0.1);
      dummyGain.gain.setValueAtTime(1, audioCtx.currentTime + 0.2);
      browserFeatures['customCurveClearing'] = true;
    } catch (error) {
      browserFeatures['customCurveClearing'] = false;
    }
  };

  const checkCancelAndHoldAtTime = function() {
    let dummyGain = audioCtx.createGain();
    dummyGain.gain.setValueAtTime(0.5, audioCtx.currentTime);
    try {
      dummyGain.gain.cancelAndHoldAtTime(audioCtx.currentTime + 0.1);
      browserFeatures['cancelAndHoldAtTime'] = true;
    } catch (error) {
      browserFeatures['cancelAndHoldAtTime'] = false;
    }
  };

  const checkChrome = function() {
    browserFeatures['usingChrome'] = navigator.userAgent.includes('Chrome/');
  };

  const showPerformanceWarning = function() {
    if (browserFeatures['cancelAndHoldAtTime']) { return; }

    $('#performance-warning').html(
      '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
      '<span aria-hidden="true">&times;</span></button>' +
      '<strong>Just a heads up: </strong><br />' +
      'There are known performance issues with this browser, ' +
      'specifically while using the envelope and sequencer at the same time.<br /><br />' +
      'For best results, use a <a class="alert-link" target="_blank" ' +
      'href="https://caniuse.com/mdn-api_audioparam_cancelandholdattime">' +
      'supported browser.</a>'
    );
    $('#performance-warning').removeClass('hidden');
  };

  const testBrowserFeatures = function() {
    checkCustomCurveClearing();
    checkCancelAndHoldAtTime();
    checkChrome();
    console.log(browserFeatures);

    // showPerformanceWarning();
  };

  testBrowserFeatures();

  // END get browser capabilities


  const triggerDecay = function(attackEndTimeValue) {
    filterEgOffsetParam.linearRampToValueAtTime(
      0,
      attackEndTimeValue + (patch.envelope.decayRelease * patch.filterEgCoefficient)
    );

    if (patch.ampEgOn) {
      ampEgGainParam.setValueAtTime(1, attackEndTimeValue);

      if (browserFeatures['customCurveClearing'] && !sequencerPlaying) {
        // use custom curve
        ampEgGainParam.setValueCurveAtTime(
          decayReleaseGainCurve,
          attackEndTimeValue,
          patch.envelope.decayRelease
        )
      } else {
        ampEgGainParam.linearRampToValueAtTime(
          0,
          attackEndTimeValue + patch.envelope.decayRelease
        )
      }
    }
  };

  const retriggerLfo = function() {
    let lfo = patch.lfo;
    if (lfo.shape !== 'square') { return; }
    if (!(lfo.targetAmp) && !(lfo.targetPitch) && !(lfo.targetCutoff)) { return; }
    if (lfo.ampValue + lfo.pitchValue + lfo.cutoffValue === 0) { return; }

    oscLfo.disconnect();
    oscLfo = null;
    setupOscLfo();
  };

  let sequencerPlaying = false;

  let debugNewNote;
  const playNewNote = function(time = audioCtx.currentTime) {
    debugNewNote = audioCtx.currentTime;
    activateAudio();
    let frequency;

    // Filter EG reset
    filterEgOffsetParam.cancelAndHoldAtTime(time);

    const attackEndTimeValue = time + patch.envelope.attack;
    attackEndTime.setValueAtTime(attackEndTimeValue, time);

    // Amp EG reset
    ampEgGainParam.cancelAndHoldAtTime(time);

    // Set frequency
    frequency = Tone.Frequency(notePlaying.getValueAtTime(time), 'midi').toFrequency();
    oscFreqNodeOffsetParam.setValueAtTime(frequency, time);

    if (patch.ampEgOn && patch.envelope.attack > 0) {
      ampEgGainParam.setValueAtTime(0, time);
      ampEgGainParam.linearRampToValueAtTime(1, attackEndTimeValue);
    } else {
      ampEgGainParam.setValueAtTime(1, time);
    }

    retriggerLfo();

    // Retrigger envelope
    // Attack
    filterEgOffsetParam.setValueAtTime(0, time);
    filterEgOffsetParam.linearRampToValueAtTime(1, attackEndTimeValue);

    // Decay
    if (!patch.sustainOn) {
      triggerDecay(attackEndTimeValue);
    }
  };

  const changeCurrentNote = function(time = audioCtx.currentTime) {
    let frequency = Tone.Frequency(notePlaying.getValueAtTime(time), 'midi').toFrequency();
    let lastFrequency = oscFreqNodeOffsetParam.getValueAtTime(time);

    oscFreqNodeOffsetParam.setValueAtTime(lastFrequency, time);
    oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + 0.05);
  };

  // NOTE: This message will not be used by the sequencer.
  const changeOctave = function(change, time = audioCtx.currentTime) {
    VS.display.update(octaveMap[patch.octave], 'noteString');

    // Turn octave knob
    new VS.Knob($('#octave')).setKnob(octaveKnobMidiMap[patch.octave]);

    if (notePlaying === undefined) { return; } // at init time

    if (keysDown.length === 0) { return; } // when it's amp_eg release

    let octaveOffset = change * 12;
    notePlaying.setValueAtTime(notePlaying.getValueAtTime(time) + octaveOffset, time);
    keysDown = keysDown.map(key => key + octaveOffset);
    let frequency = Tone.Frequency(notePlaying.getValueAtTime(time), 'midi').toFrequency();
    oscFreqNodeOffsetParam.setValueAtTime(frequency, time);
  }

  changeOctave(0);
  sequences.init();

  const keyboardDown = function(time = audioCtx.currentTime){
    if (sequencerPlaying) { return; }
    if (keysDown.indexOf(notePlaying.getValueAtTime(time)) === -1) {
      keysDown.push(notePlaying.getValueAtTime(time));
    }

    if (keysDown.length === 1) {
      playNewNote(time);
    } else {
      changeCurrentNote(time);
    }
  };

  const keyboardUp = function(keyUp, time = audioCtx.currentTime) {
    if (sequencerPlaying) { return; }
    let octaveOffset = (patch.octave - 3) * 12;
    keysDown = keysDown.filter(key => key !== keyMidiMap[keyUp.keyCode] + octaveOffset);

    if (keysDown.length > 0) {
      notePlaying.setValueAtTime(keysDown[keysDown.length - 1], time);

      changeCurrentNote(time);

      return;
    }

    stopNote(time);
  };

  const stopNote = function(time = audioCtx.currentTime) {
    // console.log('QDEBUG:', time - debugNewNote);
    const currentValue = ampEgGainParam.getValueAtTime(time);

    // If note is already off, don't bother stopping it.
    if (currentValue === 0) { return; }

    if (patch.ampEgOn) {
      if (patch.sustainOn || (time < attackEndTime.getValueAtTime(time))) {

        // filter envelope
        filterEgOffsetParam.cancelAndHoldAtTime(time);

        // TODO: Use custom curve for filter?
        filterEgOffsetParam.linearRampToValueAtTime(
          0,
          time + (patch.envelope.decayRelease * patch.filterEgCoefficient * currentValue)
        );

        // Amp eg
        ampEgGainParam.cancelAndHoldAtTime(time);

        const duration = currentValue * patch.envelope.decayRelease;

        if (browserFeatures['customCurveClearing'] && !sequencerPlaying) {
          // custom curve
          const gainCurve = decayReleaseGainCurve.map(
            function(value) { return value * currentValue }
          );
          ampEgGainParam.setValueCurveAtTime(gainCurve, time, duration);
        } else {
          ampEgGainParam.linearRampToValueAtTime(0, time + duration);
        }
      }

    } else {
      // Filter cutoff down immediately
      filterEg.offset.cancelScheduledValues(time);
      filterEg.offset.setValueAtTime(0, time);

      // Turn amp down immediately
      ampEgGainParam.setValueAtTime(1, time);
      ampEgGainParam.linearRampToValueAtTime(0, time + builtInDecay);
    }
  };


  // ===================================
  //  Sequencer experiment
  // ===================================

  const runToneSequencer = function(){
    Tone.Transport.bpm.value = patch.tempo;

    // This is needed for when tempo is changed before the sequencer starts.
    try {
      Tone.getTransport().bpm.rampTo(patch.tempo, 0.0001);
    } catch (error) {
      // idc
    }

    let i = 0;
    let previousStep;

    Tone.Transport.scheduleRepeat(time => {
      if (!sequencerPlaying) { return; }

      while (!sequence[i % 16].activeStep) {
        // Bail out if all steps are inactive
        if (!sequence.some(step => { return step.activeStep })) { return; }
        i++;
      }

      const gateEnd = time + 0.58 * (60 / (patch.tempo * 4));

      let currentStep = sequence[i % 16];
      notePlaying.setValueAtTime(currentStep['note'], time);

      if (currentStep['stepMode']) {
        if (i > 0 && previousStep['slide']) {
          if (i > 0 && previousStep['stepMode']) {
            changeCurrentNote(time);
          } else {
            // Play a new note when last step stop mode was off
            playNewNote(time);
            if (!currentStep['slide']) {
              stopNote(gateEnd);
            }
          }
        } else {
          playNewNote(time);
          if (!currentStep['slide']) {
            stopNote(gateEnd);
          }
        }
      }

      previousStep = currentStep;
      i++;
    }, '16n');
  };

  runToneSequencer();

  const activateAudio = function() {
    if (audioCtx.state === 'running') { return; }

    audioCtx.resume().then(() => {
      Tone.context.resume();
      Tone.start();
    });
  };

  $('#play').on('click tap', function() {
    activateAudio();
    $('#stop').toggleClass('hidden');
    if (sequencerPlaying) {
      // STOP
      Tone.Transport.stop();
      stopNote(Tone.now() + 0.2);
      sequencerPlaying = false;
    } else {
      // START
      sequencerPlaying = true;
      Tone.Transport.start('+0');
    }
  });

  // ===================================
  //  END Sequencer experiment
  // ===================================

  window.onkeydown = function(keyDown) {
    if (keyDown.repeat) { return; }

    // PLAY NOTES
    if (keyCodes.includes(keyDown.keyCode)) {
      let octaveOffset = (patch.octave - 3) * 12;
      notePlaying.setValueAtTime(keyMidiMap[keyDown.keyCode] + octaveOffset, audioCtx.currentTime);

      keyboardDown();
    }

    // CHANGE OCTAVE
    if (keyDown.keyCode == zKeyCode && patch.octave > -1) {
      patch.octave -= 1;
      changeOctave(-1);
    }
    if (keyDown.keyCode == xKeyCode && patch.octave < 9) {
      patch.octave += 1;
      changeOctave(1);
    }
  };

  window.onkeyup = function(keyUp) {
    if (keyCodes.includes(keyUp.keyCode)) {
      keyboardUp(keyUp);
    }
  };

  const doSequenceStuff = function() {
    if (VS.sequences.activeNote !== null) {
      const note = VS.sequences.activeNote.data('note');
      const index = VS.sequences.activeNote.data('index');
      sequence[index]['note'] = note;
    }
  };

  document.addEventListener('changesequencenote', doSequenceStuff);

  $('.sequence-holder').on('sequenceparamchange', '.sequence-box .slide label',
    function() {
      const light = $($(this).find('.light'));
      light.data('active', !light.data('active'));
      const index = light.data('index');
      sequence[index]['slide'] = light.data('active');
    }
  );

  $('.sequence-holder').on('sequenceparamchange', '.sequence-box .step-mode label',
    function() {
      const light = $($(this).find('.light'));
      light.data('active', !light.data('active'));
      const index = light.data('index');
      sequence[index]['stepMode'] = light.data('active');
    }
  );

  $('.sequence-holder').on('sequenceparamchange', '.sequence-box .active-step label',
    function() {
      const light = $($(this).find('.light'));
      light.data('active', !light.data('active'));
      const index = light.data('index');
      sequence[index]['activeStep'] = light.data('active');
    }
  );

  $('#tempo').on('knobturn', () => {
    midiValue = VS.activeKnob.jElement.data('superMidi');
    patch.settempo(midiValue);

    // this is needed to change loop interval
    Tone.Transport.bpm.value = patch.tempo;
    // This is needed to change tempo relative timing of gateEnd
    try {
      Tone.getTransport().bpm.rampTo(patch.tempo, 0.0001);
    } catch (error) {
      // idc
    }
  });

  ['attack', 'decay_release'].forEach(id => {
    $(`#${id}`).on('knobturn', () => {
      patch[`set${id}`](VS.activeKnob.trueMidi());
    });
  });

  $('#cutoff_eg_int').on('knobturn', () => {
    patch.setcutoff_eg_int(VS.activeKnob.trueMidi());

    filterEgAmp.gain.setValueAtTime(
      patch.envelope.cutoffEgInt,
      audioCtx.currentTime
    );
  });

  $('#peak').on('knobturn', () => {
    patch.setpeak(VS.activeKnob.trueMidi());
    filter.Q.value = patch.filter.peak;
  });

  $('#cutoff').on('knobturn', () => {
    patch.setcutoff(VS.activeKnob.trueMidi());
    filter.frequency.setValueAtTime(patch.filter.cutoff, audioCtx.currentTime);
  });

  $('#lfo_rate').on('knobturn', () => {
    patch.setlfo_rate(VS.activeKnob.trueMidi());
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, audioCtx.currentTime);
  });

  $('#lfo_int').on('knobturn', () => {
    patch.setlfo_int(VS.activeKnob.trueMidi());

    // TODO: Think about calling setAmpLfoPitchGain() here maybe.  And for others.
    if (patch.lfo.targetPitch) {
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, audioCtx.currentTime);
    }

    if (patch.lfo.targetCutoff) {
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, audioCtx.currentTime);
    }

    if (patch.lfo.targetAmp) {
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, audioCtx.currentTime);
    }
  });

  [1, 2, 3].forEach(oscNumber => {
    $(`#vco${oscNumber}_pitch`).on('knobturn', () => {
      patch[`setvco${oscNumber}_pitch`](VS.activeKnob.midi());

      osc[oscNumber].detune.setValueAtTime(
        patch.vco[oscNumber].detune, audioCtx.currentTime
      );
    });
  });

  $('#volume').on('knobturn', () => {
    patch.setvolume(VS.activeKnob.midi());
    masterAmp.gain.setValueAtTime(patch.volume, audioCtx.currentTime);
  });

  const toggleVcoAmp = function(oscNumber) {
    if (patch.vco[oscNumber].amp == defaultVcoAmp) {
      patch.vco[oscNumber].amp = 0;
    } else {
      patch.vco[oscNumber].amp = defaultVcoAmp;
    }
    oscMuteAmps[oscNumber].gain.setValueAtTime(
      patch.vco[oscNumber].amp, audioCtx.currentTime
    );
  };

  // VCO MUTE BUTTONS
  [1, 2, 3].forEach(function(oscNumber) {
    $(`#vco${oscNumber}_active_button`).on('click tap', function(){
      toggleVcoAmp(oscNumber);
    });
  });

  // LFO TARGET AMP
  $('label[for="patch_lfo_target_amp"]').on('click tap', function() {
    patch.lfo.targetAmp = !patch.lfo.targetAmp;
    setAmpLfoAmpGain();
  });

  // LFO TARGET PITCH
  $('label[for="patch_lfo_target_pitch"]').on('click tap', function() {
    patch.lfo.targetPitch = !patch.lfo.targetPitch;
    setAmpLfoPitchGain();
  });

  // LFO TARGET CUTOFF
  $('label[for="patch_lfo_target_cutoff"]').on('click tap', function() {
    patch.lfo.targetCutoff = !patch.lfo.targetCutoff;
    setAmpLfoCutoffGain();
  });

  // LFO WAVE
  $('label[for="patch_lfo_wave"]').on('click tap', function() {
     if (patch.lfo.shape == 'triangle') {
       patch.setlfo_wave('square');
     } else {
       patch.setlfo_wave('triangle');
    }
    oscLfo.type = patch.lfo.shape;
  });

  const toggleVcoWave = function(osc, vco) {
     if (vco.shape == 'sawtooth') {
       vco.shape = 'square';
     } else {
       vco.shape = 'sawtooth';
     }
     if (osc !== null) {
       osc.type = vco.shape;
     }
  };

  // VCO WAVE
  [1, 2, 3].forEach(function(oscNumber){
    $(`label[for="patch_vco${oscNumber}_wave"]`).on('click tap', function() {
      toggleVcoWave(osc[oscNumber], patch.vco[oscNumber]);
    });
  });

  $('label[for="patch_sustain_on"]').on('click tap', function() {
    patch.sustainOn = !patch.sustainOn;
  });

  $('label[for="patch_amp_eg_on"]').on('click tap', function() {
    patch.ampEgOn = !patch.ampEgOn;
  });

  const clearSlide = function () {
    $('.slide:visible .light').each(function() {
      let light = $(this);
      if (light.data('active')) {
        light.data('active', false);
        light.removeClass('lit');
        sequence[light.data('index')]['slide'] = false;
      }
    });
  };

  const clearActiveStep = function() {
    $('.active-step:visible .light').each(function() {
      const light = $(this);
      if (!light.data('active')) {
        light.data('active', true);
        light.addClass('lit');
        sequence[light.data('index')].activeStep = true;
      }
    });
  };

  const clearNotes = function() {
    $('.note:visible span').each(function() {
      const el = $(this);
      el.html('C3');
      el.data('starting-note', 60);
      sequence[el.data('index')].note = 60;
    });
  };

  const clearStepMode = function() {
    $('.step-mode:visible .light').each(function() {
      const light = $(this);
      if (!light.data('active')) {
        light.data('active', true);
        light.addClass('lit');
        sequence[light.data('index')].stepMode = true;
      }
    });
  };

  $('#clear-slide').on('click tap', clearSlide);

  $('#clear-active-step').on('click tap', clearActiveStep);

  $('#clear-part').on('click tap', function() {
    clearNotes();
    clearSlide();
    clearStepMode();
    clearActiveStep();
  });

  // MOBILE OCTAVE UP
  $('#octave-up').on('click tap', function(){
    if (patch.octave < 9) {
      patch.octave += 1;
    }
    changeOctave(1);
  });

  // MOBILE OCTAVE DOWN
  $('#octave-down').on('click tap', function(){
    if (patch.octave > -1) {
      patch.octave -= 1;
    }
    changeOctave(-1);
  });

  // MOBILE KEY
  $('.mobile-control.key').on('mousedown touchstart', function(e) {
    let octaveOffset = (patch.octave - 3) * 12;
    notePlaying.setValueAtTime(keyMidiMap[$(this).data('keycode')] + octaveOffset, audioCtx.currentTime);

    keyboardDown();
  });

  $('.mobile-control.key').on('mouseup touchend mouseleave', function() {
    keyboardUp({ keyCode: $(this).data('keycode') });
  });

  // TOOLTIPS
  const itemsComingSoon = [
    'label[for="patch_vco_group_one"]',
    'label[for="patch_vco_group_two"]'
  ];

  itemsComingSoon.forEach(function(selector) {
    $(selector).mouseenter(function() {
      if (VS.dragging) { return; }
      $('.cooltip').text("Coming soon!");
      $('.cooltip').show();
    });
  });

  itemsComingSoon.forEach(function(selector) {
    $(selector).mouseleave(function() {
      $('.cooltip').hide();
    });
  });

  $('#octave').mouseenter(function() {
    $('.cooltip').text("Press 'Z' or 'X' to change octaves");
    $('.cooltip').show();
  });

  $('#octave').mouseleave(function() {
    $('.cooltip').hide();
  });

  $('#toggle-mobile').on('click tap', function(e) {
    e.preventDefault();
    $('#mobile-keyboard').removeClass('hidden');
    $('#back-to-desktop').removeClass('hidden');
    $('#desktop-instructions').hide();
  })

  $('#back-to-desktop a').on('click tap', function(e) {
    e.preventDefault();
    $('#mobile-keyboard').addClass('hidden');
    $('#back-to-desktop').addClass('hidden');
    $('#desktop-instructions').show();
  })
};
