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

  // ==================================
  // START QUERY STRING
  // ==================================
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
      'voice', 'detune', 'portamento', 'vco_eg_int', 'attack', 'decay_release',
      'vcf_eg_int', 'octave', 'peak', 'cutoff', 'sustain', 'lfo_rate',
      'lfo_pitch_int', 'lfo_cutoff_int', 'delay_time', 'delay_feedback'
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

    const qsBooleanParameters = ['lfo_trigger_sync'];

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
    const rawValue = urlParams.get('lfo_shape');
    if (['triangle', 'square', 'saw'].indexOf(rawValue) !== -1) {
      const adjustedValue = rawValue === 'saw' ? 'sawtooth' : rawValue;
      patch.setlfo_wave(adjustedValue);

      volcaInterface.unlightAndUncheck('lfo_shape_square');
      volcaInterface.unlightAndUncheck('lfo_shape_triangle');
      volcaInterface.unlightAndUncheck('lfo_shape_saw');

      switch (rawValue) {
        case 'square':
          volcaInterface.lightAndCheck('lfo_shape_square');
          break;
        case 'triangle':
          volcaInterface.lightAndCheck('lfo_shape_triangle');
          break;
        case 'saw':
          volcaInterface.lightAndCheck('lfo_shape_saw');
          break;
      }
    }
  };

  processQueryString();

  // =======================
  // END query string params
  // =======================

  let keysDown = [];

  const audioEngine = new VS.KeysAudioEngine(emulatorParams);
  audioEngine.init();

  const showPerformanceWarning = () => {
    $('#performance-warning').html(
      '<button type="button" class="close" data-dismiss="alert" aria-label="Close">' +
      '<span aria-hidden="true">&times;</span></button>' +
      '<strong>Just a heads up: </strong><br />' +
      'There are known performance issues with this browser.' +
      'For best results, use a <a class="alert-link" target="_blank" ' +
      'href="https://caniuse.com/mdn-api_audioparam_cancelandholdattime">' +
      'supported browser.</a>'
    );
    $('#performance-warning').removeClass('hidden');
  };

  if (audioEngine.showPerformanceWarning()) {
    // showPerformanceWarning();
  }

  // this is how to auto-rotate knobs
  $('.knob').each(function() {
    new VS.Knob(this).setKnob($(this).data('midi'));
  });

  const changeOctave = function(change, keyStroke = true) {
    VS.display.update(emulatorConstants.octaveMap[patch.octave], 'noteString');

    if (keyStroke) {
      // Turn octave knob
      new VS.Knob($('#octave')).setKnob(emulatorConstants.darkOctaveKnobMidiMap[patch.octave]);

      if (!audioEngine.noteIsPlaying()) { return; } // at init time
    }

    if (keysDown.length === 0) { return; } // when it's amp_eg release

    // Transpose all keys held down to new octave
    const octaveOffset = change * 12;
    keysDown = keysDown.map(key => key + octaveOffset);

    audioEngine.changeOctave(octaveOffset);
  }

  changeOctave(0);

  const keyboardDown = function(note){
    keysDown.push(note);
    // if (keysDown.indexOf(audioEngine.getNotePlaying()) === -1) {
    //  keysDown.push(audioEngine.getNotePlaying());
    // }

    if (keysDown.length === 1) {
      audioEngine.playNewNote(note);
    } else if (patch.voice.includes('poly')){
      audioEngine.addNote(keysDown);
    } else {
      audioEngine.changeCurrentNote(note);
    }
  };

  // This transposes keycode based on octave
  const octaveAdjustedKeyCode = (keycode) => {
    const octaveOffset = (patch.octave - 3) * 12;
    return emulatorConstants.keyMidiMap[keycode] + octaveOffset;
  };

  const keyboardUp = function(noteThatStopped) {
    keysDown = keysDown.filter(key => key !== noteThatStopped);

    if (keysDown.length > 0) {
      if (patch.voice.includes('poly')) {
        audioEngine.stopPolyNote(keysDown, noteThatStopped);
        return;
      } else {
        audioEngine.changeCurrentNote(keysDown[keysDown.length - 1]);
        return;
      }
    }

    audioEngine.stopPolyNote(keysDown, noteThatStopped);
    audioEngine.stopNote();
  };

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
      const adjustedKeyDown = octaveAdjustedKeyCode(keyDown.keyCode);
      keyboardDown(adjustedKeyDown);
    }

    // CHANGE OCTAVE
    if (keyDown.keyCode == emulatorConstants.zKeyCode) { macroOctaveDown() }
    if (keyDown.keyCode == emulatorConstants.xKeyCode) { macroOctaveUp() }
  };

  window.onkeyup = function(keyUp) {
    if (emulatorConstants.keyCodes.includes(keyUp.keyCode)) {
      const adjustedKeyUp = octaveAdjustedKeyCode(keyUp.keyCode);
      keyboardUp(adjustedKeyUp);
    }
  };

  // Stop audio if user switches browser tab or minimizes window
  document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
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

  $('#sustain').on('knobturn', () => {
    patch.setsustain(VS.activeKnob.trueMidi());
    audioEngine.setSustain();
  });

  $('#vco_eg_int').on('knobturn', () => {
    patch.setvco_eg_int(VS.activeKnob.trueMidi());
    audioEngine.setVcoEgInt();
  });

  $('#delay_time').on('knobturn', () => {
    patch.setdelay_time(VS.activeKnob.trueMidi());
    audioEngine.setDelayTime();
  });

  $('#delay_feedback').on('knobturn', () => {
    patch.setdelay_feedback(VS.activeKnob.trueMidi());
    audioEngine.setDelayFeedback();
  });

  $('#detune').on('knobturn', () => {
    patch.setdetune(VS.activeKnob.trueMidi());
    audioEngine.setDetune();
  });

  $('#voice').on('knobturn', () => {
    patch.setvoice(VS.activeKnob.midi());
    audioEngine.changeVoice();
  });

 $('#octave').on('knobturn', () => {
   const startingOctave = patch.octave;
   patch.setoctave(VS.activeKnob.midi());

   const octaveDifference = patch.octave - startingOctave;
   changeOctave(octaveDifference, false);
 });

  $('#vcf_eg_int').on('knobturn', () => {
    patch.setvcf_eg_int(VS.activeKnob.trueMidi());
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

  $('#lfo_pitch_int').on('knobturn', () => {
    patch.setlfo_pitch_int(VS.activeKnob.trueMidi());
    audioEngine.setLfoPitchInt();
  });

  $('#lfo_cutoff_int').on('knobturn', () => {
    patch.setlfo_cutoff_int(VS.activeKnob.trueMidi());
    audioEngine.setLfoCutoffInt();
  });

  $('#volume').on('knobturn', () => {
    patch.setvolume(VS.activeKnob.midi());
    audioEngine.setVolume(patch.volume);
  });

  $(document).on('midinoteon', function(event) {
    keyboardDown(event.detail.number);
  });

  $(document).on('midinoteoff', function(event) {
    keyboardUp(event.detail.number);
  });

  const getShapeFromLfoLightClick = function(el) {
    return $('#' + $(el).closest('label').attr('for')).val();
  };

  lfoControlSelectors = [
    'label[for="patch_lfo_shape_saw"] span.multi',
    'label[for="patch_lfo_shape_triangle"] span.multi',
    'label[for="patch_lfo_shape_square"] span.multi'
  ];

  lfoControlSelectors.forEach(function(selector) {
    $(selector).on('click tap', function(event) {
      let shape = getShapeFromLfoLightClick(this);
      shape = shape === 'saw' ? 'sawtooth' : shape;
      if (shape === patch.lfo.shape) { return; }

      patch.lfo.shape = shape;
      audioEngine.setLfoWave();
    });
  });

  $('label[for="patch_lfo_trigger_sync"] span.on-off').on( 'click tap', () => {
    patch.setlfo_trigger_sync();
  });

  // MOBILE OCTAVE UP
  $('#octave-up').on('click tap', function() { macroOctaveUp() });

  // MOBILE OCTAVE DOWN
  $('#octave-down').on('click tap', function() { macroOctaveDown() });

  // MOBILE KEY
  $('.mobile-control.key').on('mousedown touchstart', function(e) {
    const note = octaveAdjustedKeyCode($(this).data('keycode'))
    keyboardDown(note);
  });

  $('.mobile-control.key').on('mouseup touchend mouseleave', function() {
    const adjustedKeyUp = octaveAdjustedKeyCode($(this).data('keycode'));
    keyboardUp(adjustedKeyUp);
  });

  $('.keyboard-notice').on('mousedown touchstart', () => {
    $('#keyboard-tip').show();
  });

  $('.keyboard-notice').on('mouseup touchend', () => {
    $('#keyboard-tip').fadeOut(3000);
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

  $('.bottom-row .multi').on('click tap', function() {
    $('.light[data-radio]').each(function() {
      $(this).removeClass('lit');
    });
    $(this).find('.light').addClass('lit');
  });
};
