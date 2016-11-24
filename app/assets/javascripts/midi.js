var midiAvailable, midiOutput, midiChannel;

WebMidi.enable(function(err) {
  if (err) console.log("An error occurred", err);
  midiAvailable = true;
});
