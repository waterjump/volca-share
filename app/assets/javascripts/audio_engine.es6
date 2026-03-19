VS.AudioEngine = function(patch, sequence = [], options = {}) {
  // ===================================================================
  // THIS IS THE ONLY COMPONENT THAT SHOULD INTERACT WITH TONE.JS
  // ===================================================================

  const sequencerEnabled = options.enableSequencer !== false;
  this.notePlaying = new Tone.Param(new Tone.Gain().gain);
  const attackEndTime = new Tone.Param(new Tone.Gain().gain);
  const masterAmp = new Tone.Gain();
  const preAmp = new Tone.Gain();
  const filter = new Tone.BiquadFilter();
  const filterEgAmp = new Tone.Gain();
  const filterEg = new Tone.Signal();
  const ampEg = new Tone.Gain();
  const ampEgGainParam = new Tone.Param(ampEg.gain);
  const osc1MuteAmp = new Tone.Gain();
  const osc2MuteAmp = new Tone.Gain();
  const osc3MuteAmp = new Tone.Gain();
  const oscMuteAmps = [null, osc1MuteAmp, osc2MuteAmp, osc3MuteAmp];
  const ampLfoPitch = new Tone.Gain()
  const ampLfoCutoff = new Tone.Gain()
  const lfoAmpWaveShaper = new Tone.WaveShaper();
  const builtInDecay = 0.1;
  let osc = [null, null, null, null];
  let sequencerPlaying = false;
  let disposed = false;
  let sequencerEventId = null;

  const toneState = function() {
    if (Tone.context && Tone.context.state) {
      return Tone.context.state;
    }

    try {
      const context = Tone.getContext && Tone.getContext();
      if (context && context.rawContext && context.rawContext.state) {
        return context.rawContext.state;
      }
    } catch (error) {
      // no-op
    }

    return 'unknown';
  };

  // TODO: Encampsulate this setup script in its own function.

  // An amp used for modulating amplitude without overriding
  //  the master Amp level
  preAmp.connect(masterAmp);

  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(patch.filter.cutoff, Tone.now());
  filter.Q.value = patch.filter.peak;
  filter.connect(preAmp);

  filterEgAmp.gain.setValueAtTime(patch.envelope.cutoffEgInt, Tone.now());
  filterEgAmp.connect(filter.detune);

  filterEg.setValueAtTime(0, Tone.now());
  filterEg.connect(filterEgAmp);


  ampEg.gain.setValueAtTime(0, Tone.now());
  ampEg.connect(filter);

  ampEgGainParam.setValueAtTime(0, Tone.now());

  // Oscillator mute button amps (will go to gain 0 on mute button click)
  osc1MuteAmp.gain.value = patch.vco[1].amp;
  osc1MuteAmp.connect(ampEg);
  osc2MuteAmp.gain.value = patch.vco[2].amp;
  osc2MuteAmp.connect(ampEg);
  osc3MuteAmp.gain.value = patch.vco[3].amp;
  osc3MuteAmp.connect(ampEg);


  this.setAmpLfoPitchGain = function() {
    if (patch.lfo.targetPitch) {
      // Affect pitch
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, Tone.now());
    } else {
      // Do not affect pitch
      ampLfoPitch.gain.setValueAtTime(0, Tone.now());
    }
  }
  this.setAmpLfoPitchGain();

  this.setAmpLfoCutoffGain = function() {
    if (patch.lfo.targetCutoff) {
      // Affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, Tone.now());
    } else {
      // Do not affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(0, Tone.now());
    }
  }
  this.setAmpLfoCutoffGain();
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

  lfoAmpWaveShaper.curve = makeLfoAmpCurve();

  const ampLfoAmp = new Tone.Gain()
  this.setAmpLfoAmpGain = function() {
    if (patch.lfo.targetAmp) {
      // Affect amp
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, Tone.now());
    } else {
      // Do not affect amp
      ampLfoAmp.gain.setValueAtTime(0, Tone.now());
    }
  }
  this.setAmpLfoAmpGain();


  lfoAmpWaveShaper.connect(ampLfoAmp);
  ampLfoAmp.connect(preAmp.gain);

  let oscLfo;

  const setupOscLfo = function() {
    oscLfo = new Tone.Oscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, Tone.now());
    oscLfo.connect(ampLfoPitch);
    oscLfo.connect(ampLfoCutoff);
    oscLfo.connect(lfoAmpWaveShaper);
    oscLfo.start();
  }

  setupOscLfo();

  // Setup oscilators
  [1, 2, 3].forEach(function(oscNumber) {
    let oscillator = new Tone.Oscillator();
    oscillator.type = patch.vco[oscNumber].shape;
    oscillator.detune.setValueAtTime(
      patch.vco[oscNumber].detune,
      Tone.now()
    );

    oscillator.frequency.setValueAtTime(0, Tone.now());

    osc[oscNumber] = oscillator;
    osc[oscNumber].connect(oscMuteAmps[oscNumber]);
    ampLfoPitch.connect(osc[oscNumber].detune);
    osc[oscNumber].start();
  });

  // controls frequency of all three vcos rather than looping through them.
  const oscFreqNode = new Tone.Signal();
  oscFreqNode.setValueAtTime(440, Tone.now());
  oscFreqNode.connect(osc[1].frequency);
  oscFreqNode.connect(osc[2].frequency);
  oscFreqNode.connect(osc[3].frequency);

  // ==========================
  //  get browser capabilities
  // ==========================
  const browserFeatures = {};

  const checkCustomCurveClearing = function() {
    let dummyGain = new Tone.Gain();
    dummyGain.gain.setValueCurveAtTime([0, 0.5, 0], Tone.now(), 2.6);
    try {
      dummyGain.gain.cancelScheduledValues(Tone.now() + 0.1);
      dummyGain.gain.setValueAtTime(1, Tone.now() + 0.2);
      browserFeatures['customCurveClearing'] = true;
    } catch (error) {
      browserFeatures['customCurveClearing'] = false;
    }
  };

  const checkCancelAndHoldAtTime = function() {
    let dummyGain = new Tone.Gain();
    dummyGain.gain.setValueAtTime(0.5, Tone.now());
    try {
      dummyGain.gain.cancelAndHoldAtTime(Tone.now() + 0.1);
      browserFeatures['cancelAndHoldAtTime'] = true;
    } catch (error) {
      browserFeatures['cancelAndHoldAtTime'] = false;
    }
  };

  const checkChrome = function() {
    browserFeatures['usingChrome'] = navigator.userAgent.includes('Chrome/');
  };

  const testBrowserFeatures = function() {
    checkCustomCurveClearing();
    checkCancelAndHoldAtTime();
    checkChrome();
    console.log(browserFeatures);
  };

  testBrowserFeatures();

  // END get browser capabilities

  // ===================================
  //  SEQUENCER
  // ===================================

  const setTempo = () => {
    // this is needed to change loop interval
    Tone.Transport.bpm.value = patch.tempo;
    // This is needed to change tempo relative timing of gateEnd
    try {
      Tone.getTransport().bpm.rampTo(patch.tempo, 0.0001);
    } catch (error) {
      // idc
    }
  };

  const runToneSequencer = function(){
    if (!sequencerEnabled) { return; }
    setTempo();

    let i = 0;
    let previousStep;

    sequencerEventId = Tone.Transport.scheduleRepeat(function(time) {
      if (!sequencerPlaying) { return; }

      while (!sequence[i % 16].activeStep) {
        // Bail out if all steps are inactive
        if (!sequence.some(step => { return step.activeStep })) { return; }
        i++;
      }

      const gateEnd = time + 0.58 * (60 / (patch.tempo * 4));

      let currentStep = sequence[i % 16];
      this.setNotePlaying(currentStep['note'], time);

      if (currentStep['stepMode']) {
        if (i > 0 && previousStep['slide']) {
          if (i > 0 && previousStep['stepMode']) {
            this.changeCurrentNote(time);
          } else {
            // Play a new note when last step stop mode was off
            this.playNewNote(time);
            if (!currentStep['slide']) {
              this.stopNote(gateEnd);
            }
          }
        } else {
          this.playNewNote(time);
          if (!currentStep['slide']) {
            this.stopNote(gateEnd);
          }
        }
      }

      previousStep = currentStep;
      i++;
    }.bind(this), '16n');
  }.bind(this);

  runToneSequencer();

  const canInteract = () => {
    return !disposed;
  };

  const safelyDisposeToneNode = function(node) {
    if (!node) { return; }

    try {
      if (typeof node.stop === 'function' && node.state === 'started') {
        node.stop();
      }
    } catch (error) {
      // no-op
    }

    try {
      if (typeof node.disconnect === 'function') {
        node.disconnect();
      }
    } catch (error) {
      // no-op
    }

    try {
      if (typeof node.dispose === 'function') {
        node.dispose();
      }
    } catch (error) {
      // no-op
    }
  };

  this.init = () => {
    if (!canInteract()) { return; }
    Tone.start();
    masterAmp.toDestination();

    if (sequencerEnabled) {
      Tone.Transport.loop = true;
      Tone.Transport.loopEnd = 60 / patch.tempo * 4 + 's';
    }
  };

  this.activateAudio = function() {
    if (!canInteract()) { return Promise.resolve(false); }
    if (toneState() === 'running') { return Promise.resolve(true); }

    return Tone.context.resume().then(() => {
      return Tone.start();
    }).then(() => {
      return true;
    });
  };

  const retriggerLfo = function() {
    let lfo = patch.lfo;
    if (lfo.shape !== 'square') { return; }
    if (!(lfo.targetAmp) && !(lfo.targetPitch) && !(lfo.targetCutoff)) { return; }
    if (lfo.ampValue + lfo.pitchValue + lfo.cutoffValue === 0) { return; }

    oscLfo.disconnect();
    oscLfo = null;
    setupOscLfo();
  };

  const triggerDecay = function(attackEndTimeValue) {
    filterEg.linearRampToValueAtTime(
      0,
      attackEndTimeValue + (patch.envelope.decayRelease * patch.filterEgCoefficient)
    );

    if (patch.ampEgOn) {
      ampEgGainParam.setValueAtTime(1, attackEndTimeValue);

      if (browserFeatures['customCurveClearing'] && !sequencerPlaying) {
        // use custom curve
        ampEgGainParam.setValueCurveAtTime(
          VS.emulatorConstants.decayReleaseGainCurve,
          attackEndTimeValue,
          patch.envelope.decayRelease
        )
      } else {
        ampEgGainParam.linearRampToValueAtTime(
          0,
          attackEndTimeValue + patch.envelope.decayRelease
        )
      }
    }
  };

  this.playNewNote = function(time = Tone.now()) {
    if (!canInteract()) { return; }
    if (toneState() !== 'running') {
      this.activateAudio().then((activated) => {
        if (!activated || !canInteract()) { return; }
        this.playNewNote(Tone.now());
      }).catch(() => {});
      return;
    }

    let frequency;

    // Filter EG reset
    filterEg.cancelAndHoldAtTime(time);

    const attackEndTimeValue = time + patch.envelope.attack;
    attackEndTime.setValueAtTime(attackEndTimeValue, time);

    // Amp EG reset
    ampEgGainParam.cancelAndHoldAtTime(time);

    // Set frequency
    frequency = Tone.Frequency(this.notePlaying.getValueAtTime(time), 'midi').toFrequency();
    oscFreqNode.setValueAtTime(frequency, time);

    if (patch.ampEgOn && patch.envelope.attack > 0) {
      ampEgGainParam.setValueAtTime(0, time);
      ampEgGainParam.linearRampToValueAtTime(1, attackEndTimeValue);
    } else {
      ampEgGainParam.setValueAtTime(1, time);
    }

    retriggerLfo();

    // Retrigger envelope
    // Attack
    filterEg.setValueAtTime(0, time);
    filterEg.linearRampToValueAtTime(1, attackEndTimeValue);

    // Decay
    if (!patch.sustainOn) {
      triggerDecay(attackEndTimeValue);
    }
  };

  this.changeCurrentNote = function(time = Tone.now()) {
    if (!canInteract()) { return; }
    let frequency = Tone.Frequency(this.notePlaying.getValueAtTime(time), 'midi').toFrequency();
    let lastFrequency = oscFreqNode.getValueAtTime(time);

    oscFreqNode.setValueAtTime(lastFrequency, time);
    oscFreqNode.linearRampToValueAtTime(frequency, time + 0.05);
  };

  this.stopNote = function(time = Tone.now()) {
    if (!canInteract()) { return; }
    const currentValue = ampEgGainParam.getValueAtTime(time);

    // If note is already off, don't bother stopping it.
    if (currentValue === 0) { return; }

    if (patch.ampEgOn) {
      if (patch.sustainOn || (time < attackEndTime.getValueAtTime(time))) {

        // filter envelope
        filterEg.cancelAndHoldAtTime(time);

        // TODO: Use custom curve for filter?
        filterEg.linearRampToValueAtTime(
          0,
          time + (patch.envelope.decayRelease * patch.filterEgCoefficient * currentValue)
        );

        // Amp eg
        ampEgGainParam.cancelAndHoldAtTime(time);

        const duration = currentValue * patch.envelope.decayRelease;

        if (browserFeatures['customCurveClearing'] && !sequencerPlaying) {
          // custom curve
          const gainCurve = VS.emulatorConstants.decayReleaseGainCurve.map(
            function(value) { return value * currentValue }
          );
          ampEgGainParam.setValueCurveAtTime(gainCurve, time, duration);
        } else {
          ampEgGainParam.linearRampToValueAtTime(0, time + duration);
        }
      }

    } else {
      // Filter cutoff down immediately
      filterEg.cancelScheduledValues(time);
      filterEg.setValueAtTime(0, time);

      // Turn amp down immediately
      ampEgGainParam.setValueAtTime(1, time);
      ampEgGainParam.linearRampToValueAtTime(0, time + builtInDecay);
    }
  };

  // CHANGE OCTAVE
  this.changeOctave = (octaveOffset, time = Tone.now()) => {
    if (!canInteract()) { return; }
    this.notePlaying.setValueAtTime(
      this.notePlaying.getValueAtTime(time) + octaveOffset,
      time
    );

    const frequency =
      Tone.Frequency(this.notePlaying.getValueAtTime(time), 'midi').toFrequency();

    oscFreqNode.setValueAtTime(frequency, time);
  };

  this.setPeak = (value) => {
    if (!canInteract()) { return; }
    filter.Q.value = value;
  };

  this.setCutoff = (value, time = Tone.now()) => {
    if (!canInteract()) { return; }
    filter.frequency.setValueAtTime(value, time);
  };

  this.setFilterEgInt = (value, time = Tone.now()) => {
    if (!canInteract()) { return; }
    filterEgAmp.gain.setValueAtTime(value, time);
  };

  this.setVolume = (value, time = Tone.now()) => {
    if (!canInteract()) { return; }
    masterAmp.gain.setValueAtTime(value, time);
  };

  this.setOscMuteAmp = (oscNumber, value) => {
    if (!canInteract()) { return; }
    oscMuteAmps[oscNumber].gain.setValueAtTime(value, Tone.now());
  };

  this.setLfoRate = (value) => {
    if (!canInteract() || !oscLfo) { return; }
    oscLfo.frequency.setValueAtTime(value, Tone.now());
  };

  this.setLfoWave = (value) => {
    if (!canInteract() || !oscLfo) { return; }
    oscLfo.type = value;
  }

  this.setLfoInt = (value) => {
    if (!canInteract()) { return; }
    // TODO: Think about calling setAmpLfoPitchGain() here maybe.  And for others.
    if (patch.lfo.targetPitch) {
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, Tone.now());
    }

    if (patch.lfo.targetCutoff) {
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, Tone.now());
    }

    if (patch.lfo.targetAmp) {
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, Tone.now());
    }
  };

  this.setNotePlaying = (value, time = Tone.now()) => {
    if (!canInteract()) { return; }
    this.notePlaying.setValueAtTime(value, time);
  };

  this.getNotePlaying = () => {
    if (!canInteract()) { return undefined; }
    return this.notePlaying.getValueAtTime(Tone.now());
  };

  this.setOscPitch = (index, value) => {
    if (!canInteract()) { return; }
    osc[index].detune.setValueAtTime(value, Tone.now());
  };

  this.setTempo = () => {
    if (!canInteract() || !sequencerEnabled) { return; }
    setTempo();
  };

  this.startSequencer = () => {
    if (!canInteract() || !sequencerEnabled) { return; }
    sequencerPlaying = true;
    Tone.Transport.start('+0');
  };

  this.stopSequencer = () => {
    if (!canInteract() || !sequencerEnabled) { return; }
    sequencerPlaying = false;
    Tone.Transport.stop();
    this.stopNote(Tone.now() + 0.2);
  };

  this.getSequencerPlaying = () => {
    return sequencerEnabled ? sequencerPlaying : false;
  };

  this.setSequencerPlaying = (value) => {
    if (!canInteract() || !sequencerEnabled) { return; }
    sequencerPlaying = value;
  };

  this.getOsc = (index) => {
    if (!canInteract()) { return null; }
    return osc[index];
  };

  this.setOscShape = (index, value) => {
    if (!canInteract()) { return; }
    osc[index].type = value;
  };

  this.dispose = () => {
    if (disposed) { return; }

    const releaseTime = Tone.now();
    this.stopSequencer();
    this.stopNote(releaseTime);
    this.setVolume(0, releaseTime);

    if (sequencerEnabled && sequencerEventId !== null) {
      Tone.Transport.clear(sequencerEventId);
      sequencerEventId = null;
    }

    disposed = true;

    safelyDisposeToneNode(this.notePlaying);
    safelyDisposeToneNode(attackEndTime);
    safelyDisposeToneNode(masterAmp);
    safelyDisposeToneNode(preAmp);
    safelyDisposeToneNode(filter);
    safelyDisposeToneNode(filterEgAmp);
    safelyDisposeToneNode(filterEg);
    safelyDisposeToneNode(ampEg);
    safelyDisposeToneNode(ampEgGainParam);
    safelyDisposeToneNode(osc1MuteAmp);
    safelyDisposeToneNode(osc2MuteAmp);
    safelyDisposeToneNode(osc3MuteAmp);
    safelyDisposeToneNode(ampLfoPitch);
    safelyDisposeToneNode(ampLfoCutoff);
    safelyDisposeToneNode(lfoAmpWaveShaper);
    safelyDisposeToneNode(ampLfoAmp);
    safelyDisposeToneNode(oscLfo);
    safelyDisposeToneNode(oscFreqNode);

    [1, 2, 3].forEach(index => {
      safelyDisposeToneNode(osc[index]);
    });

    oscLfo = null;
    osc = [null, null, null, null];
  };
};
