VS.KeysAudioEngine = function(patch, sequence = [], options = {}) {
  // ===================================================================
  // THIS IS THE ONLY COMPONENT THAT SHOULD INTERACT WITH TONE.JS
  // ===================================================================

  const masterAmp = new Tone.Gain();
  const filter = new Tone.BiquadFilter();
  const filterEgAmp = new Tone.Gain();
  const ampEg = new Tone.Gain();
  const universalEg = new Tone.Signal();
  const vcoEgShaper = new Tone.WaveShaper();
  const vcoEgIntAmp = new Tone.Gain();
  const ampLfoPitch = new Tone.Gain();
  const ampLfoCutoff = new Tone.Gain();
  const gracePeriod = 0.05; // 50ms
  const carrierGain = 0.5; // so ring mod voices aren't super loud
  const sequencerEnabled = options.enableSequencer !== false;
  let sequencerPlaying = false;
  let disposed = false;
  let sequencerEventId = null;

  const makeVcoEgShaperCurve = function() {
    const curve = new Float32Array(256);
    const sustain = patch.envelope.sustain;

    for (let i = 0; i < 256; i++) {
      // Counterintuitively, the shaper is excepting -1 to 1 range even
      // though it appears that the universalEg outputs values
      // in range 0 to 1.  Not sure why, but this works.
      const x = (i - 128) / 128; // Normalize input range (-1 to 1)

      curve[i] = x - sustain;
    }
    return curve;
  }

  vcoEgShaper.curve = makeVcoEgShaperCurve();
  vcoEgShaper.oversample = 'none';

  // TODO: Encampsulate this setup script in its own function.

  // BEGIN delay
  const delay = new Tone.Delay();
  delay.delayTime.setValueAtTime(0.2, Tone.now());

  const delayFilter = new Tone.BiquadFilter();
  delayFilter.type = 'lowpass';
  delayFilter.Q.value = 0;
  delayFilter.frequency.setValueAtTime(1000, Tone.now());

  const delayAmp = new Tone.Gain();
  delayAmp.gain.setValueAtTime(patch.delay.feedback, Tone.now());
  delay.connect(delayFilter);
  delayFilter.connect(delayAmp);
  delayAmp.connect(masterAmp);
  delayAmp.connect(delay);
  // END delay

  filter.type = 'lowpass';
  filter.frequency.setValueAtTime(patch.filter.cutoff, Tone.now());
  filter.Q.value = patch.filter.peak;
  filter.connect(masterAmp);
  filter.connect(delay);

  filterEgAmp.gain.setValueAtTime(patch.vcf_eg_int, Tone.now());
  filterEgAmp.connect(filter.detune);

  ampEg.gain.setValueAtTime(0, Tone.now());
  ampEg.connect(filter);

  ampLfoCutoff.connect(filter.detune);

  let oscLfo;

  //  This is needed to flip the LFO wave upside down so the sawtooth wave
  //  slopes top to bottom and not bottom to top.
  const lfoWaveShaper = new Tone.WaveShaper();
  lfoWaveShaper.curve = new Float32Array([1, 0, -1]);

  const setupOscLfo = function() {
    oscLfo = new Tone.Oscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, Tone.now());

    if (patch.lfo.shape === 'square') {
      // Don't invert the square LFO
      lfoWaveShaper.disconnect();
      oscLfo.connect(ampLfoPitch);
      oscLfo.connect(ampLfoCutoff);
    } else {
      oscLfo.connect(lfoWaveShaper);
      lfoWaveShaper.connect(ampLfoPitch);
      lfoWaveShaper.connect(ampLfoCutoff);
    }

    oscLfo.start();
  }

  setupOscLfo();

  const thruGainSwitchController = new Tone.Signal();
  thruGainSwitchController.setValueAtTime(1, Tone.now());

  const modGainSwitchController = new Tone.Signal();
  modGainSwitchController.setValueAtTime(0, Tone.now());

  // Early outputs for one and two note poly ring scenarios.
  // The modGain amps are off by default unless that note of polyphony is
  // playing.  The amps provide a bypass for when less notes are playing.
  const oneNotePolyRingAmp = new Tone.Gain();
  oneNotePolyRingAmp.gain.value = 0;
  oneNotePolyRingAmp.connect(ampEg);
  const twoNotePolyRingAmp = new Tone.Gain();
  twoNotePolyRingAmp.gain.value = 0;
  twoNotePolyRingAmp.connect(ampEg);

  const modGain2 = new Tone.Gain();
  modGain2.gain.value = 0;

  const modGain3 = new Tone.Gain();
  modGain3.gain.value = 0;
  modGain2.connect(twoNotePolyRingAmp);
  modGain2.connect(modGain3);
  modGain3.connect(ampEg);

  vcoEgIntAmp.gain.setValueAtTime(0, Tone.now());

  const oscillatorObj = function(oscNumber) {
    this.oscNumber = oscNumber;
    this.oscFreqNode = new Tone.Signal();
    this.oscillator = new Tone.Oscillator();
    this.volumeAmp = new Tone.Gain();
    this.oscAmp = new Tone.Gain();
    this.thruGain = new Tone.Gain();
    this.modGainSwitch = new Tone.Gain();
    this.modGain2CarrierAmp = new Tone.Gain();
    this.modGain2ModAmp = new Tone.Gain();
    this.modGain3ModAmp = new Tone.Gain();
    this.note = -1;
    this.setFrequency = function(value) {};

    this.turnOnOscAmp = function(time = Tone.now()) {
      this.oscAmp.gain.cancelScheduledValues(time);
      this.oscAmp.gain.setValueAtTime(1, time);
    };

    this.turnOffOscAmp = function(time = Tone.now()) {
      this.oscAmp.gain.cancelScheduledValues(time);
      this.oscAmp.gain.setValueAtTime(0, time);
    };

    this.setRingModPath = function(time = Tone.now(), isRingOut = false) {
      if (patch.voice !== 'poly ring') { return; }
      const actionTime = isRingOut ? time + patch.envelope.decayRelease : time;
      const ringModPaths = [
        this.modGain2CarrierAmp,
        this.modGain2ModAmp,
        this.modGain3ModAmp
      ];

      const currentNotesSorted = Object.values(oscillators)
        .map(osc => osc.note)
        .filter(note => note !== -1)
        .sort((a, b) => a - b);

      const indexOfAmpToTurnOn = currentNotesSorted.indexOf(this.note);
      if (indexOfAmpToTurnOn === 0) {
        this.volumeAmp.gain.setValueAtTime(carrierGain, time);
      } else {
        this.volumeAmp.gain.setValueAtTime(1, time);
      }

      ringModPaths.forEach((amp, index) => {
        const gainValue = index === indexOfAmpToTurnOn ? 1 : 0;
        amp.gain.cancelScheduledValues(time);
        amp.gain.setValueAtTime(gainValue, actionTime);
      });
    };

    this.initialize = function() {
      this.oscFreqNode.setValueAtTime(440, Tone.now());
      // Set up osc
      this.oscillator.type = patch.vco[this.oscNumber].shape;
      this.oscillator.detune.setValueAtTime(
        patch.vco[this.oscNumber].detune,
        Tone.now()
      );
      this.oscillator.frequency.setValueAtTime(0, Tone.now());
      ampLfoPitch.connect(this.oscillator.detune);
      vcoEgIntAmp.connect(this.oscillator.detune);

      this.oscillator.connect(this.volumeAmp);
      this.volumeAmp.gain.setValueAtTime(patch.defaultVcoAmp, Tone.now());
      this.volumeAmp.connect(this.oscAmp);
      this.oscAmp.connect(this.thruGain);
      this.oscAmp.connect(this.modGainSwitch);

      this.thruGain.gain.value = 0;
      thruGainSwitchController.connect(this.thruGain.gain);
      this.thruGain.connect(ampEg);

      this.modGainSwitch.gain.value = 0;
      modGainSwitchController.connect(this.modGainSwitch.gain);
      this.modGainSwitch.connect(oneNotePolyRingAmp);

      this.modGain2CarrierAmp.gain.value = 0;
      this.modGain2ModAmp.gain.value = 0;
      this.modGain3ModAmp.gain.value = 0;

      this.modGainSwitch.connect(this.modGain2CarrierAmp);
      this.modGain2CarrierAmp.connect(modGain2);
      this.modGainSwitch.connect(this.modGain2ModAmp);
      this.modGain2ModAmp.connect(modGain2.gain);
      this.modGainSwitch.connect(this.modGain3ModAmp);
      this.modGain3ModAmp.connect(modGain3.gain);

      this.oscillator.start();
    }

    this.initialize();
  };

  const oscillators = {
    1: new oscillatorObj(1),
    2: new oscillatorObj(2),
    3: new oscillatorObj(3)
  };

  universalEg.setValueAtTime(0, Tone.now());
  universalEg.connect(filterEgAmp);
  universalEg.connect(ampEg.gain);
  universalEg.connect(vcoEgShaper);
  vcoEgShaper.connect(vcoEgIntAmp);

  const voiceOscDetuner1 = new Tone.Signal();
  voiceOscDetuner1.setValueAtTime(0, Tone.now());
  voiceOscDetuner1.connect(oscillators[1].oscillator.detune);

  const voiceOscDetuner3 = new Tone.Signal();
  voiceOscDetuner3.setValueAtTime(0, Tone.now());
  voiceOscDetuner3.connect(oscillators[3].oscillator.detune);

  const unisonNoteAmp2 = new Tone.Gain();
  unisonNoteAmp2.gain.value = 0;
  const unisonNoteAmp3 = new Tone.Gain();
  unisonNoteAmp3.gain.value = 0;


  // Setup oscillator specific note frequency control
  oscillators[1].oscFreqNode.connect(oscillators[1].oscillator.frequency);
  oscillators[1].oscFreqNode.connect(unisonNoteAmp2);
  oscillators[1].oscFreqNode.connect(unisonNoteAmp3);
  unisonNoteAmp2.connect(oscillators[2].oscillator.frequency);
  unisonNoteAmp3.connect(oscillators[3].oscillator.frequency);

  const polyNoteAmp2 = new Tone.Gain();
  polyNoteAmp2.gain.value = 0;
  oscillators[2].oscFreqNode.connect(polyNoteAmp2);
  polyNoteAmp2.connect(oscillators[2].oscillator.frequency);

  const polyNoteAmp3 = new Tone.Gain();
  polyNoteAmp3.gain.value = 0;
  oscillators[3].oscFreqNode.connect(polyNoteAmp3);
  polyNoteAmp3.connect(oscillators[3].oscillator.frequency);



  // Switch for unison note frequencies
  const unisonNoteSwitchController = new Tone.Signal();
  unisonNoteSwitchController.setValueAtTime(1, Tone.now());
  unisonNoteSwitchController.connect(unisonNoteAmp2.gain);
  unisonNoteSwitchController.connect(unisonNoteAmp3.gain);

  // Switch for poly note frequencies
  const polyNoteSwitchController = new Tone.Signal();
  polyNoteSwitchController.setValueAtTime(0, Tone.now());
  polyNoteSwitchController.connect(polyNoteAmp2.gain);
  polyNoteSwitchController.connect(polyNoteAmp3.gain);

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

  this.currentStepIndex = 0;

  const runToneSequencer = function(){
    if (!sequencerEnabled) { return; }
    setTempo();

    // let i = 0;
    let previousStep;

    sequencerEventId = Tone.Transport.scheduleRepeat(function(time) {
      let i = this.currentStepIndex;
      if (!sequencerPlaying) { return; }

      while (!sequence[i % 16].activeStep) {
        // Bail out if all steps are inactive
        if (!sequence.some(step => { return step.activeStep })) { return; }
        this.currentStepIndex++;
      }

      const gateEnd = time + 0.58 * (60 / (patch.tempo * 4));

      let currentStep = sequence[i % 16];

      previousSlide = i > 0 && previousStep.slide && !patch.step_trigger
      currentSlide = currentStep.slide && !patch.step_trigger

      if (previousSlide) {
        this.changeCurrentNote(currentStep.note, time);
        if (!currentSlide) {
          this.triggerSequencerRelease(gateEnd);
        }
      } else {
        this.playNewNote(currentStep.note, time);
        if (!currentSlide) {
          this.triggerSequencerRelease(gateEnd);
        }
      }

      previousStep = currentStep;
      this.currentStepIndex++;
    }.bind(this), '16n');
  }.bind(this);

  runToneSequencer();

  const setInitialEngineValues = function() {
    this.changeVoice();
    this.setDetune();
    this.setVcoEgInt();
    this.setCutoff(patch.filter.cutoff);
    this.setPeak(patch.filter.peak);
    this.setFilterEgInt(patch.vcf_eg_int);
    this.setLfoRate(patch.lfo.frequency);
    this.setLfoPitchInt();
    this.setLfoCutoffInt();
    this.setLfoWave();
    this.setDelayTime();
    this.setDelayFeedback();
  }.bind(this);

  const canInteract = function() {
    return !disposed;
  };

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
    setInitialEngineValues();
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
    const lfo = patch.lfo;
    if (!lfo.triggerSync) { return; }
    if (lfo.pitchValue + lfo.cutoffValue === 0) { return; }

    oscLfo.disconnect();
    oscLfo = null;
    setupOscLfo();
  };

  const triggerDecayRelease = function(time = Tone.now(), forceRelease = false) {
    let isDecay, duration;

    if (forceRelease) {
      isDecay = false;
    } else {
      isDecay = Object.values(oscillators).some(osc => osc.note !== -1);
    }

    const endValue = isDecay ? patch.envelope.sustain : 0;
    const currentValue = universalEg.getValueAtTime(time);

    if (currentValue === 0) { return; }

    if (isDecay) {
      universalEg.setValueAtTime(1, time);
      duration = patch.envelope.decayRelease;
    } else {
      universalEg.cancelAndHoldAtTime(time); // kill attack in progress
      universalEg.setValueAtTime(currentValue, time);  // stop at current value
      duration = currentValue * patch.envelope.decayRelease;
    }

    if (browserFeatures['customCurveClearing']) {
      // use custom curve (scaled to amount between current and end values)
      const gainCurve = VS.emulatorConstants.decayReleaseGainCurve.map(
        function(value) { return value * (currentValue - endValue) + endValue }
      );
      universalEg.setValueCurveAtTime(gainCurve, time, duration);
    } else {
      universalEg.linearRampToValueAtTime(endValue, time + duration)
    }
  };

  const triggerEg = function(time = Tone.now()) {
    const attackEndTimeValue = time + patch.envelope.attack;

    // Amp EG reset
    universalEg.cancelAndHoldAtTime(time);

    if (patch.envelope.attack > 0) {
      universalEg.setValueAtTime(0, time);
      universalEg.linearRampToValueAtTime(1, attackEndTimeValue);
    } else {
      universalEg.setValueAtTime(1, time);
    }

    retriggerLfo();

    // Decay
    triggerDecayRelease(attackEndTimeValue);
  };

  const turnOnAllOscAmps = function(time = Tone.now()) {
    Object.values(oscillators).forEach(obj => obj.turnOnOscAmp());
  };

  this.playNewNote = function(note, time = Tone.now()) {
    if (!canInteract()) { return; }

    if (toneState() !== 'running') {
      this.activateAudio().then((activated) => {
        if (!activated || !canInteract()) { return; }
        this.playNewNote(note, Tone.now());
      }).catch(() => {});
      return;
    }

    if (!patch.voice.includes('poly')) {
      turnOnAllOscAmps();
    } else {
      oscillators[1].turnOnOscAmp();
      oscillators[2].turnOffOscAmp();
      oscillators[3].turnOffOscAmp();
    }

    if (patch.voice === 'poly ring') {
      oneNotePolyRingAmp.gain.cancelScheduledValues(time);
      twoNotePolyRingAmp.gain.cancelScheduledValues(time);
      oneNotePolyRingAmp.gain.setValueAtTime(1, time);
    }

    // Set frequency of oscillators
    oscillators[1].note = note;
    const frequency = Tone.Frequency(note, 'midi').toFrequency();
    oscillators[1].oscFreqNode.setValueAtTime(frequency, time);
    oscillators[1].setRingModPath();

    triggerEg(time);
  };

  // Only used for unison voices
  this.changeCurrentNote = function(note, time = Tone.now()) {
    if (!canInteract()) { return; }
    let frequency = Tone.Frequency(note, 'midi').toFrequency();
    let lastFrequency = oscillators[1].oscFreqNode.getValueAtTime(time);

    oscillators[1].oscFreqNode.setValueAtTime(lastFrequency, time);
    oscillators[1].oscFreqNode.linearRampToValueAtTime(frequency, time + patch.portamento);
  };

  const lowestFreeOscillator = () => {
    return Object.values(oscillators).find(osc => osc.note === -1) || null;
  };

  const findOscillatorPlayingClosestNote = function(target) {
    let closestOsc = null;
    let smallestDifference = Infinity;

    for (let key in oscillators) {
      const currentOsc = oscillators[key];
      const difference = Math.abs(currentOsc.note - target);

      if (
        difference < smallestDifference ||
        (difference === smallestDifference && currentOsc.note > closestOsc.note)
      ) {
        closestOsc = currentOsc;
        smallestDifference = difference;
      }
    }

    return closestOsc;
  };

  const adjustPolyRingAlgo = function(numberOfKeysDown, time = Tone.now(), isRingOut = false) {
    if (patch.voice !== 'poly ring') { return; }

    const actionTime = isRingOut ? time + patch.envelope.decayRelease : time;

    oneNotePolyRingAmp.gain.cancelScheduledValues(time);
    twoNotePolyRingAmp.gain.cancelScheduledValues(time);

    if (numberOfKeysDown === 1) {
      oneNotePolyRingAmp.gain.setValueAtTime(1, actionTime);
      twoNotePolyRingAmp.gain.setValueAtTime(0, actionTime);
    } else if (numberOfKeysDown === 2) {
      oneNotePolyRingAmp.gain.setValueAtTime(0, actionTime);
      twoNotePolyRingAmp.gain.setValueAtTime(1, actionTime);
    } else if (numberOfKeysDown === 3) {
      oneNotePolyRingAmp.gain.setValueAtTime(0, actionTime);
      twoNotePolyRingAmp.gain.setValueAtTime(0, actionTime);
    }
  };

  const swapOscillatorFrequency = function(oscillator, oldFreq, newFreq, time = Tone.now()) {
    const rampEndTime = time + patch.portamento;
    oscillator.oscFreqNode.setValueAtTime(oldFreq, time);
    oscillator.oscFreqNode.linearRampToValueAtTime(newFreq, rampEndTime);
  }

  // Poly voices only!
  this.addNote = function(keysDown, noteToAdd, time = Tone.now()) {
    if (!canInteract()) { return; }

    const lowestFreeOsc = lowestFreeOscillator();
    const frequency = Tone.Frequency(noteToAdd, 'midi').toFrequency();
    const closestOscillator = findOscillatorPlayingClosestNote(noteToAdd);
    const closestNote = closestOscillator.note;
    const closestNoteFrequency = Tone.Frequency(closestNote, 'midi').toFrequency();

    if (patch.portamento > 0.008) {
      triggerEg(time);
    }

    // if there's an unused oscillator
    if (lowestFreeOsc !== null) {
      lowestFreeOsc.note = noteToAdd;

      swapOscillatorFrequency(lowestFreeOsc, closestNoteFrequency, frequency, time);
      lowestFreeOsc.turnOnOscAmp();
    } else {
      // swap closest playing note
      closestOscillator.note = noteToAdd;
      swapOscillatorFrequency(closestOscillator, closestNoteFrequency, frequency, time);
    }

    Object.values(oscillators).forEach(osc => osc.setRingModPath());
    adjustPolyRingAlgo(keysDown.length);
  };

  const findOscByNote = (note) => {
    return Object.values(oscillators).find(osc => osc.note === note) || null;
  };

  const findClosestValue = function(arr, target) {
    return arr.reduce((closest, current) => {
      const closestDiff = Math.abs(closest - target);
      const currentDiff = Math.abs(current - target);

      // If current is closer, or the same distance but greater, update closest
      if (
        currentDiff < closestDiff ||
        (currentDiff === closestDiff && current > closest)
      ) {
        return current;
      } else {
        return closest;
      }
    });
  };

  const swapPolyNote = function(keysDown, noteThatStopped, oscAffected, time = Tone.now()) {
    if (oscAffected === null) { return; }

    // find notes that aren't playing
    const notesStillPlaying = Object.values(oscillators).map(osc => osc.note);
    const notesNotPlaying = keysDown.filter(note => !notesStillPlaying.includes(note));

    let noteToSwapIn;
    if (notesNotPlaying.length === 1) {
      noteToSwapIn = notesNotPlaying[0];
    } else {
      noteToSwapIn = findClosestValue(notesNotPlaying, noteThatStopped);
    }

    const lastFrequency = Tone.Frequency(oscAffected.note, 'midi').toFrequency();
    const frequency = Tone.Frequency(noteToSwapIn, 'midi').toFrequency();
    oscAffected.note = noteToSwapIn;

    swapOscillatorFrequency(oscAffected, lastFrequency, frequency, time);
  };

  const turnOffAllOscAmps = function(time = Tone.now()) {
    const turnOffTime = time + patch.envelope.decayRelease;
    Object.values(oscillators).forEach(obj => {
      obj.oscAmp.gain.cancelScheduledValues(time);
      obj.turnOffOscAmp(turnOffTime);
    });
  };

  this.stopPolyNote = function(keysDown, noteThatStopped, time = Tone.now()) {
    if (!canInteract()) { return; }

    if (keysDown.length === 0) {
      // Ring out
      Object.values(oscillators).forEach(osc => osc.setRingModPath(time, true));
      adjustPolyRingAlgo(keysDown.length, time, true);
      turnOffAllOscAmps();
      [1, 2, 3].forEach(i => oscillators[i].note = -1);
      return;
    }
    if (!patch.voice.includes('poly')) { return; }

    const oscAffected = findOscByNote(noteThatStopped);
    if (oscAffected === null) { return; }

    if (keysDown.length > 2) {
      swapPolyNote(keysDown, noteThatStopped, oscAffected);
    } else {
      oscAffected.note = -1;
      // Schedule note removal after 50ms grace period
      const actionTime = time + gracePeriod;
      Object.values(oscillators).forEach(osc => osc.setRingModPath(actionTime));
      adjustPolyRingAlgo(keysDown.length, actionTime);
      oscAffected.turnOffOscAmp(actionTime);
    }
  };

  this.changeVoice = function() {
    if (!canInteract()) { return; }
    /*
    TODO: Try to break out the configurations of different voices
          into an object or something.
    */
    const time = Tone.now();
    voiceOscDetuner1.setValueAtTime(patch.vco[1].voiceDetune, time);
    voiceOscDetuner3.setValueAtTime(patch.vco[3].voiceDetune, time);

    Object.values(oscillators).forEach(obj => obj.oscillator.type = patch.vco[obj.oscNumber].shape);

    if (patch.voice.includes('poly')) {
      oscillators[2].oscAmp.gain.setValueAtTime(0, time);
      oscillators[3].oscAmp.gain.setValueAtTime(0, time);
      unisonNoteSwitchController.setValueAtTime(0, time);
      polyNoteSwitchController.setValueAtTime(1, time);
    } else {
      oscillators[2].oscAmp.gain.setValueAtTime(1, time);
      oscillators[3].oscAmp.gain.setValueAtTime(1, time);
      unisonNoteSwitchController.setValueAtTime(1, time);
      polyNoteSwitchController.setValueAtTime(0, time);
    }

    if (patch.voice === 'unison ring') {
      // set mod ring amps
      oscillators[1].volumeAmp.gain.setValueAtTime(carrierGain, time);
      oscillators[1].modGain2CarrierAmp.gain.cancelScheduledValues(time);
      oscillators[1].modGain2CarrierAmp.gain.setValueAtTime(1, time);
      oscillators[1].modGain2ModAmp.gain.cancelScheduledValues(time);
      oscillators[1].modGain2ModAmp.gain.setValueAtTime(0, time);
      oscillators[1].modGain3ModAmp.gain.cancelScheduledValues(time);
      oscillators[1].modGain3ModAmp.gain.setValueAtTime(0, time);

      oscillators[2].volumeAmp.gain.setValueAtTime(1, time);
      oscillators[2].modGain2CarrierAmp.gain.cancelScheduledValues(time);
      oscillators[2].modGain2CarrierAmp.gain.setValueAtTime(0, time);
      oscillators[2].modGain2ModAmp.gain.cancelScheduledValues(time);
      oscillators[2].modGain2ModAmp.gain.setValueAtTime(1, time);
      oscillators[2].modGain3ModAmp.gain.cancelScheduledValues(time);
      oscillators[2].modGain3ModAmp.gain.setValueAtTime(0, time);

      oscillators[3].volumeAmp.gain.setValueAtTime(1, time);
      oscillators[3].modGain2CarrierAmp.gain.cancelScheduledValues(time);
      oscillators[3].modGain2CarrierAmp.gain.setValueAtTime(0, time);
      oscillators[3].modGain2ModAmp.gain.cancelScheduledValues(time);
      oscillators[3].modGain2ModAmp.gain.setValueAtTime(0, time);
      oscillators[3].modGain3ModAmp.gain.cancelScheduledValues(time);
      oscillators[3].modGain3ModAmp.gain.setValueAtTime(1, time);

      oneNotePolyRingAmp.gain.setValueAtTime(0, time);
      twoNotePolyRingAmp.gain.setValueAtTime(0, time);
    } else {
      oscillators[1].modGain2CarrierAmp.gain.cancelScheduledValues(time);
      oscillators[1].modGain2CarrierAmp.gain.setValueAtTime(0, time);
      oscillators[2].modGain2ModAmp.gain.cancelScheduledValues(time);
      oscillators[2].modGain2ModAmp.gain.setValueAtTime(0, time);
      oscillators[3].modGain3ModAmp.gain.cancelScheduledValues(time);
      oscillators[3].modGain3ModAmp.gain.setValueAtTime(0, time);
    }

    if (patch.voice.includes('ring')) {
      thruGainSwitchController.setValueAtTime(0, time);
      modGainSwitchController.setValueAtTime(1, time);
    } else {
      thruGainSwitchController.setValueAtTime(1, time);
      modGainSwitchController.setValueAtTime(0, time);
      Object.values(oscillators).forEach(osc => {
        osc.volumeAmp.gain.cancelScheduledValues(time);
        osc.volumeAmp.gain.setValueAtTime(patch.defaultVcoAmp, time);
      });
    }
  };

  this.stopNote = function(time = Tone.now()) {
    if (!canInteract()) { return; }
    triggerDecayRelease(time);
  };

  this.triggerSequencerRelease = function(time = Tone.now()) {
    if (!canInteract() || !sequencerEnabled) { return; }
    triggerDecayRelease(time, true);
  };

  // CHANGE OCTAVE
  this.changeOctave = (octaveOffset, time = Tone.now()) => {
    if (!canInteract()) { return; }
    Object.values(oscillators).forEach(osc => {
      if (osc.note !== -1) {
        const newNote = osc.note + octaveOffset;
        osc.note = newNote;
        const frequency = Tone.Frequency(newNote, 'midi').toFrequency();
        osc.oscFreqNode.setValueAtTime(frequency, time);
      }
    });
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

  this.setLfoRate = (value) => {
    if (!canInteract() || !oscLfo) { return; }
    oscLfo.frequency.setValueAtTime(value, Tone.now());
  };

  this.setLfoWave = () => {
    if (!canInteract() || !oscLfo) { return; }
    oscLfo.type = patch.lfo.shape;
    retriggerLfo();
  };

  this.setSustain = (value) => {
    if (!canInteract()) { return; }
    // recalculate vcoEg envelope so that sustain always equals 0 (aka not detuned).
    vcoEgShaper.curve = makeVcoEgShaperCurve();
  };

  this.setLfoPitchInt = () => {
    if (!canInteract()) { return; }
    ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, Tone.now());
  };

  this.setLfoCutoffInt = () => {
    if (!canInteract()) { return; }
    ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, Tone.now());
  };

  this.noteIsPlaying = () => {
    if (!canInteract()) { return false; }
    return Object.values(oscillators).some(osc => osc.note !== -1);
  };

  this.setTempo = () => {
    if (!canInteract() || !sequencerEnabled) { return; }
    setTempo();
  };

  this.startSequencer = () => {
    if (!canInteract() || !sequencerEnabled) { return; }
    sequencerPlaying = true;
    Tone.Transport.start();
  };

  this.stopSequencer = () => {
    if (!canInteract() || !sequencerEnabled) { return; }
    sequencerPlaying = false;
    // set all oscillator notes to -1
    [1, 2, 3].forEach(i => oscillators[i].note = -1);
    this.triggerSequencerRelease();
    Tone.Transport.stop();
    Tone.Transport.position = '0:0:0';
    this.currentStepIndex = 0;
  };

  this.getSequencerPlaying = () => {
    return sequencerEnabled ? sequencerPlaying : false;
  };

  this.setDetune = () => {
    if (!canInteract()) { return; }
    oscillators[2].oscillator.detune.setValueAtTime(patch.vco[2].detune, Tone.now());
    oscillators[3].oscillator.detune.setValueAtTime(patch.vco[3].detune, Tone.now());
  };

  this.setVcoEgInt = () => {
    if (!canInteract()) { return; }
    vcoEgIntAmp.gain.setValueAtTime(patch.vco_eg_int, Tone.now());
  };

  this.setDelayTime = () => {
    if (!canInteract()) { return; }
    delay.delayTime.setValueAtTime(patch.delay.time, Tone.now());
  };

  this.setDelayFeedback = () => {
    if (!canInteract()) { return; }
    delayAmp.gain.setValueAtTime(patch.delay.feedback, Tone.now());
  };

  this.dispose = () => {
    if (disposed) { return; }

    const releaseTime = Tone.now();
    this.stopPolyNote([], -1);
    this.stopNote(releaseTime);
    this.setVolume(0, releaseTime);

    if (sequencerEnabled && sequencerPlaying) {
      this.stopSequencer();
    }

    if (sequencerEnabled && sequencerEventId !== null) {
      Tone.Transport.clear(sequencerEventId);
      sequencerEventId = null;
    }

    disposed = true;

    Object.values(oscillators).forEach(osc => {
      safelyDisposeToneNode(osc.oscFreqNode);
      safelyDisposeToneNode(osc.oscillator);
      safelyDisposeToneNode(osc.volumeAmp);
      safelyDisposeToneNode(osc.oscAmp);
      safelyDisposeToneNode(osc.thruGain);
      safelyDisposeToneNode(osc.modGainSwitch);
      safelyDisposeToneNode(osc.modGain2CarrierAmp);
      safelyDisposeToneNode(osc.modGain2ModAmp);
      safelyDisposeToneNode(osc.modGain3ModAmp);
    });

    [
      masterAmp,
      filter,
      filterEgAmp,
      ampEg,
      universalEg,
      vcoEgShaper,
      vcoEgIntAmp,
      ampLfoPitch,
      ampLfoCutoff,
      delay,
      delayFilter,
      delayAmp,
      oscLfo,
      lfoWaveShaper,
      thruGainSwitchController,
      modGainSwitchController,
      oneNotePolyRingAmp,
      twoNotePolyRingAmp,
      modGain2,
      modGain3,
      voiceOscDetuner1,
      voiceOscDetuner3,
      unisonNoteAmp2,
      unisonNoteAmp3,
      polyNoteAmp2,
      polyNoteAmp3,
      unisonNoteSwitchController,
      polyNoteSwitchController
    ].forEach(safelyDisposeToneNode);

    oscLfo = null;
  };
};
