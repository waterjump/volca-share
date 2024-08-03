VS.KeysAudioEngine = function(patch) {
  // ===================================================================
  // THIS IS THE ONLY COMPONENT THAT SHOULD INTERACT WITH AUDIO CONTEXT
  // ===================================================================

  const audioCtx = new AudioContext();
  const myToneCtx = new Tone.Context({context: audioCtx, lookAhead: 0.1})
  this.notePlaying = new Tone.Param(audioCtx.createGain().gain);
  const attackEndTime = new Tone.Param(audioCtx.createGain().gain);
  const masterAmp = audioCtx.createGain();
  const filter = audioCtx.createBiquadFilter();
  const filterEgAmp = audioCtx.createGain();
  const filterEg = audioCtx.createConstantSource();
  const filterEgOffsetParam = new Tone.Param(filterEg.offset);
  const ampEg = audioCtx.createGain();
  const ampEgGainParam = new Tone.Param(ampEg.gain);
  const ampLfoPitch = audioCtx.createGain()
  const ampLfoCutoff = audioCtx.createGain()
  const builtInDecay = 0.1;
  let osc = [null, null, null, null];
  let sequencerPlaying = false;

  // TODO: Encampsulate this setup script in its own function.

  // BEGIN delay
  const delay = audioCtx.createDelay();
  delay.delayTime.setValueAtTime(0.2, audioCtx.currentTime);

  const delayFilter = audioCtx.createBiquadFilter();
  delayFilter.type = 'lowpass';
  delayFilter.Q.value = 0;
  delayFilter.frequency.setValueAtTime(2000, audioCtx.currentTime);

  const delayAmp = audioCtx.createGain();
  delayAmp.gain.setValueAtTime(patch.delay.feedback, audioCtx.currentTime);
  delay.connect(delayFilter);
  delayFilter.connect(delayAmp);
  delayAmp.connect(masterAmp);
  delayAmp.connect(delay);
  // END delay

  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(patch.filter.cutoff, audioCtx.currentTime);
  filter.Q.value = patch.filter.peak;
  filter.connect(masterAmp);
  filter.connect(delay);

  filterEgAmp.gain.setValueAtTime(patch.vcf_eg_int, audioCtx.currentTime);
  filterEgAmp.connect(filter.detune);

  filterEg.offset.setValueAtTime(0, audioCtx.currentTime);
  filterEg.connect(filterEgAmp);
  filterEg.start();


  ampEg.gain.setValueAtTime(0, audioCtx.currentTime);
  ampEg.connect(filter);

  ampEgGainParam.setValueAtTime(0, audioCtx.currentTime);

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



  let oscLfo;

  const setupOscLfo = function() {
    oscLfo = audioCtx.createOscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, audioCtx.currentTime);
    oscLfo.connect(ampLfoPitch);
    oscLfo.connect(ampLfoCutoff);
    oscLfo.start();
  }

  setupOscLfo();

  const thruGainSwitchController = audioCtx.createConstantSource();
  thruGainSwitchController.offset.setValueAtTime(patch.defaultVcoAmp, audioCtx.currentTime);

  const modGainSwitchController = audioCtx.createConstantSource();
  modGainSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);

  const modGain2 = audioCtx.createGain();
  modGain2.gain.value = 0;

  const modGain3 = audioCtx.createGain();
  modGain3.gain.value = 0;
  modGain2.connect(modGain3);
  modGain3.connect(ampEg);

  const oscPolyMonoAmp2 = audioCtx.createGain();
  oscPolyMonoAmp2.gain.value = 1;
  const oscPolyMonoAmp3 = audioCtx.createGain();
  oscPolyMonoAmp3.gain.value = 1;

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
    ampLfoPitch.connect(oscillator.detune);

    const thruGain = audioCtx.createGain();
    thruGain.gain.value = 0;
    thruGainSwitchController.connect(thruGain.gain);
    thruGain.connect(ampEg);

    const modGainSwitch = audioCtx.createGain();
    modGainSwitch.gain.value = 0;
    modGainSwitchController.connect(modGainSwitch.gain);

    if (oscNumber === 1) {
      oscillator.connect(thruGain);
      oscillator.connect(modGainSwitch);
      modGainSwitch.connect(modGain2); // carrier
    } else if ( oscNumber === 2) {
      oscillator.connect(oscPolyMonoAmp2);
      oscPolyMonoAmp2.connect(thruGain);
      oscPolyMonoAmp2.connect(modGainSwitch);
      modGainSwitch.connect(modGain2.gain); // modulator
    } else {
      oscillator.connect(oscPolyMonoAmp3);
      oscPolyMonoAmp3.connect(thruGain);
      oscPolyMonoAmp3.connect(modGainSwitch);
      modGainSwitch.connect(modGain3.gain); // modulator
    }
    oscillator.start();
  });

  thruGainSwitchController.start();
  modGainSwitchController.start();

  const voiceOscDetuner3 = audioCtx.createConstantSource();
  voiceOscDetuner3.offset.setValueAtTime(0, audioCtx.currentTime);
  voiceOscDetuner3.connect(osc[3].detune);
  voiceOscDetuner3.start();


  const unisonNoteAmp2 = audioCtx.createGain();
  unisonNoteAmp2.gain.value = 0;
  const unisonNoteAmp3 = audioCtx.createGain();
  unisonNoteAmp3.gain.value = 0;

  // TODO: The oscillators "base frequency" are not all the same in the keys.
  // controls frequency of all three vcos rather than looping through them.
  const oscFreqNode = audioCtx.createConstantSource();
  oscFreqNode.offset.setValueAtTime(440, audioCtx.currentTime);
  oscFreqNode.connect(osc[1].frequency);
  oscFreqNode.connect(unisonNoteAmp2);
  oscFreqNode.connect(unisonNoteAmp3);
  unisonNoteAmp2.connect(osc[2].frequency);
  unisonNoteAmp3.connect(osc[3].frequency);
  oscFreqNode.start();

  const oscFreqNodeOffsetParam = new Tone.Param(oscFreqNode.offset);

  const oscFreqNode2 = audioCtx.createConstantSource();
  oscFreqNode2.offset.setValueAtTime(440, audioCtx.currentTime);
  const polyNoteAmp2 = audioCtx.createGain();
  polyNoteAmp2.gain.value = 0;
  oscFreqNode2.connect(polyNoteAmp2);
  polyNoteAmp2.connect(osc[2].frequency);
  oscFreqNode2.start();

  const oscFreqNode3 = audioCtx.createConstantSource();
  oscFreqNode3.offset.setValueAtTime(440, audioCtx.currentTime);
  const polyNoteAmp3 = audioCtx.createGain();
  polyNoteAmp3.gain.value = 0;
  oscFreqNode3.connect(polyNoteAmp3);
  polyNoteAmp3.connect(osc[3].frequency);
  oscFreqNode3.start();

  // Switch for unison note frequencies
  const unisonNoteSwitchController = audioCtx.createConstantSource();
  unisonNoteSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
  unisonNoteSwitchController.connect(unisonNoteAmp2.gain);
  unisonNoteSwitchController.connect(unisonNoteAmp3.gain);
  unisonNoteSwitchController.start();

  // Switch for poly note frequencies
  const polyNoteSwitchController = audioCtx.createConstantSource();
  polyNoteSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
  polyNoteSwitchController.connect(polyNoteAmp2.gain);
  polyNoteSwitchController.connect(polyNoteAmp3.gain);
  polyNoteSwitchController.start();

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

