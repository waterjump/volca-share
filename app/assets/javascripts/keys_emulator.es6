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

  let debugNewNote;

  // this is how to auto-rotate knobs
  $('.knob').each(function() {
    new VS.Knob(this).setKnob($(this).data('midi'));
  });

  const changeOctave = function(change) {
    VS.display.update(emulatorConstants.octaveMap[patch.octave], 'noteString');

    // Turn octave knob
    new VS.Knob($('#octave')).setKnob(emulatorConstants.darkOctaveKnobMidiMap[patch.octave]);

    if (!audioEngine.noteIsPlaying()) { return; } // at init time

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

  const keyboardUp = function(keyUp) {
    const noteThatStopped = octaveAdjustedKeyCode(keyUp.keyCode);
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
      keyboardUp(keyUp);
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

  // LFO WAVE
  $('#patch_lfo_shape_saw').on('change', function(event) {
    audioEngine.setLfoWave($(this).val());
  });

  // LFO WAVE
  $('#patch_lfo_shape_triangle').on('change', function(event) {
    audioEngine.setLfoWave($(this).val());
  });

  // LFO WAVE
  $('#patch_lfo_shape_square').on('change', function(event) {
    audioEngine.setLfoWave($(this).val());
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
    keyboardUp({ keyCode: $(this).data('keycode') });
  });

  // TOOLTIPS
  const itemsComingSoon = [
    '.scrim',
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

  $('.bottom-row .multi').on('click tap', function() {
    $('.light[data-radio]').each(function() {
      $(this).removeClass('lit');
    });
    $(this).find('.light').addClass('lit');
  });
};
