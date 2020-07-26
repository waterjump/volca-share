VS.BassSimulator = function() {
  const myp = new p5(function(p) {
    const osc = new p5.Oscillator('sawtooth');

    p.setup = function() {
      console.log('p5 is running :-]');
      osc.freq(110);
      osc.amp(1);
    };

    p.keyPressed = function() {
      osc.start();
    };

    p.keyReleased = function() {
      osc.stop();
    };
  });
};
