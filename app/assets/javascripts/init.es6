$(function() {
  VS.clicked = false;
  VS.dragging = false;
  VS.activeKnob = null;
  VS.clickedPoint = null;
  VS.currentPoint = null;
  VS.midiOut = new VS.MidiOut;
  VS.display = new VS.Display($('#led'));
  VS.sequences = new VS.Sequences;
  VS.form = new VS.Form;
});
