VS.Form = function() {
  // TODO do page specific scripts the right way
  const foo = [1,2,3];

  if ($('body.form').length === 0) { return; }
  const scope = this;
  let midi = undefined;
  const { midiOut } = VS;
  const { display } = VS;
  const limit = 140;
  const { sequences } = VS;

  //
  // initialize
  //

  const rotateKnobs = function() {
    $('.knob').each(function() {
      const myKnob = new VS.Knob(this);
      const degree = myKnob.degreeForMidi($(this).data('midi'), limit);
      $(this).data('rotation', degree);
      myKnob.autoRotate(degree);
    });
  };

  const init = function() {
    rotateKnobs();
    sequences.init();
  };

  init();

  //
  // user actions
  //
  // TODO DRY this up.
  $('#randomize').on('click tap', function(e) {
    e.preventDefault();

    const assignKnobValue = function(knob) {
      let randomValue;
      const snapKnobMidiValues = [10, 30, 50, 70, 100, 120];

      if ($(knob).hasClass('dark')) {
        randomValue =
          snapKnobMidiValues[
            Math.floor(Math.random() * snapKnobMidiValues.length)
          ];
      } else {
        randomValue = Math.floor(Math.random() * (127 - 1));
      }

      const myKnob = new VS.Knob(knob);
      const degree = myKnob.degreeForMidi(randomValue, limit);
      knob.data('rotation', degree);
      knob.data('midi', randomValue);
      myKnob.autoRotate(degree);
      myKnob.inputElement.val(randomValue);
    };

    const randomizeKnobs = function() {
      $('.volca .knob').each(function() {
        assignKnobValue($(this));
      });

      if (!midiOut.ready()) { return; }

      $('#midi-only-controls .knob').each(function() {
        assignKnobValue($(this));
      });
    };

    const randomizeVcoActive = function() {
      $('.button').each(function() {
        const vco = $(this).attr('id').split('_')[0];
        const randomBoolean = Math.random() >= 0.5;
        const input = $(`input#patch_${$(this).attr('id').split('_').slice(0, -1).join('_')}`);
        $(this).data('active', randomBoolean);
        const vcoKnob = $(`.knob#${vco}_pitch`);
        if (randomBoolean !== $(this).hasClass('lit')) {
          $(this).toggleClass('lit');
          vcoKnob.toggleClass('lit');
        }
        input.prop('checked', randomBoolean);
      });
    };

    const randomizeCheckboxes = function() {
      $('.bottom-row label').each(function() {
        if (!$(`input#${$(this).attr('for')}`).is(':checkbox')) { return; }
        const myInput = $(`input#${$(this).attr('for')}`);
        const randomBoolean = Math.random() >= 0.5;
        const light = $(this).find('span').find('div');
        if (randomBoolean) { light.addClass('lit'); } else { light.removeClass('lit'); }
        myInput.prop('checked', randomBoolean);
      });
    };

    const randomizeVcoGroup = function() {
      if (!!sequences.sequencesActive) { return; }
      const items = ['one', 'two', 'three'];
      const item = items[Math.floor(Math.random() * items.length)];
      $('.light[data-radio]').each(function() {
        $(this).removeClass('lit');
        $(`:radio[value=${item}]`).prop('checked', false);
      });
      $(`:radio[value=${item}]`).prop('checked', true);
      $(`label[for="patch_vco_group_${item}"]`).find('span .light').addClass('lit');
    };

    const randomizeKeysLfoShape = function() {
      const items = ['saw', 'triangle', 'square'];
      const item = items[Math.floor(Math.random() * items.length)];

      $('.light[data-radio]').each(function() {
        $(this).removeClass('lit');
        $(`:radio[value=${item}]`).prop('checked', false);
      });
      $(`:radio[value=${item}]`).prop('checked', true);
      $(`label[for="patch_lfo_shape_${item}"]`).find('span .light').addClass('lit');
    }

    randomizeKnobs();
    randomizeCheckboxes();

    if ($('.volca.bass').length > 0) {
      randomizeVcoActive();
      randomizeVcoGroup();
    }

    if ($('.volca.keys').length > 0) {
      randomizeKeysLfoShape();
    }

    midiOut.syncMidi();
  });

  $('.bottom-row .on-off').on('click tap', function() {
    $(this).find('.light').toggleClass('lit');
  });

  $('.button').on('click tap', function() {
    const vco = $(this).attr('id').split('_')[0];
    const value = $(this).data('active');
    const vcoKnob = $(`.knob#${vco}_pitch`);
    const input = $(`input#patch_${$(this).attr('id').split('_').slice(0, -1).join('_')}`);
    $(this).toggleClass('lit');
    vcoKnob.toggleClass('lit');
    vcoKnob.toggleClass('unlit');
    $(this).data('active', !value);
    input.prop('checked', !value);
  });

  $('.knob').on('mousedown touchstart', function(e) {
    VS.clickedPoint = e.pageY || Math.round(e.originalEvent.touches[0].pageY);
    e.preventDefault();
    e.stopPropagation();
    VS.clicked = true;
    VS.dragging = true;
    VS.activeKnob = new VS.Knob(this);
    sequences.activeNote = null;
    const knob = $(VS.activeKnob.element);
    if (!knob.data('origin')) { knob.data('origin', {top: knob.offset().top}); }
  });

  $('.knob').mouseenter(function() {
    midi = $(this).data('midi');
    if (VS.dragging) { return false; }
    VS.activeKnob = new VS.Knob(this);
    display.update(midi, VS.activeKnob.displayStyle);
  });

  $(document).on('mousemove touchmove', function(e) {
    if (VS.clicked) { VS.dragging = true; }
    if (!VS.dragging) { return; }
    e.preventDefault();
    e.stopPropagation();
    $('body').css('cursor', 'ns-resize');
    VS.currentPoint = e.pageY || Math.round(e.originalEvent.touches[0].pageY);
    turnKnob(e);
    sequences.changeSequenceNote(e);
  });

  const calculateDegree = function() {
    if ($(VS.activeKnob.element).hasClass('dark')) {
      // SNAP KNOBS
      // I suspect this is slow.
      difference = VS.clickedPoint - VS.currentPoint;

      if (difference > -15 && difference <= 15) {
        return VS.activeKnob.rotation;
      } else if (difference <= -135) {
        snapped_degree = -150;
      } else if (difference > -135 && difference <= -105) {
        snapped_degree = -120;
      } else if (difference > -105 && difference <= -75) {
        snapped_degree = -90;
      } else if (difference > -75 && difference <= -45) {
        snapped_degree = -60;
      } else if (difference > -45 && difference <= -15) {
        snapped_degree = -30;
      } else if (difference > 15 && difference <= 45) {
        snapped_degree = 30;
      } else if (difference > 45 && difference <= 75) {
        snapped_degree = 60;
      } else if (difference > 75 && difference <= 105) {
        snapped_degree = 90;
      } else if (difference > 105 && difference <= 135) {
        snapped_degree = 120;
      } else if (difference > 135) {
        snapped_degree = 150;
      }

      return VS.activeKnob.rotation + snapped_degree;
    } else {
      // GLIDE KNOBS
      return (VS.activeKnob.rotation + VS.clickedPoint) - VS.currentPoint;
    }
  };

  var turnKnob = function(e) {
    if (VS.activeKnob === null) { return; }

    let degree = calculateDegree();

    const leftLimit = VS.activeKnob.leftLimit;
    const rightLimit = VS.activeKnob.rightLimit;

    if (degree > rightLimit) {
      VS.activeKnob.rotation = rightLimit;
      VS.clickedPoint = VS.currentPoint;
    }
    if (degree < leftLimit) {
      VS.activeKnob.rotation = leftLimit;
      VS.clickedPoint = VS.currentPoint;
    }

    degree = calculateDegree();

    if ((VS.currentPoint !== VS.clickedPoint) || (degree === leftLimit) || (degree === rightLimit)) {
      VS.activeKnob.rotate(degree);

      // TODO: Refactor! This is ugly.  The way the Knob class is defined
      //   isn't polymorphism friendly.
      if ($(VS.activeKnob.element).hasClass('dark')) {
        midi_map = {
          '-90': 10,
          '-60': 30,
          '-30': 50,
          '0': 70,
          '30': 100,
          '60': 120
        };
        midi = midi_map[degree];
        trueMidi = ((63.5 / limit) * degree) + 63.5
      } else {
        midi = Math.round(((63.5 / limit) * degree) + 63.5);
        trueMidi = ((63.5 / limit) * degree) + 63.5
      }

      if (midiOut.ready()) {
        midiOut.output.sendControlChange(
          $(VS.activeKnob.element).data('control-number'),
          midi,
          midiOut.channel
        );
      }
      $(VS.activeKnob.element).data('midi', midi);
      $(VS.activeKnob.element).data('trueMidi', trueMidi);
      VS.activeKnob.inputElement.val(midi);
      display.update(midi, VS.activeKnob.displayStyle);
    }
  };

  $(document).on('mouseup touchend', function(e) {
    VS.clicked = false;
    if (!VS.dragging) { tapKnob(); }
    if (!VS.dragging) { return; }
    VS.dragging = false;
    VS.currentPoint = e.pageY || Math.round(e.originalEvent.changedTouches[0].pageY);
    $('body').css('cursor', 'default');
    endKnobTurn();
    sequences.endNoteChange();
  });

  var endKnobTurn = function() {
    if (VS.activeKnob === null) { return; }
    const currentAngle = calculateDegree();
    let leftLimit = VS.activeKnob.leftLimit;
    let rightLimit = VS.activeKnob.rightLimit;

    if (VS.activeKnob.rotation > rightLimit) {
      VS.activeKnob.rotation = rightLimit;
      VS.currentPoint = VS.clickedPoint;
    }
    if (VS.activeKnob.rotation < leftLimit) {
      VS.activeKnob.rotation = leftLimit;
      VS.currentPoint = VS.clickedPoint;
    }
    $(VS.activeKnob.element).data('rotation', currentAngle);
    $(VS.activeKnob.element).data('midi', midi);
    VS.activeKnob = null;
  };

  var tapKnob = function() {
    if ((VS.activeKnob === null) || (typeof VS.activeKnob !== VS.Knob)) { return; }
    display.update(VS.activeKnob.midi, VS.activeKnob.displayStyle);
  };
};
