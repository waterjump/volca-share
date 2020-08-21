VS.MidiOut = function() {
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
    $('#green-check-mark').show();
    $('#green-check-mark').fadeOut(1000);

    if (localStorageAvailable() && localStorage.DoNotShowMessageAgain != 'true') {
      localStorage.DoNotShowMessageAgain = 'true';
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
