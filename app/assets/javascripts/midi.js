function MidiOut() {
  var parent = this;
  this.supported;
  this.output;
  this.channel;

  this.ready = function(){
    return (parent.output !== 'undefined' && parent.channel !== 'undefined')
  }

  this.changeChannel = function(element){
    console.log($(element).val());
    parent.channel = $(element).val();
  }

  this.changeOutput = function(element){
    parent.output = WebMidi.getOutputByName($(element).val());
  }

  this.updateForm = function(){
    if (parent.supported && WebMidi.outputs.length > 0) {
      var items = '<option>Midi Device</option>';

      $(WebMidi.outputs).each(function() {
        items += '<option value="' + this.name + '">' + this.name + '</option>';
      });
      $('#midi-device').html(items);

      $('#midi-device option:eq(1)').attr("selected", "selected");
      parent.changeOutput($('#midi-device option:eq(1)'));
      $('#midi-channel option:eq(1)').attr("selected", "selected");
      parent.changeChannel($('#midi-channel option:eq(1)'));
      $('#midi-output').removeClass('hidden');
    } else {
      $('.knob').removeClass('midi-enabled');
    }
  }

  this.enableSync =  function(){
    if (parent.ready()) {
      $('#sync').removeClass('disabled')
    }
  }

  this.init = function(){
    WebMidi.enable(function(err) {
      if (err) {
        console.log("An error occurred", err);
      } else {
        parent.supported = true;
        parent.updateForm();
      }
    });
  }

  this.init();
}
