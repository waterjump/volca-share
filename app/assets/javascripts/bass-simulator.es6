VS.BassSimulator = function() {
  const myp = new p5(function(p) {
    const osc = new p5.Oscillator('sawtooth');
    const keyCodes = [65, 87, 83, 69, 68, 70, 84, 71, 89, 72, 85, 74, 75, 76];

    p.setup = function() {
      console.log('p5 is running :-]');
      osc.freq(110);
      osc.amp(1);
    };

    p.keyPressed = function() {
      if (keyCodes.includes(p.keyCode)) {
        osc.start();
      }
    };

    p.keyReleased = function() {
      osc.stop();
    };
  });
};
