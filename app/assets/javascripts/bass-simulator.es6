VS.BassSimulator = function() {
  const myp = new p5(function(p) {
    const audioCtx = new AudioContext();

    let masterAmp = audioCtx.createGain();
    masterAmp.connect(audioCtx.destination);

    const filter = audioCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.connect(masterAmp);

    let osc1Amp = audioCtx.createGain()
    osc1Amp.gain.value = 0.33;
    osc1Amp.connect(filter);
    let osc2Amp = audioCtx.createGain()
    osc2Amp.gain.value = 0.33;
    osc2Amp.connect(filter);
    let osc3Amp = audioCtx.createGain()
    osc3Amp.gain.value = 0.33;
    osc3Amp.connect(filter);

    const oscAmp = [null, osc1Amp, osc2Amp, osc3Amp];

    let osc = [null, null, null, null];

    const ampLfoPitch = audioCtx.createGain()
    ampLfoPitch.gain.value = 0;

    const ampLfoCutoff = audioCtx.createGain()
    ampLfoCutoff.gain.value = 2500;
    ampLfoCutoff.connect(filter.frequency);

    const oscLfo = audioCtx.createOscillator();
    oscLfo.type = 'triangle';
    oscLfo.frequency.setValueAtTime(1, audioCtx.currentTime);
    oscLfo.connect(ampLfoPitch);
    oscLfo.connect(ampLfoCutoff);
    oscLfo.start();

    let octave = 3;

    let vco = [
      null,
      { shape: 'sawtooth', amp: 1, pitchMidi: 63, frequency: 440, detune: 0 },
      { shape: 'sawtooth', amp: 1, pitchMidi: 63, frequency: 440, detune: 0 },
      { shape: 'square', amp: 1, pitchMidi: 63, frequency: 440, detune: 0 }
    ];

    let lfo = {
      shape: 'triangle',
      targetAmp: false,
      targetPitch: false,
      targetCutoff: true,
      ampValue: 69, // TODO: Change me
      pitchValue: 500,
      cutoffValue: 2500
    }
    let filterData = { cutoff: 20000 }

    let notePlaying;

    const keyMap = {
      65: 130.81, // C
      87: 138.59, // C#
      83: 146.83, // D
      69: 155.56, // D#
      68: 164.81, // E
      70: 174.61, // F
      84: 185.00, // F#
      71: 196.00, // G
      89: 207.65, // G#
      72: 220.00, // A
      85: 233.08, // A#
      74: 246.94, // B
      75: 261.63, // C
      76: 277.18 // C#
    }

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
      "-1": { displayNumber: 8, frequencyFactor: 0.0625 },
      0: { displayNumber: 9, frequencyFactor: 0.125 },
      1: { displayNumber: 21, frequencyFactor: 0.25 },
      2: { displayNumber: 33, frequencyFactor: 0.5 },
      3: { displayNumber: 45, frequencyFactor: 1 },
      4: { displayNumber: 57, frequencyFactor: 2 },
      5: { displayNumber: 69, frequencyFactor: 4 },
      6: { displayNumber: 81, frequencyFactor: 8 },
      7: { displayNumber: 93, frequencyFactor: 16 },
      8: { displayNumber: 105, frequencyFactor: 32 },
      9: { displayNumber: 118, frequencyFactor: 64 }
    }

    const keyCodes = Object.keys(keyMap).map(Number);

    p.setup = function() {
      console.log('p5 is running :-]');

      filter.frequency.setValueAtTime(filterData.cutoff, audioCtx.currentTime);
      filter.Q.value = 0;
    };

    p.draw = function() {
      // Keeping this for debugging purposes
    }

    const playNote = function(oscNumber){
      let oscillator = audioCtx.createOscillator();
      oscillator.type = vco[oscNumber].shape;
      oscillator.frequency.setValueAtTime(vco[oscNumber].frequency, audioCtx.currentTime); // value in hertz
      oscillator.detune.setValueAtTime(vco[oscNumber].detune, audioCtx.currentTime);

      osc[oscNumber] = oscillator;
      osc[oscNumber].connect(oscAmp[oscNumber]);
      ampLfoPitch.connect(osc[oscNumber].detune);
      osc[oscNumber].start();
    };

    const killNotes = function() {
      osc.forEach(function(oscillator, index) {
        if (oscillator !== null) {
          osc[index].stop();
          osc[index] = null;
        }
      });
    };

    p.keyPressed = function() {
      // PLAY NOTES
      if (keyCodes.includes(p.keyCode)) {
        notePlaying = p.keyCode;

        // stop other oscillators
        killNotes();

        // VCOs 1, 2, and 3
        [1, 2, 3].forEach(function(oscNumber) {
          vco[oscNumber].frequency =
            keyMap[notePlaying] *
            octaveMap[octave].frequencyFactor;
          playNote(oscNumber);
        });
      }

      // CHANGE OCTAVE
      if ([zKeyCode, xKeyCode].includes(p.keyCode)) {
        if (p.keyCode == zKeyCode && octave > -1) {
          octave -= 1;
        }
        if (p.keyCode == xKeyCode && octave < 9) {
          octave += 1;
        }

        VS.display.update(octaveMap[octave].displayNumber, 'noteString');
        osc.forEach(function(oscillator, oscNumber) {
          if (oscillator !== null) {
            vco[oscNumber].frequency =
              keyMap[notePlaying] *
              octaveMap[octave].frequencyFactor;

            osc[oscNumber].frequency.setValueAtTime(
              vco[oscNumber].frequency, audioCtx.currentTime
            );
          }
        });
      }
    };

    p.keyReleased = function() {
      if (p.keyIsPressed) { return; }
      killNotes();
    };

    $(document).on('mousemove touchmove', function(e) {
      if (VS.activeKnob === null) { return; }
      if (VS.dragging === false) { return; }
      let midiValue;

      // FILTER PEAK (RESONANCE)
      if (VS.activeKnob.element.id == 'peak') {
        let peak, percentage, peakAmount;

        peak = VS.activeKnob

        midiValue = $(peak.element).data('trueMidi');
        if (midiValue == undefined) { return; }

        percentage = midiValue / 127.0;
        peakAmount = (percentage * 30.0);

        filter.Q.value = peakAmount;
      }

      // FILTER CUTOFF
      if (VS.activeKnob.element.id == 'cutoff') {
        let cutoff, percentage;

        cutoff = VS.activeKnob

        midiValue = $(cutoff.element).data('trueMidi');
        if (midiValue == undefined) { return; }

        percentage = midiValue / 127.0;
        filterData.cutoff = 20 + (percentage**3 * 19980.0);

        filter.frequency.setValueAtTime(filterData.cutoff, audioCtx.currentTime);
      }

      // LFO RATE
      if (VS.activeKnob.element.id == 'lfo_rate') {
        let lfoRate, percentage, peakAmount;

        lfoRate = VS.activeKnob

        midiValue = $(lfoRate.element).data('trueMidi');
        if (midiValue == undefined) { return; }

        percentage = midiValue / 127.0;
        lfoRateValue = (percentage**3 * 35) + 0.1;

        oscLfo.frequency.setValueAtTime(lfoRateValue, audioCtx.currentTime);
      }

      // LFO INT
      if (VS.activeKnob.element.id == 'lfo_int') {
        let lfoInt, percentage, peakAmount;

        lfoInt = VS.activeKnob

        midiValue = $(lfoInt.element).data('trueMidi');
        if (midiValue == undefined) { return; }

        percentage = midiValue / 127.0;
        lfo.pitchValue = percentage * 1000;
        // TODO: Try to make audio not clip when filter cutoff is low
        lfo.cutoffValue = percentage**2 * 5000;

        if (lfo.targetPitch) {
          ampLfoPitch.gain.setValueAtTime(lfo.pitchValue, audioCtx.currentTime);
        }

        if (lfo.targetCutoff) {
          ampLfoCutoff.gain.setValueAtTime(lfo.cutoffValue, audioCtx.currentTime);
        }
      }

      // VCO PITCH KNOBS
      [1, 2, 3].forEach(function(oscNumber) {
        if (VS.activeKnob.element.id == `vco${oscNumber}_pitch`) {
          midiValue = $(VS.activeKnob.element).data('midi');
          if (midiValue == undefined) { return; }

          vco[oscNumber].pitchMidi = midiValue;
          vco[oscNumber].detune = pitchMap[vco[oscNumber].pitchMidi] * 100;

          if (osc[oscNumber] !== null) {
            osc[oscNumber].detune.setValueAtTime(
              vco[oscNumber].detune, audioCtx.currentTime
            );
          }
        }
      });
    });

    const toggleVcoAmp = function(oscNumber) {
      if (vco[oscNumber].amp == 1) {
        vco[oscNumber].amp = 0;
      } else {
        vco[oscNumber].amp = 1;
      }
      oscAmp[oscNumber].gain.setValueAtTime(vco[oscNumber].amp, audioCtx.currentTime);
    };

    // VCO MUTE BUTTONS
    [1, 2, 3].forEach(function(oscNumber) {
      $(`#vco${oscNumber}_active_button`).on('click tap', function(){
        toggleVcoAmp(oscNumber);
      });
    });

    // LFO TARGET PITCH
    $('label[for="patch_lfo_target_pitch"]').on('click tap', function() {
      lfo.targetPitch = !lfo.targetPitch;
      if (lfo.targetPitch) {
        // Affect pitch
        ampLfoPitch.gain.setValueAtTime(lfo.pitchValue, audioCtx.currentTime);
      } else {
        // Do not affect pitch
        ampLfoPitch.gain.setValueAtTime(0, audioCtx.currentTime);
      }
    });

    // LFO TARGET CUTOFF
    $('label[for="patch_lfo_target_cutoff"]').on('click tap', function() {
      lfo.targetCutoff = !lfo.targetCutoff;
      if (lfo.targetCutoff) {
        // Affect filter cutoff
        ampLfoCutoff.gain.setValueAtTime(lfo.cutoffValue, audioCtx.currentTime);
      } else {
        // Do not affect filter cutoff
        ampLfoCutoff.gain.setValueAtTime(0, audioCtx.currentTime);
      }
    });

    // LFO WAVE
    $('label[for="patch_lfo_wave"]').on('click tap', function() {
       if (lfo.shape == 'triangle') {
         lfo.shape = 'square';
       } else {
         lfo.shape = 'triangle';
      }
      oscLfo.type = lfo.shape;
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

    // VCO1 WAVE
    $('label[for="patch_vco1_wave"]').on('click tap', function() {
      toggleVcoWave(osc[1], vco[1]);
    });

    // VCO2 WAVE
    $('label[for="patch_vco2_wave"]').on('click tap', function() {
      toggleVcoWave(osc[2], vco[2]);
    });

    // VCO3 WAVE
    $('label[for="patch_vco3_wave"]').on('click tap', function() {
      toggleVcoWave(osc[3], vco[3]);
    });
  });
};
