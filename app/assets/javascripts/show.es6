$(function() {
  if ($('body.show').length === 0) { return; }

  let activeKnob = undefined;
  const { display } = VS;
  const { sequences } = VS;

  sequences.init();

  $('.knob').each(function() {
    new VS.Knob(this).setKnob($(this).data('midi'));
  });

  $('.knob').mouseenter(function() {
    const midi = $(this).data('midi');
    activeKnob = new VS.Knob(this);
    display.update(midi, activeKnob.displayStyle);
  });
});
