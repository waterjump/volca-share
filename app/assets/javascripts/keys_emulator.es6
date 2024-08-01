VS.KeysEmulator = function() {
  const { emulatorConstants, emulatorParams } = VS;
  const patch = emulatorParams;

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

  let keysDown = [];

  const audioEngine = new VS.KeysAudioEngine(emulatorParams);
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

  // this is how to auto-rotate knobs
  $('.knob').each(function() {
    new VS.Knob(this).setKnob($(this).data('midi'));
  });

  // NOTE: This message will not be used by the sequencer.
  const changeOctave = function(change) {
    VS.display.update(emulatorConstants.octaveMap[patch.octave], 'noteString');

    // Turn octave knob
    new VS.Knob($('#octave')).setKnob(emulatorConstants.darkOctaveKnobMidiMap[patch.octave]);

    if (audioEngine.getNotePlaying() === undefined) { return; } // at init time

    if (keysDown.length === 0) { return; } // when it's amp_eg release

    // Transpose all keys held down to new octave
    const octaveOffset = change * 12;
    keysDown = keysDown.map(key => key + octaveOffset);

    audioEngine.changeOctave(octaveOffset);
  }

  changeOctave(0);

  const keyboardDown = function(){
    if (audioEngine.getSequencerPlaying()) { return; }
    if (keysDown.indexOf(audioEngine.getNotePlaying()) === -1) {
      keysDown.push(audioEngine.getNotePlaying());
    }

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

  // Stop audio if user switches browser tab or minimizes window
  document.addEventListener('visibilitychange', function() {
    if (document.hidden && !audioEngine.getSequencerPlaying()) {
      audioEngine.stopNote();
    }
  });

  $('#tempo').on('knobturn', () => {
    midiValue = VS.activeKnob.jElement.data('superMidi');
    patch.settempo(midiValue);
    audioEngine.setTempo();
  });

  ['attack', 'decay_release', 'portamento'].forEach(id => {
    $(`#${id}`).on('knobturn', () => {
      patch[`set${id}`](VS.activeKnob.trueMidi());
    });
  });

  $('#voice').on('knobturn', () => {
    patch.setvoice(VS.activeKnob.midi());
    // TODO: set voice in audioEngine;
  });

  $('#vcf_eg_int').on('knobturn', () => {
    patch.setcutoff_eg_int(VS.activeKnob.trueMidi());
    audioEngine.setFilterEgInt(patch.vcf_eg_int);
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

  // LFO PITCH INT
  document.getElementById('lfo_pitch_int').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetAmp = !patch.lfo.targetAmp;
      audioEngine.setAmpLfoAmpGain();
    }
  );

  // LFO CUTOFF INT
  document.getElementById('lfo_cutoff_int').addEventListener(
    'change',
    function(event) {
      patch.lfo.targetPitch = !patch.lfo.targetPitch;
      audioEngine.setAmpLfoPitchGain();
    }
  );

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
