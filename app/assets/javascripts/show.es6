$(function() {
  if ($('body.show').length === 0) { return; }
  let activeKnob = undefined;
  const { display } = VS;
  const limit = 140;
  new VS.MidiOut;
  const { sequences } = VS;

  sequences.init();

  $('.knob').each(function() {
    const my_knob = new VS.Knob(this);
    const degree = my_knob.degreeForMidi($(this).data('midi'), limit);
    $(this).data('rotation', degree);
    my_knob.autoRotate(degree);
  });

  $('.knob').mouseenter(function() {
    const midi = $(this).data('midi');
    activeKnob = new VS.Knob(this);
    display.update(midi, activeKnob.displayStyle);
  });
});
