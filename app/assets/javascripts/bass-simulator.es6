VS.BassSimulator = function() {
  const myp = new p5(function(p) {
    const osc1 = new p5.Oscillator('sawtooth');
    let octave = 3;
    let vco1 = {
      shape: 'sawtooth',
      amp: 1
    }

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

    const zKeyCode = 90;
    const xKeyCode = 88;

    const octaveMap = {
      "-1": 8,
      0: 9,
      1: 21,
      2: 33,
      3: 45,
      4: 57,
      5: 69,
      6: 81,
      7: 93,
      8: 105,
      9: 118
    }

    const keyCodes = Object.keys(keyMap).map(Number);

    p.setup = function() {
      console.log('p5 is running :-]');
      osc1.amp(vco1.amp);
      filter = new p5.Filter();
      filter.freq(2517.5);
      filter.res(0);
      osc1.disconnect();
      osc1.connect(filter);
    };

    p.keyPressed = function() {
      // PLAY NOTES
      if (keyCodes.includes(p.keyCode)) {
        osc1.freq(keyMap[p.keyCode] / 2.0);
        osc1.start();
      }

      // OCTAVE DOWN (Z KEY)
      if (zKeyCode == p.keyCode) {
        if (octave > -1) {
          octave -= 1;
        }
        VS.display.update(octaveMap[octave], 'noteString');
      }

      // OCTAVE UP (X KEY)
      if (xKeyCode == p.keyCode) {
        if (octave < 9) {
          octave += 1;
        }
        VS.display.update(octaveMap[octave], 'noteString');
      }
    };

    p.keyReleased = function() {
      if (p.keyIsPressed) { return; }
      osc1.stop();
    };

    // OSC WAVE
    $('label[for="patch_vco1_wave"]').on('click tap', function() {
       if (vco1.shape == 'sawtooth') {
         vco1.shape = 'square';
       } else {
         vco1.shape = 'sawtooth';
      }
      osc1.setType(vco1.shape);
    });

    // VCO1 ON/OFF
    $('#vco1_active_button').on('click tap', function(){
      if (vco1.amp == 1) {
        vco1.amp = 0;
      } else {
        vco1.amp = 1;
      }
      osc1.amp(vco1.amp);
    });

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