const runToneSequencer = function() {
  setTempo();

  let i = 0;
  let previousStep;

  // Calculate tempo-based gate duration only once

    Tone.Transport.scheduleRepeat(function(time) {
      if (!sequencerPlaying) return;

      let activeStepFound = false;

      // Find the next active step
      for (let j = 0; j < 16; j++) {
        i = i % 16;
        if (sequence[i].activeStep) {
          activeStepFound = true;
          break;
        }
        i++;
      }

      // Bail out if no active steps are found
      if (!activeStepFound) return;
      const gateDurationFactor = 0.58 * (60 / (patch.tempo * 4));

      const gateEnd = time + gateDurationFactor;

      let currentStep = sequence[i];
      this.setNotePlaying(currentStep.note, time);

      // Simplified logic for handling step mode and slide
      if (currentStep.stepMode) {
        if (previousStep && previousStep.slide) {
          if (previousStep.stepMode) {
            this.changeCurrentNote(time);
          } else {
            this.playNewNote(time);
            if (!currentStep.slide) {
              this.stopNote(gateEnd);
            }
          }
        } else {
          this.playNewNote(time);
          if (!currentStep.slide) {
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

    // Set frequency of all oscillators
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

    // TODO: Use patch.portamento instead of 0.05
    oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + 0.05);
  };

  // Poly voices only!
  this.addNote = function(keysDown) {
    if (keysDown.length === 2) {
      const frequency2 = Tone.Frequency(keysDown[1], 'midi').toFrequency();
      oscFreqNode2.offset.setValueAtTime(frequency2, audioCtx.currentTime);
      oscPolyMonoAmp2.gain.setValueAtTime(1, audioCtx.currentTime);
    } else if (keysDown.length === 3) {
      const frequency3 = Tone.Frequency(keysDown[2], 'midi').toFrequency();
      oscFreqNode3.offset.setValueAtTime(frequency3, audioCtx.currentTime);
      oscPolyMonoAmp3.gain.setValueAtTime(1, audioCtx.currentTime);
    } else if (keysDown.length > 3) {
      // TODO: Behavior of actual synth is the replace the note nearest to it,
      //       replacing the higher note if its exactly between two.
      const frequency3 = Tone.Frequency(keysDown[keysDown.length - 1], 'midi').toFrequency();
      oscFreqNode3.offset.setValueAtTime(frequency3, audioCtx.currentTime);
    }
  };

  this.stopPolyNote = function(keysDown) {
    if (keysDown.length === 1) {
      oscPolyMonoAmp2.gain.setValueAtTime(0, audioCtx.currentTime);
    } else if (keysDown.length === 2) {
      oscPolyMonoAmp3.gain.setValueAtTime(0, audioCtx.currentTime);
    } else if (keysDown.length > 2) {
      // TODO: Behavior of actual synth is the replace the note nearest to it,
      //       replacing the higher note if its exactly between two.

      // change osc3 to last note in keysDown
      const frequency3 = Tone.Frequency(keysDown[keysDown.length - 1], 'midi').toFrequency();
      oscFreqNode3.offset.setValueAtTime(frequency3, audioCtx.currentTime);
    }
  };

  this.changeVoice = function() {
    /*
    Voices implemented:
    [X] poly
    [X] unison
    [X] octave and
    [X] fifth
    [X] unison ring
    [ ] poly ring

    TODO: Try to break out the configurations of different voices
          into an object or something.
    */
    voiceOscDetuner3.offset.setValueAtTime(patch.vco[3].voiceDetune, audioCtx.currentTime);

    osc.forEach((oscillator, index) => {
      if (oscillator !== null) {
        oscillator.type = patch.vco[index].shape;
      }
    });

    if(patch.voice.includes('poly')) {
      console.log('poly ');
      oscPolyMonoAmp2.gain.setValueAtTime(0, audioCtx.currentTime);
      oscPolyMonoAmp3.gain.setValueAtTime(0, audioCtx.currentTime);
      unisonNoteSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
      polyNoteSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
    } else {
      console.log('unison');
      oscPolyMonoAmp2.gain.setValueAtTime(1, audioCtx.currentTime);
      oscPolyMonoAmp3.gain.setValueAtTime(1, audioCtx.currentTime);
      unisonNoteSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
      polyNoteSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
    }

    if (patch.voice.includes('ring')) {
      console.log('...ring');
      thruGainSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
      modGainSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
    } else {
      thruGainSwitchController.offset.setValueAtTime(patch.defaultVcoAmp, audioCtx.currentTime);
      modGainSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
    }
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

  this.setDetune = () => {
    osc[1].detune.setValueAtTime(patch.vco[1].detune, audioCtx.currentTime);
    osc[3].detune.setValueAtTime(patch.vco[3].detune, audioCtx.currentTime);
  };

  this.setDelayTime = () => {
    delay.delayTime.setValueAtTime(patch.delay.time, audioCtx.currentTime);
  };

  this.setDelayFeedback = () => {
    delayAmp.gain.setValueAtTime(patch.delay.feedback, audioCtx.currentTime);
  };
};
