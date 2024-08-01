VS.BassEmulator = function() {
  const { sequences, emulatorConstants, emulatorParams } = VS;
  const patch = emulatorParams;
  const sequence = [];

  this.getSequence = function() {
    return sequence;
  };

  // TODO: Don't base sequence object on DOM state!!
  //   Set a default sequence object
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

  const audioEngine = new VS.AudioEngine(emulatorParams, sequence);
  audioEngine.init();

  const showPerformanceWarning = () => {
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

  if (audioEngine.showPerformanceWarning()) {
    // showPerformanceWarning();
  }

  let debugNewNote;

  // NOTE: This message will not be used by the sequencer.
  const changeOctave = function(change) {
    VS.display.update(emulatorConstants.octaveMap[patch.octave], 'noteString');

    // Turn octave knob
    new VS.Knob($('#octave')).setKnob(emulatorConstants.octaveKnobMidiMap[patch.octave]);

    if (audioEngine.getNotePlaying() === undefined) { return; } // at init time

    if (keysDown.length === 0) { return; } // when it's amp_eg release

    // Transpose all keys held down to new octave
    const octaveOffset = change * 12;
    keysDown = keysDown.map(key => key + octaveOffset);

    audioEngine.changeOctave(octaveOffset);
  }

  changeOctave(0);
  sequences.init();

  const stepRecordNote = (skip = false) => {
    if (!patch.stepRecEnabled) { return; }

    // set sequence note at stepRecIndex to audioEngine.notePlaying
    if (skip) {
      sequence[patch.stepRecIndex - 1]['stepMode'] = false;
    } else {
      sequence[patch.stepRecIndex - 1]['note'] =
        audioEngine.getNotePlaying();
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

  const keyboardDown = function(){
    if (audioEngine.getSequencerPlaying()) { return; }
    if (keysDown.indexOf(audioEngine.getNotePlaying()) === -1) {
      keysDown.push(audioEngine.getNotePlaying());
    }

    stepRecordNote();

    if (keysDown.length === 1) {
      audioEngine.playNewNote();
    } else {
      audioEngine.changeCurrentNote();
    }
  };

  // This transposes keycode based on octave
  const octaveAdjustedKeyCode = (keycode) => {
    const octaveOffset = (patch.octave - 3) * 12;
    return emulatorConstants.keyMidiMap[keycode] + octaveOffset;
  };

  const keyboardUp = function(keyUp) {
    if (audioEngine.getSequencerPlaying()) { return; }
    keysDown = keysDown.filter(key => key !== octaveAdjustedKeyCode(keyUp.keyCode));

    if (keysDown.length > 0) {
      audioEngine.setNotePlaying(keysDown[keysDown.length - 1]);
      audioEngine.changeCurrentNote();

      return;
    }

    audioEngine.stopNote();
  };

  $('#play').on('click tap', function() {
    audioEngine.activateAudio();
    $('#stop').toggleClass('hidden');
    if (audioEngine.getSequencerPlaying()) {
      // STOP
      macroStopSequencer();
    } else {
      // START
      audioEngine.startSequencer();
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
    if (!audioEngine.getSequencerPlaying()) { return; }

    audioEngine.stopSequencer();
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

  const macroOctaveUp = () => {
    if (patch.octave >= 9) { return }

    patch.octave += 1;
    changeOctave(1);
  };

  const macroOctaveDown = () => {
    if (patch.octave <= -1) { return }

    patch.octave -= 1;
    changeOctave(-1);
  };

  window.onkeydown = function(keyDown) {
    if (keyDown.repeat) { return; }

    // PLAY NOTES
    if (emulatorConstants.keyCodes.includes(keyDown.keyCode)) {
      audioEngine.setNotePlaying(octaveAdjustedKeyCode(keyDown.keyCode));

      keyboardDown();
    }

    // CHANGE OCTAVE
    if (keyDown.keyCode == emulatorConstants.zKeyCode) { macroOctaveDown() }
    if (keyDown.keyCode == emulatorConstants.xKeyCode) { macroOctaveUp() }
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
    if (document.hidden && !audioEngine.getSequencerPlaying()) {
      audioEngine.stopNote();
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
    audioEngine.setTempo();
  });

  ['attack', 'decay_release'].forEach(id => {
    $(`#${id}`).on('knobturn', () => {
      patch[`set${id}`](VS.activeKnob.trueMidi());
    });
  });

  $('#cutoff_eg_int').on('knobturn', () => {
    patch.setcutoff_eg_int(VS.activeKnob.trueMidi());
    audioEngine.setFilterEgInt(patch.envelope.cutoffEgInt);
  });

  $('#peak').on('knobturn', () => {
    patch.setpeak(VS.activeKnob.trueMidi());
    audioEngine.setPeak(patch.filter.peak);
  });

  $('#cutoff').on('knobturn', () => {
    patch.setcutoff(VS.activeKnob.trueMidi());
    audioEngine.setCutoff(patch.filter.cutoff);
  });

  $('#lfo_rate').on('knobturn', () => {
    patch.setlfo_rate(VS.activeKnob.trueMidi());
    audioEngine.setLfoRate(patch.lfo.frequency);
  });

  $('#lfo_int').on('knobturn', () => {
    patch.setlfo_int(VS.activeKnob.trueMidi());
    audioEngine.setLfoInt();
  });

  [1, 2, 3].forEach(oscNumber => {
    $(`#vco${oscNumber}_pitch`).on('knobturn', () => {
      patch[`setvco${oscNumber}_pitch`](VS.activeKnob.midi());
      audioEngine.setOscPitch(oscNumber, patch.vco[oscNumber].detune);
    });
  });

  $('#volume').on('knobturn', () => {
    patch.setvolume(VS.activeKnob.midi());
    audioEngine.setVolume(patch.volume);
  });

  const toggleVcoAmp = function(oscNumber) {
    patch.toggleVcoAmp(oscNumber);
    audioEngine.setOscMuteAmp(oscNumber, patch.vco[oscNumber].amp);
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
      audioEngine.setAmpLfoAmpGain();
    }
  );

  // LFO TARGET PITCH
  document.getElementById('patch_lfo_target_pitch').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetPitch = !patch.lfo.targetPitch;
      audioEngine.setAmpLfoPitchGain();
    }
  );

  // LFO TARGET CUTOFF
  document.getElementById('patch_lfo_target_cutoff').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetCutoff = !patch.lfo.targetCutoff;
      audioEngine.setAmpLfoCutoffGain();
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
      audioEngine.setLfoWave(patch.lfo.shape);
    }
  );

  const toggleVcoWave = (index) => {
    const vcoShape = patch.vco[index].shape;
    let newShape = vcoShape == 'sawtooth' ? 'square' : 'sawtooth';
    patch.vco[index].shape = newShape;
    if (audioEngine.getOsc[index] !== null) {
      audioEngine.setOscShape(index, newShape);
    }
  };

  // VCO WAVE
  [1, 2, 3].forEach(function(oscNumber){
    document.getElementById(`patch_vco${oscNumber}_wave`).addEventListener(
      'change',
      function(event) {
        toggleVcoWave(oscNumber);
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
  $('#octave-up').on('click tap', function() { macroOctaveUp() });

  // MOBILE OCTAVE DOWN
  $('#octave-down').on('click tap', function() { macroOctaveDown() });

  // MOBILE KEY
  $('.mobile-control.key').on('mousedown touchstart', function(e) {
    audioEngine.setNotePlaying(octaveAdjustedKeyCode($(this).data('keycode')));

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
