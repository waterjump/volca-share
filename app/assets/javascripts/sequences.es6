VS.Sequences = function() {
  const { display } = VS;
  const { midiOut } = VS;
  const scope = this;
  const vcoGroupCounts = {one: 3, two: 2, three: 1};
  this.sequencesActive = $('.remove-sequence[value=\'false\']').toArray().length > 1;
  this.sequenceCount = 0;
  this.activeNote = null;

  const lightSequences = function() {
    $('.bottom-row label, .sequence-box label').each(function() {
      const myInput = $(`input#${$(this).attr('for')}`);
      if (myInput.prop('checked')) { $(this).find('span').find('div').addClass('lit'); }
    });
  };

  const setSequenceNotes = function() {
    $('.note-display').each(function() {
      $(this).html(VS.midiNoteNumbers[$(this).data('starting-note')]);
    });
  };

  this.init = function() {
    lightSequences();
    setSequenceNotes();
  };

  const showSequences = function() {
    $('.sequence-message').removeClass('hidden');
    let i = 0;
    while (i < scope.sequenceCount) {
      const totalSequenceCount = $('.sequence-area .sequence-form').toArray().length;
      const content = $('#new_choice_form').html().replace(/QQQ/g, totalSequenceCount);
      $('.sequence-holder').append(content);
      i++;
    }
    $('#toggle-sequences').text('Remove sequences');
    scope.sequencesActive = true;
  };

  const hideSequences = function() {
    $('.sequence-area .remove-sequence').val('true');
    $('.sequence-area .sequence-form').addClass('hidden');
    $('.sequence-message').addClass('hidden');
    $('#toggle-sequences').text('Add sequences');
    scope.sequencesActive = false;
  };

  const setSequenceCount = function() {
    const vcoGroup = $('input[name=patch\\[vco_group\\]]:checked').val();
    scope.sequenceCount = vcoGroupCounts[vcoGroup];
  };

  $('#toggle-sequences').on('click tap', function(e) {
    e.preventDefault();
    setSequenceCount();
    if (scope.sequencesActive) { hideSequences(); } else { showSequences(); }
    $('.sequence-box .multi').each(function() {
      const myInput = $(`input#${$(this).parent().attr('for')}`);
      if (myInput.prop('checked')) { $(this).find('div').addClass('lit'); }
    });
  });

  $('.sequence-holder').on('mousedown touchstart', '.note-display', function(e) {
    VS.clickedPoint = e.pageY || Math.round(e.originalEvent.touches[0].pageY);
    e.preventDefault();
    e.stopPropagation();
    VS.clicked = true;
    scope.activeNote = $(this);
    VS.activeKnob = null;
  });

  $('.sequence-holder').on('click tap', '.sequence-box label', function() {
    if ($('body.show').length > 0) { return; }
    $(this).find('span').find('div').toggleClass('lit');
  });

  // TODO: this method sucks lol.  Refactor.
  $('.bottom-row .multi').on('click tap', function() {
    $('.light[data-radio]').each(function() {
      $(this).removeClass('lit');
    });
    if (scope.sequencesActive) {
      let difference, i;
      const vcoGroup = $(`input#${$(this).parent().attr('for')}`).val();
      const mySequenceCount = vcoGroupCounts[vcoGroup];
      const hiddenSequences = $('.sequence-area .sequence-form.hidden').toArray();
      const shownSequences = $('.sequence-area .sequence-form').not('.hidden').toArray();
      const disabledSequences = $('.sequence-area .sequence-form:not(\'.hidden\') .remove-sequence[value=\'true\']').toArray();
      const totalSequenceCount = $('.sequence-area .sequence-form').toArray().length;
      let activeSequences = $('.sequence-area .remove-sequence[value=\'false\']').toArray();
      if (mySequenceCount > activeSequences.length) {
        if (mySequenceCount > shownSequences.length) {
          // uncheck all boxes
          $(disabledSequences).each(function() {
            $(this).val('false');
            $(this).removeAttr('disabled');
          });
          $('.sequence-area .sequence-form').each(function() {
            $(this).css('opacity', '1.0');
          });
          activeSequences = $('.sequence-area .remove-sequence[value=\'false\']').toArray();
          //add sequences
          difference = mySequenceCount - (activeSequences.length);
          i = activeSequences.length;
          while (i < (activeSequences.length + difference)) {
            const content = $('#new_choice_form').html().replace(/QQQ/g, totalSequenceCount - 1);
            $('.sequence-holder').append(content);
            i++;
          }
        } else {
          //uncheck boxes
          i = 0;
          while (i < mySequenceCount) {
            $(disabledSequences[i]).val('false');
            $(shownSequences[i]).css('opacity', '1.0');
            i++;
          }
        }
      } else if (activeSequences.length > mySequenceCount) {
        //check boxes
        difference = activeSequences.length - mySequenceCount;
        i = activeSequences.length - 1;
        while (i > (activeSequences.length - 1 - difference)) {
          $(activeSequences[i]).val('true');
          $(shownSequences[i]).css('opacity', '0.5');
          i--;
        }
      }
    }
    $(this).find('.light').addClass('lit');
  });

  $('.sequence-holder').on('mouseenter', '.note-display', function() {
    if (VS.dragging) { return false; }
    const value = $(this).data('starting-note');
    display.update(value, 'noteString');
    midiOut.playNote($(this).html());
    $('.note-light').hide();
    $(`.note-${(value + 3) % 12}`).show();
  });

  $('.sequence-holder').on('mouseleave', '.note-display', function() {
    if (VS.dragging) { return false; }
    $('.note-light').hide();
    midiOut.stopNote();
  });

  this.changeSequenceNote = e => {
    if (this.activeNote === null) { return; }
    let num = this.activeNote.data('starting-note') + Math.floor((VS.clickedPoint - VS.currentPoint) / 6);
    if (num > 127) { num = 127; }
    if (num < 0) { num = 0; }
    if (num === this.activeNote.data('note')) { return; }
    display.update(num, 'noteString');
    this.activeNote.data('note', num);
    this.activeNote.html(VS.midiNoteNumbers[num]);
    midiOut.playNote(VS.midiNoteNumbers[num]);
    $('.note-light').hide();
    $(`.note-${(num + 3) % 12}`).show();
  };

  this.endNoteChange = function() {
    if (this.activeNote === null) { return; }
    this.activeNote.data('starting-note', this.activeNote.data('note'));
    midiOut.stopNote();
    $('.note-light').hide();
    const inputId = this.activeNote['0'].parentNode.attributes['0'].value;
    $(`input#${inputId}`).val(this.activeNote.data('note'));
    this.activeNote = null;
  };
};
