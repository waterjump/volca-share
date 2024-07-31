VS.AudioEngine = function(patch, sequence) {
  // ===================================================================
  // THIS IS THE ONLY COMPONENT THAT SHOULD INTERACT WITH AUDIO CONTEXT
  // ===================================================================

  const audioCtx = new AudioContext();
  const myToneCtx = new Tone.Context({context: audioCtx, lookAhead: 0.1})
  this.notePlaying = new Tone.Param(audioCtx.createGain().gain);
  const attackEndTime = new Tone.Param(audioCtx.createGain().gain);
  const masterAmp = audioCtx.createGain();
  const preAmp = audioCtx.createGain();
  const filter = audioCtx.createBiquadFilter();
  const filterEgAmp = audioCtx.createGain();
  const filterEg = audioCtx.createConstantSource();
  const filterEgOffsetParam = new Tone.Param(filterEg.offset);
  const ampEg = audioCtx.createGain();
  const ampEgGainParam = new Tone.Param(ampEg.gain);
  const osc1MuteAmp = audioCtx.createGain();
  const osc2MuteAmp = audioCtx.createGain();
  const osc3MuteAmp = audioCtx.createGain();
  const oscMuteAmps = [null, osc1MuteAmp, osc2MuteAmp, osc3MuteAmp];
  const ampLfoPitch = audioCtx.createGain()
  const ampLfoCutoff = audioCtx.createGain()
  const lfoAmpWaveShaper = audioCtx.createWaveShaper();
  const builtInDecay = 0.1;
  let osc = [null, null, null, null];
  let sequencerPlaying = false;

  // TODO: Encampsulate this setup script in its own function.

  // An amp used for modulating amplitude without overriding
  //  the master Amp level
  preAmp.connect(masterAmp);

  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(patch.filter.cutoff, audioCtx.currentTime);
  filter.Q.value = patch.filter.peak;
  filter.connect(preAmp);

  filterEgAmp.gain.setValueAtTime(patch.envelope.cutoffEgInt, audioCtx.currentTime);
  filterEgAmp.connect(filter.detune);

  filterEg.offset.setValueAtTime(0, audioCtx.currentTime);
  filterEg.connect(filterEgAmp);
  filterEg.start();


  ampEg.gain.setValueAtTime(0, audioCtx.currentTime);
  ampEg.connect(filter);

  ampEgGainParam.setValueAtTime(0, audioCtx.currentTime);

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
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, audioCtx.currentTime);
    } else {
      // Do not affect pitch
      ampLfoPitch.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  this.setAmpLfoPitchGain();

  this.setAmpLfoCutoffGain = function() {
    if (patch.lfo.targetCutoff) {
      // Affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, audioCtx.currentTime);
    } else {
      // Do not affect filter cutoff
      ampLfoCutoff.gain.setValueAtTime(0, audioCtx.currentTime);
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

  const ampLfoAmp = audioCtx.createGain()
  this.setAmpLfoAmpGain = function() {
    if (patch.lfo.targetAmp) {
      // Affect amp
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, audioCtx.currentTime);
    } else {
      // Do not affect amp
      ampLfoAmp.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  }
  this.setAmpLfoAmpGain();


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

  // ==========================
  //  get browser capabilities
  // ==========================
  const browserFeatures = {};

  const checkCustomCurveClearing = function() {
    let dummyGain = audioCtx.createGain();
    dummyGain.gain.setValueCurveAtTime([0, 0.5, 0], audioCtx.currentTime, 2.6);
    try {
      dummyGain.gain.cancelScheduledValues(audioCtx.currentTime + 0.1);
      dummyGain.gain.setValueAtTime(1, audioCtx.currentTime + 0.2);
      browserFeatures['customCurveClearing'] = true;
    } catch (error) {
      browserFeatures['customCurveClearing'] = false;
    }
  };

  const checkCancelAndHoldAtTime = function() {
    let dummyGain = audioCtx.createGain();
    dummyGain.gain.setValueAtTime(0.5, audioCtx.currentTime);
    try {
      dummyGain.gain.cancelAndHoldAtTime(audioCtx.currentTime + 0.1);
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

  this.showPerformanceWarning = () => {
    return !browserFeatures['cancelAndHoldAtTime'];
  };

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
    setTempo();

    let i = 0;
    let previousStep;

    Tone.Transport.scheduleRepeat(function(time) {
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

  this.init = () => {
    Tone.setContext(myToneCtx);
    Tone.start();
    masterAmp.connect(audioCtx.destination);
  };

  this.activateAudio = function() {
    if (audioCtx.state === 'running') { return; }

    audioCtx.resume().then(() => {
      Tone.context.resume();
      Tone.start();
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
    filterEgOffsetParam.linearRampToValueAtTime(
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

  this.playNewNote = function(time = audioCtx.currentTime) {
    debugNewNote = audioCtx.currentTime;
    this.activateAudio();
    let frequency;

    // Filter EG reset
    filterEgOffsetParam.cancelAndHoldAtTime(time);

    const attackEndTimeValue = time + patch.envelope.attack;
    attackEndTime.setValueAtTime(attackEndTimeValue, time);

    // Amp EG reset
    ampEgGainParam.cancelAndHoldAtTime(time);

    // Set frequency
    frequency = Tone.Frequency(this.notePlaying.getValueAtTime(time), 'midi').toFrequency();
    oscFreqNodeOffsetParam.setValueAtTime(frequency, time);

    if (patch.ampEgOn && patch.envelope.attack > 0) {
      ampEgGainParam.setValueAtTime(0, time);
      ampEgGainParam.linearRampToValueAtTime(1, attackEndTimeValue);
    } else {
      ampEgGainParam.setValueAtTime(1, time);
    }

    retriggerLfo();

    // Retrigger envelope
    // Attack
    filterEgOffsetParam.setValueAtTime(0, time);
    filterEgOffsetParam.linearRampToValueAtTime(1, attackEndTimeValue);

    // Decay
    if (!patch.sustainOn) {
      triggerDecay(attackEndTimeValue);
    }
  };

  this.changeCurrentNote = function(time = audioCtx.currentTime) {
    let frequency = Tone.Frequency(this.notePlaying.getValueAtTime(time), 'midi').toFrequency();
    let lastFrequency = oscFreqNodeOffsetParam.getValueAtTime(time);

    oscFreqNodeOffsetParam.setValueAtTime(lastFrequency, time);
    oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + 0.05);
  };

  this.stopNote = function(time = audioCtx.currentTime) {
    // console.log('QDEBUG:', time - debugNewNote);
    const currentValue = ampEgGainParam.getValueAtTime(time);

    // If note is already off, don't bother stopping it.
    if (currentValue === 0) { return; }

    if (patch.ampEgOn) {
      if (patch.sustainOn || (time < attackEndTime.getValueAtTime(time))) {

        // filter envelope
        filterEgOffsetParam.cancelAndHoldAtTime(time);

        // TODO: Use custom curve for filter?
        filterEgOffsetParam.linearRampToValueAtTime(
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
      filterEg.offset.cancelScheduledValues(time);
      filterEg.offset.setValueAtTime(0, time);

      // Turn amp down immediately
      ampEgGainParam.setValueAtTime(1, time);
      ampEgGainParam.linearRampToValueAtTime(0, time + builtInDecay);
    }
  };

  // CHANGE OCTAVE
  this.changeOctave = (octaveOffset, time = audioCtx.currentTime) => {
    this.notePlaying.setValueAtTime(
      this.notePlaying.getValueAtTime(time) + octaveOffset,
      time
    );

    const frequency =
      Tone.Frequency(this.notePlaying.getValueAtTime(time), 'midi').toFrequency();

    oscFreqNodeOffsetParam.setValueAtTime(frequency, time);
  };

  this.setPeak = (value) => {
    filter.Q.value = value;
  };

  this.setCutoff = (value, time = audioCtx.currentTime) => {
    filter.frequency.setValueAtTime(value, time);
  };

  this.setFilterEgInt = (value, time = audioCtx.currentTime) => {
    filterEgAmp.gain.setValueAtTime(value, time);
  };

  this.setVolume = (value, time = audioCtx.currentTime) => {
    masterAmp.gain.setValueAtTime(value, time);
  };

  this.setOscMuteAmp = (oscNumber, value) => {
    oscMuteAmps[oscNumber].gain.setValueAtTime(value, audioCtx.currentTime);
  };

  this.setLfoRate = (value) => {
    oscLfo.frequency.setValueAtTime(value, audioCtx.currentTime);
  };

  this.setLfoWave = (value) => {
    oscLfo.type = value;
  }

  this.setLfoInt = (value) => {
    // TODO: Think about calling setAmpLfoPitchGain() here maybe.  And for others.
    if (patch.lfo.targetPitch) {
      ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, audioCtx.currentTime);
    }

    if (patch.lfo.targetCutoff) {
      ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, audioCtx.currentTime);
    }

    if (patch.lfo.targetAmp) {
      ampLfoAmp.gain.setValueAtTime(patch.lfo.ampValue, audioCtx.currentTime);
    }
  };

  this.setNotePlaying = (value, time = audioCtx.currentTime) => {
    this.notePlaying.setValueAtTime(value, time);
  };

  this.getNotePlaying = () => {
    return this.notePlaying.getValueAtTime(audioCtx.currentTime);
  };

  this.setOscPitch = (index, value) => {
    osc[index].detune.setValueAtTime(value, audioCtx.currentTime);
  };

  this.setTempo = () => {
    setTempo();
  };

  this.startSequencer = () => {
    sequencerPlaying = true;
    Tone.Transport.start('+0');
  };

  this.stopSequencer = () => {
    sequencerPlaying = false;
    Tone.Transport.stop();
    this.stopNote(Tone.now() + 0.2);
  };

  this.getSequencerPlaying = () => {
    return sequencerPlaying;
  };

  this.setSequencerPlaying = (value) => {
    sequencerPlaying = value;
  };

  this.getOsc = (index) => {
    return osc[index];
  };

  this.setOscShape = (index, value) => {
    osc[index].type = value;
  };
};
