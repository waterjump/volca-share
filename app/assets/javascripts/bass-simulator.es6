VS.BassSimulator = function() {
  const myp = new p5(function(p) {
    const osc = new p5.Oscillator('sawtooth');
    let osc1Shape = 'sawtooth';
    let filter;
    const keyMap = {
      65: 130.81, // C
      87: 138.59, // C#
      83: 146.83, // D
      69: 155.56, // D#
      68: 164.81, // E
      70: 174.61, // F
      84: 185.00, // F#
      71: 196.00, // G
      89: 207.65, // G#
      72: 220.00, // A
      85: 233.08, // A#
      74: 246.94, // B
      75: 261.63, // C
      76: 277.18 // C#
    }
    const keyCodes = Object.keys(keyMap).map(Number);

    p.setup = function() {
      console.log('p5 is running :-]');
      osc.amp(1);
      filter = new p5.Filter();
      filter.freq(2517.5);
      filter.res(0);
      osc.disconnect();
      osc.connect(filter);
    };

    p.keyPressed = function() {
      if (keyCodes.includes(p.keyCode)) {
        osc.freq(keyMap[p.keyCode]);
        osc.start();
      }
    };

    p.keyReleased = function() {
      if (p.keyIsPressed) { return; }
      osc.stop();
    };

    // OSC WAVE
    $('label[for="patch_vco1_wave"]').on('click tap', function() {
       if (osc1Shape == 'sawtooth') {
         osc1Shape = 'square';
       } else {
         osc1Shape = 'sawtooth';
      }
      osc.setType(osc1Shape);
    })

    // FILTER CUTOFF
    $(document).on('mousemove touchmove', function(e) {
      if (VS.activeKnob === null) { return; }

      if (VS.activeKnob.element.id == 'cutoff') {
        let cutoff, midiValue, percentage, frequency;

        cutoff = VS.activeKnob

        midiValue = $(cutoff.element).data('trueMidi');
        if (midiValue == undefined) { return; }

        percentage = midiValue / 127.0;
        frequency = 20 + (percentage**3 * 19980.0);

        filter.freq(frequency);
      }
    });
  });
};
