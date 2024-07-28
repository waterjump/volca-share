VS.EmulatorEngine = function(patch) {
  const audioCtx = new AudioContext();
  const myToneCtx = new Tone.Context({context: audioCtx, lookAhead: 0.1})
  const notePlaying = new Tone.Param(audioCtx.createGain().gain);
  const attackEndTime = new Tone.Param(audioCtx.createGain().gain);
  const masterAmp = audioCtx.createGain();

  // An amp used for modulating amplitude without overriding
  //  the master Amp level
  let preAmp = audioCtx.createGain();
  preAmp.connect(masterAmp);

  const filter = audioCtx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(patch.filter.cutoff, audioCtx.currentTime);
  filter.Q.value = patch.filter.peak;
  filter.connect(preAmp);

  const filterEgAmp = audioCtx.createGain();
  filterEgAmp.gain.setValueAtTime(patch.envelope.cutoffEgInt, audioCtx.currentTime);
  filterEgAmp.connect(filter.detune);

  const filterEg = audioCtx.createConstantSource();
  filterEg.offset.setValueAtTime(0, audioCtx.currentTime);
  filterEg.connect(filterEgAmp);
  filterEg.start();

  const filterEgOffsetParam = new Tone.Param(filterEg.offset);

  const ampEg = audioCtx.createGain();
  ampEg.gain.setValueAtTime(0, audioCtx.currentTime);
  ampEg.connect(filter);

  const ampEgGainParam = new Tone.Param(ampEg.gain);
  ampEgGainParam.setValueAtTime(0, audioCtx.currentTime);

  // Oscillator mute button amps (will go to gain 0 on mute button click)
  let osc1MuteAmp = audioCtx.createGain()
  osc1MuteAmp.gain.value = patch.vco[1].amp;
  osc1MuteAmp.connect(ampEg);
  let osc2MuteAmp = audioCtx.createGain()
  osc2MuteAmp.gain.value = patch.vco[2].amp;
  osc2MuteAmp.connect(ampEg);
  let osc3MuteAmp = audioCtx.createGain()
  osc3MuteAmp.gain.value = patch.vco[3].amp;
  osc3MuteAmp.connect(ampEg);

  const oscMuteAmps = [null, osc1MuteAmp, osc2MuteAmp, osc3MuteAmp];

  let osc = [null, null, null, null];

  const ampLfoPitch = audioCtx.createGain()
  const setAmpLfoPitchGain = function() {
    if (patch.lfo.targetPitch) {
      // Affect pitch
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, audioCtx.currentTime);
    } else {
      // Do not affect pitch
      ampLfoPitch.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  setAmpLfoPitchGain();

  const ampLfoCutoff = audioCtx.createGain()
  const setAmpLfoCutoffGain = function() {
    if (patch.lfo.targetCutoff) {
      // Affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, audioCtx.currentTime);
    } else {
      // Do not affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  setAmpLfoCutoffGain();
  ampLfoCutoff.connect(filter.detune);

  // Creates a curve that goes from -1, -1 to 1, 0.
  const makeLfoAmpCurve = function() {
    let n_samples = 44100;
    let curve = new Float32Array(n_samples)
    let i = 0;
    for ( ; i < n_samples; ++i ) {
      curve[i] = i / (n_samples - 1) - 1;
    }
    return curve;
  };

  const lfoAmpWaveShaper = audioCtx.createWaveShaper();
  lfoAmpWaveShaper.curve = makeLfoAmpCurve();

  const ampLfoAmp = audioCtx.createGain()
  const setAmpLfoAmpGain = function() {
    if (patch.lfo.targetAmp) {
      // Affect amp
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, audioCtx.currentTime);
    } else {
      // Do not affect amp
      ampLfoAmp.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  setAmpLfoAmpGain();

  lfoAmpWaveShaper.connect(ampLfoAmp);
  ampLfoAmp.connect(preAmp.gain);

  let oscLfo;

  const setupOscLfo = function() {
    oscLfo = audioCtx.createOscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, audioCtx.currentTime);
    oscLfo.connect(ampLfoPitch);
    oscLfo.connect(ampLfoCutoff);
    oscLfo.connect(lfoAmpWaveShaper);
    oscLfo.start();
  }

  setupOscLfo();

  // Setup oscilators
  [1, 2, 3].forEach(function(oscNumber) {
    let oscillator = audioCtx.createOscillator();
    oscillator.type = patch.vco[oscNumber].shape;
    oscillator.detune.setValueAtTime(
      patch.vco[oscNumber].detune,
      audioCtx.currentTime
    );

    oscillator.frequency.setValueAtTime(0, audioCtx.currentTime);

    osc[oscNumber] = oscillator;
    osc[oscNumber].connect(oscMuteAmps[oscNumber]);
    ampLfoPitch.connect(osc[oscNumber].detune);
    osc[oscNumber].start();
  });

  // controls frequency of all three vcos rather than looping through them.
  const oscFreqNode = audioCtx.createConstantSource();
  oscFreqNode.offset.setValueAtTime(440, audioCtx.currentTime);
  oscFreqNode.connect(osc[1].frequency);
  oscFreqNode.connect(osc[2].frequency);
  oscFreqNode.connect(osc[3].frequency);
  oscFreqNode.start();

  const oscFreqNodeOffsetParam = new Tone.Param(oscFreqNode.offset);

  this.init = () => {
    console.log('Initializing emulator engine!');
    Tone.setContext(myToneCtx);
    Tone.start();
    masterAmp.connect(audioCtx.destination);
  };

  this.getAudioCtx = () => {
    console.log('fffff');
    return audioCtx;
  };
};
