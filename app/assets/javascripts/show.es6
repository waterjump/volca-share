$(function() {
  if ($('body.show').length === 0) { return; }

  const { display } = VS;
  const { sequences } = VS;

  sequences.init();

  VS.autoRotateAllKnobs();

  $('.knob').mouseenter(function() {
    const midi = $(this).data('midi');

    VS.setActiveKnob(this);

    display.update(midi, VS.activeKnob.displayStyle);
  });
});
