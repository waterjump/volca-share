var midiSupported, midiOutput, midiChannel;

WebMidi.enable(function(err) {
  if (err) console.log("An error occurred", err);
  midiSupported = true;
});

$(function(){
  if (midiSupported && WebMidi.outputs.length > 0) {
    var items = '<option>Midi Device</option>';

    $('#midi-device').change(function(){
      midiOutput = WebMidi.getOutputByName($(this).val());
      enableSync();
    });

    $('#midi-channel').change(function(){
      midiChannel = $(this).val();
      enableSync();
    });

    $(WebMidi.outputs).each(function() {
      items += '<option value="' + this.name + '">' + this.name + '</option>';
    });
    $('#midi-device').html(items);
    $('#midi-device option:eq(1)').attr("selected", "selected");
    $('#midi-device').trigger('change');
    $('#midi-channel option:eq(1)').attr("selected", "selected");
    $('#midi-channel').trigger('change');
  } else {
    $('#midi-output').hide();
    $('.knob').removeClass('midi-enabled');
  }

  function enableSync(){
    if (typeof midiOutput !== 'undefined' && typeof midiChannel !== 'undefined') {
      $('#sync').removeClass('disabled')
    }
  }

  $('#sync').click(function(){
    $('.knob').each(function(){
      if (typeof midiOutput !== 'undefined' && typeof midiChannel !== 'undefined') {
          midiOutput.sendControlChange(
            $(this).data('control-number'),
            $(this).data('midi'),
            midiChannel
          )
      }
    });
  });
});
