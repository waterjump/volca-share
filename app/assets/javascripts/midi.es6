VS.MidiOut = function() {
  if ($('body').data('midi-out') === undefined) {
    return;
  }

  const scope = this;
  this.supported;
  this.output;
  this.channel;
  this.playingNote;

  this.ready = function() {
    return (this.output !== undefined) && (this.channel !== undefined);
  };

  this.changeChannel = function(element) {
    this.channel = $(element).val();
  };

  this.changeOutput = function(element) {
    this.output = WebMidi.getOutputByName($(element).val());
  };

  this.updateForm = function() {
    if (!this.supported || !(WebMidi.outputs.length > 0)) { return; }
    let items = '<option>Midi Device</option>';
    $(WebMidi.outputs).each(function() {
      items += `<option value="${this.name}">${this.name}</option>`;
    });
    $('#midi-device').html(items);
    $('#midi-device option:eq(1)').attr('selected', 'selected');
    this.changeOutput($('#midi-device option:eq(1)'));
    $('#midi-channel option:eq(1)').attr('selected', 'selected');
    this.changeChannel($('#midi-channel option:eq(1)'));
    $('#midi-output').removeClass('hidden');
    $('.midi-enabled').css('border', 'lightgreen solid');
    $('#enable-web-midi').hide();
    $('#midi-only-panel').removeClass('hidden');
  };

  this.enableSync = function() {
    if (!this.ready()) { return; }
    $('#sync').removeClass('disabled');
  };

  this.init = function() {
    WebMidi.enable(function(err) {
      if (err) { return; }
      scope.supported = true;
      scope.updateForm();
      scope.enableSync();
    });
  };

  this.init();

  this.syncMidi = function() {
    if (!this.ready()) { return; }
    $('.knob').each(function() {
      scope.output.sendControlChange(
        $(this).data('control-number'),
        $(this).data('midi'),
        scope.channel
      );
    });
  };

  this.playNote = function(note) {
    if (!this.ready() || (this.playingNote === note)) { return; }
    if (this.playingNote !== undefined) { this.output.stopNote(this.playingNote); }
    this.output.playNote(note);
    this.playingNote = note;
  };

  this.stopNote = function() {
    if (!this.ready() || (this.playingNote === undefined)) { return; }
    this.output.stopNote(this.playingNote);
    this.playingNote = undefined;
  };

  $(document).on('midioutplaynote', function(event) {
    this.playNote(event.detail.note);
  }.bind(this));

  $(document).on('midioutstopnote', function() {
    this.stopNote();
  }.bind(this));

  $(document).on('midicontrolchange', function(event) {
    this.output.sendControlChange(
      event.detail.controlNumber,
      event.detail.midiValue,
      this.channel
    );
  }.bind(this));

  $(document).on('midisync', function() {
    this.syncMidi();
  }.bind(this));

  $('#midi-device').change(function() {
    scope.changeOutput(this);
    scope.enableSync();
  });

  $('#midi-channel').change(function() {
    scope.changeChannel(this);
    scope.enableSync();
  });

  $('#sync').on('click tap', function() {
    scope.syncMidi();
    $('.green-check-mark').show();
    $('.green-check-mark').fadeOut(1000);

    if (localStorageAvailable() && localStorage.DoNotShowMessageAgain != 'true') {
      localStorage.DoNotShowMessageAgain = 'true';
      $('#dont-show-again').prop('checked', 'checked');
      setTimeout(
        function(){ $('#sync').removeAttr('data-toggle data-target'); },
        200
      );
    }
  });

  const localStorageAvailable = function() {
    if (typeof(Storage) !== "undefined") {
      return true;
    } else {
      return false;
    }
  };

  $('#dont-show-again').click(function(){
    if ($('#dont-show-again').prop('checked')) {
      if (localStorageAvailable()) {
        localStorage.DoNotShowMessageAgain = 'true';
        $('#sync').removeAttr('data-toggle data-target');
      }
    } else {
      localStorage.DoNotShowMessageAgain = 'false';
      $('#sync').attr('data-toggle', 'modal');
      $('#sync').attr('data-target', '#sync-modal');
    }
  });

  if (localStorageAvailable() && localStorage.DoNotShowMessageAgain == 'true') {
    $('#sync').removeAttr('data-toggle data-target');
  }
};

VS.MidiIn = function() {
  if ($('body').data('midi-in') === undefined) {
    return;
  }

  this.supported;
  this.lastInput = null;
  this.input = null;
  this.channel;

  this.changeChannel = function(newChannel) {
    if (newChannel === 'Select MIDI Channel') { return; }

    this.channel = parseInt(newChannel);
  };

  this.changeInput = function(element) {
    if ($(element).val() === 'Midi Device') { return; }

    this.lastInput = this.input;
    this.input = WebMidi.getInputByName($(element).val());
    setNewInput();
  };

  $('#midi-device').change(function() {
    this.changeInput($('#midi-device :selected'));
  }.bind(this));

  $('#midi-channel').change(function() {
    const newChannel = $('#midi-channel :selected').val();
    this.changeChannel(newChannel);
  }.bind(this));

  this.updateForm = function() {
    if (!this.supported || !(WebMidi.inputs.length > 0)) { return; }
    let items = '<option>Midi Device</option>';
    $(WebMidi.inputs).each(function() {
      items += `<option value="${this.name}">${this.name}</option>`;
    });
    $('#midi-device').html(items);
    $('#midi-device option:eq(1)').attr('selected', 'selected');
    this.changeInput($('#midi-device option:eq(1)'));
    $('#midi-channel option:eq(1)').attr('selected', 'selected');
    this.changeChannel($('#midi-channel option:eq(1)').val());
    $('#midi-input').removeClass('hidden');
    $('#enable-web-midi').hide();
  };

  const createMidiNoteOnEvent = function(note) {
    return new CustomEvent('midinoteon', { detail: note });
  };

  const createMidiNoteOffEvent = function(note) {
    return new CustomEvent('midinoteoff', { detail: note });
  };

  const createMidiCcChangeEvent = function(ccNumber, value) {
    result = new CustomEvent(
      'midiccchange',
      {
        detail: {
          ccNumber: ccNumber,
          value: value
        }
      }
    );

    return result;
  };

  const noteOnListenerCallback = function(e) {
    if ((this.channel === e.channel) || (this.channel === -1)) {
      document.dispatchEvent(createMidiNoteOnEvent(e.note));
    }
  }.bind(this);

  const noteOffListenerCallback = function(e) {
    if ((this.channel === e.channel) || (this.channel === -1)) {
      document.dispatchEvent(createMidiNoteOffEvent(e.note));
    }
  }.bind(this);

  const ccChangeListenerCallback = function(e) {
    if ((this.channel === e.channel) || (this.channel === -1)) {
      document.dispatchEvent(createMidiCcChangeEvent(e.controller.number, e.value));
    }
  }.bind(this);

  const unsetLastInput = function() {
    if (this.lastInput !== null) {
      this.lastInput.removeListener('noteon');
      this.lastInput.removeListener('noteoff');
    }
  }.bind(this);

  const setNewInput = function() {
    if (this.input !== null) {
      unsetLastInput();
      this.input.addListener("noteon", "all", noteOnListenerCallback);
      this.input.addListener("noteoff", "all", noteOffListenerCallback);
      this.input.addListener("controlchange", "all", ccChangeListenerCallback);
    }
  }.bind(this);

  this.init = function() {
    WebMidi.enable(function(err) {
      if (err) { return; }
      this.supported = true;
      this.updateForm();
    }.bind(this));
  };

  this.init();
};
