VS.BassEmulator = function() {
  const { sequences, emulatorConstants, emulatorParams } = VS;

  const parameterMaps = {
    decayReleaseMap: emulatorConstants.decayReleaseMap,
    lfoRateMap: emulatorConstants.lfoRateMap
  };

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

  const patch = emulatorParams;

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

      let jStepModeLight = jElement.find('.step-mode .light');
      jStepModeLight.data('active', step.stepMode);
      jStepModeLight.removeClass(step.stepMode ? '' : 'lit');
      jStepModeLight.addClass(step.stepMode ? 'lit' : '');

      jElement.find('.active-step .light').data('active', step.activeStep);
      jElement.find('.active-step .light').removeClass(step.activeStep ? '' : 'lit');
    });
  };

  $('#toggle-sequences, #play, #record-button').on('click tap', function() {
    if (sequence.length === 0) {
      populateSequenceObject();
    }
    setSequenceView();
  });

  // BUTTON BLINK
  let blinkTimeout;

  const startBlink = (id) => {
    const elToBlink = $(id);
    elToBlink.toggleClass('lit unlit');
    const blink = () => {
      elToBlink.toggleClass('lit unlit');
      blinkTimeout = setTimeout(blink, 500);
    }
    blink();
  };

  const stopBlink = (id) => {
    clearTimeout(blinkTimeout);
    if ($(id).hasClass('lit')) { $(id).toggleClass('lit unlit'); }
  };

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

  // ==================================
  // START QUERY STRING
  // ==================================
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
          emulatorConstants.decayReleaseGainCurve,
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
    VS.display.update(emulatorConstants.octaveMap[patch.octave], 'noteString');

    // Turn octave knob
    new VS.Knob($('#octave')).setKnob(emulatorConstants.octaveKnobMidiMap[patch.octave]);

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

  const stepRecordNote = (skip = false) => {
    if (!patch.stepRecEnabled) { return; }

    // set sequence note at stepRecIndex to notePlaying
    if (skip) {
      sequence[patch.stepRecIndex - 1]['stepMode'] = false;
    } else {
      sequence[patch.stepRecIndex - 1]['note'] =
        notePlaying.getValueAtTime(audioCtx.currentTime);
      sequence[patch.stepRecIndex - 1]['stepMode'] = true;
    }

    // advance stepRecIndex
    if (patch.stepRecIndex === 16) {
      patch.stepRecIndex = 1;
    } else {
      patch.stepRecIndex++;
    }

    setSequenceView();
    $('.step.highlighted').removeClass('highlighted');
    $(`#step_${patch.stepRecIndex - 1}`).addClass('highlighted');

  }

  const keyboardDown = function(time = audioCtx.currentTime){
    if (sequencerPlaying) { return; }
    if (keysDown.indexOf(notePlaying.getValueAtTime(time)) === -1) {
      keysDown.push(notePlaying.getValueAtTime(time));
    }

    stepRecordNote();

    if (keysDown.length === 1) {
      playNewNote(time);
    } else {
      changeCurrentNote(time);
    }
  };

  const keyboardUp = function(keyUp, time = audioCtx.currentTime) {
    if (sequencerPlaying) { return; }
    let octaveOffset = (patch.octave - 3) * 12;
    keysDown = keysDown.filter(key => key !== emulatorConstants.keyMidiMap[keyUp.keyCode] + octaveOffset);

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
          const gainCurve = emulatorConstants.decayReleaseGainCurve.map(
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
      macroStopSequencer();
    } else {
      // START
      sequencerPlaying = true;
      Tone.Transport.start('+0');
      macroStepRecOff();
    }
  });

  const macroStepRecOn = () => {
    if (patch.stepRecEnabled) { return; }
    patch.stepRecEnabled = true;
    startBlink('#record-button');
    patch.stepRecIndex = 1;
    $('#skip-step').removeClass('hidden');
    $(`#step_${patch.stepRecIndex - 1}`).addClass('highlighted');
  };

  $('#skip-step').on('click tap', (e) => {
    stepRecordNote(true);
  });

  const macroStepRecOff = () => {
    if (!patch.stepRecEnabled) { return; }

    patch.stepRecEnabled = false;
    stopBlink('#record-button');
    $('.step.highlighted').removeClass('highlighted');
    let jRecButton = $('#record-button');
    if (jRecButton.hasClass('lit')) { jRecButton.toggleClass('lit unlit'); }
    $('#skip-step').addClass('hidden');
  };

  const macroStopSequencer = () => {
    if (!sequencerPlaying) { return; }

    Tone.Transport.stop();
    stopNote(Tone.now() + 0.2);
    sequencerPlaying = false;
    if ($('#play').hasClass('lit')) { $('#play').toggleClass('lit unlit'); }
    if (!$('#stop').hasClass('hidden')) { $('#stop').addClass('hidden'); }
  };

  $('#record-button').on('click tap', () => {
    macroStopSequencer();

    if (!patch.stepRecEnabled) {
      macroStepRecOn();
    } else {
      macroStepRecOff();
    }
  });

  // ===================================
  //  END Sequencer experiment
  // ===================================

  window.onkeydown = function(keyDown) {
    if (keyDown.repeat) { return; }

    // PLAY NOTES
    if (emulatorConstants.keyCodes.includes(keyDown.keyCode)) {
      let octaveOffset = (patch.octave - 3) * 12;
      notePlaying.setValueAtTime(
        emulatorConstants.keyMidiMap[keyDown.keyCode] + octaveOffset,
        audioCtx.currentTime
      );

      keyboardDown();
    }

    // CHANGE OCTAVE
    if (keyDown.keyCode == emulatorConstants.zKeyCode && patch.octave > -1) {
      patch.octave -= 1;
      changeOctave(-1);
    }
    if (keyDown.keyCode == emulatorConstants.xKeyCode && patch.octave < 9) {
      patch.octave += 1;
      changeOctave(1);
    }
  };

  window.onkeyup = function(keyUp) {
    if (emulatorConstants.keyCodes.includes(keyUp.keyCode)) {
      keyboardUp(keyUp);
    }
  };

  const setSequenceNote = function() {
    if (VS.sequences.activeNote !== null) {
      const note = VS.sequences.activeNote.data('note');
      const index = VS.sequences.activeNote.data('index');
      sequence[index]['note'] = note;
    }
  };

  document.addEventListener('changesequencenote', setSequenceNote);

  // Stop audio if user switches browser tab or minimizes window
  document.addEventListener('visibilitychange', function() {
    if (document.hidden && !sequencerPlaying) {
      stopNote();
    }
  });

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
    if (patch.vco[oscNumber].amp == patch.defaultVcoAmp) {
      patch.vco[oscNumber].amp = 0;
    } else {
      patch.vco[oscNumber].amp = patch.defaultVcoAmp;
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
  document.getElementById('patch_lfo_target_amp').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetAmp = !patch.lfo.targetAmp;
      setAmpLfoAmpGain();
    }
  );

  // LFO TARGET PITCH
  document.getElementById('patch_lfo_target_pitch').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetPitch = !patch.lfo.targetPitch;
      setAmpLfoPitchGain();
    }
  );

  // LFO TARGET CUTOFF
  document.getElementById('patch_lfo_target_cutoff').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetCutoff = !patch.lfo.targetCutoff;
      setAmpLfoCutoffGain();
    }
  );

  // LFO WAVE
  document.getElementById('patch_lfo_wave').addEventListener(
    'change',
    function(event) {
      if (patch.lfo.shape == 'triangle') {
        patch.setlfo_wave('square');
      } else {
        patch.setlfo_wave('triangle');
      }
      oscLfo.type = patch.lfo.shape;
    }
  );

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
    document.getElementById(`patch_vco${oscNumber}_wave`).addEventListener(
      'change',
      function(event) {
        toggleVcoWave(osc[oscNumber], patch.vco[oscNumber]);
      }
    );
  });

  // SUSTAIN ON
  document.getElementById('patch_sustain_on').addEventListener(
    'change',
    function(event) {
      patch.sustainOn = !patch.sustainOn;
    }
  );

  // AMP EG ON
  document.getElementById('patch_amp_eg_on').addEventListener(
    'change',
    function(event) {
      patch.ampEgOn = !patch.ampEgOn;
    }
  );

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
