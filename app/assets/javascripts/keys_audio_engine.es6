VS.KeysAudioEngine = function(patch) {
  // ===================================================================
  // THIS IS THE ONLY COMPONENT THAT SHOULD INTERACT WITH AUDIO CONTEXT
  // ===================================================================

  const audioCtx = new AudioContext();
  const myToneCtx = new Tone.Context({context: audioCtx, lookAhead: 0.1})
  const masterAmp = audioCtx.createGain();
  const filter = audioCtx.createBiquadFilter();
  const filterEgAmp = audioCtx.createGain();
  const ampEg = audioCtx.createGain();
  const universalEg = audioCtx.createConstantSource();
  const universalEgOffsetParam = new Tone.Param(universalEg.offset);
  const vcoEgShaper = audioCtx.createWaveShaper();
  const vcoEgIntAmp = audioCtx.createGain();
  const ampLfoPitch = audioCtx.createGain();
  const ampLfoCutoff = audioCtx.createGain();
  const gracePeriod = 0.05; // 50ms
  const carrierGain = 0.5; // so ring mod voices aren't super loud

  const makeVcoEgShaperCurve = function() {
    const curve = new Float32Array(256);
    const sustain = patch.envelope.sustain;

    for (let i = 0; i < 256; i++) {
      // Counterintuitively, the shaper is excepting -1 to 1 range even
      // though it appears that the universalEgOffsetParam outputs values
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
  const delay = audioCtx.createDelay();
  delay.delayTime.setValueAtTime(0.2, audioCtx.currentTime);

  const delayFilter = audioCtx.createBiquadFilter();
  delayFilter.type = 'lowpass';
  delayFilter.Q.value = 0;
  delayFilter.frequency.setValueAtTime(1000, audioCtx.currentTime);

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

  ampEg.gain.setValueAtTime(0, audioCtx.currentTime);
  ampEg.connect(filter);

  ampLfoCutoff.connect(filter.detune);

  let oscLfo;

  //  This is needed to flip the LFO wave upside down so the sawtooth wave
  //  slopes top to bottom and not bottom to top.
  const lfoWaveShaper = audioCtx.createWaveShaper();
  lfoWaveShaper.curve = new Float32Array([1, 0, -1]);

  const setupOscLfo = function() {
    oscLfo = audioCtx.createOscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, audioCtx.currentTime);

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

  const thruGainSwitchController = audioCtx.createConstantSource();
  thruGainSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);

  const modGainSwitchController = audioCtx.createConstantSource();
  modGainSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);

  // Early outputs for one and two note poly ring scenarios.
  // The modGain amps are off by default unless that note of polyphony is
  // playing.  The amps provide a bypass for when less notes are playing.
  const oneNotePolyRingAmp = audioCtx.createGain();
  oneNotePolyRingAmp.gain.value = 0;
  oneNotePolyRingAmp.connect(ampEg);
  const twoNotePolyRingAmp = audioCtx.createGain();
  twoNotePolyRingAmp.gain.value = 0;
  twoNotePolyRingAmp.connect(ampEg);

  const modGain2 = audioCtx.createGain();
  modGain2.gain.value = 0;

  const modGain3 = audioCtx.createGain();
  modGain3.gain.value = 0;
  modGain2.connect(twoNotePolyRingAmp);
  modGain2.connect(modGain3);
  modGain3.connect(ampEg);

  vcoEgIntAmp.gain.setValueAtTime(0, audioCtx.currentTime);

  const oscillatorObj = function(oscNumber) {
    this.oscNumber = oscNumber;
    this.oscFreqNode = audioCtx.createConstantSource();
    this.oscFreqNodeOffsetParam = new Tone.Param(this.oscFreqNode.offset);
    this.oscillator = audioCtx.createOscillator();
    this.volumeAmp = audioCtx.createGain();
    this.oscAmp = audioCtx.createGain();
    this.thruGain = audioCtx.createGain();
    this.modGainSwitch = audioCtx.createGain();
    this.modGain2CarrierAmp = audioCtx.createGain();
    this.modGain2ModAmp = audioCtx.createGain();
    this.modGain3ModAmp = audioCtx.createGain();
    this.note = -1;
    this.setFrequency = function(value) {};

    this.turnOnOscAmp = function(time = audioCtx.currentTime) {
      this.oscAmp.gain.cancelScheduledValues(time);
      this.oscAmp.gain.setValueAtTime(1, time);
    };

    this.turnOffOscAmp = function(time = audioCtx.currentTime) {
      this.oscAmp.gain.cancelScheduledValues(time);
      this.oscAmp.gain.setValueAtTime(0, time);
    };

    this.setRingModPath = function(time = audioCtx.currentTime, isRingOut = false) {
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
      this.oscFreqNodeOffsetParam.setValueAtTime(440, audioCtx.currentTime);
      // Set up osc
      this.oscillator.type = patch.vco[this.oscNumber].shape;
      this.oscillator.detune.setValueAtTime(
        patch.vco[this.oscNumber].detune,
        audioCtx.currentTime
      );
      this.oscillator.frequency.setValueAtTime(0, audioCtx.currentTime);
      ampLfoPitch.connect(this.oscillator.detune);
      vcoEgIntAmp.connect(this.oscillator.detune);

      this.oscillator.connect(this.volumeAmp);
      this.volumeAmp.gain.setValueAtTime(patch.defaultVcoAmp, audioCtx.currentTime);
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

      this.oscFreqNode.start();
      this.oscillator.start();
    }

    this.initialize();
  };

  const oscillators = {
    1: new oscillatorObj(1),
    2: new oscillatorObj(2),
    3: new oscillatorObj(3)
  };

  universalEg.offset.setValueAtTime(0, audioCtx.currentTime);
  universalEg.connect(filterEgAmp);
  universalEg.connect(ampEg.gain);
  universalEg.connect(vcoEgShaper);
  vcoEgShaper.connect(vcoEgIntAmp);
  universalEg.start();

  thruGainSwitchController.start();
  modGainSwitchController.start();

  const voiceOscDetuner1 = audioCtx.createConstantSource();
  voiceOscDetuner1.offset.setValueAtTime(0, audioCtx.currentTime);
  voiceOscDetuner1.connect(oscillators[1].oscillator.detune);
  voiceOscDetuner1.start();

  const voiceOscDetuner3 = audioCtx.createConstantSource();
  voiceOscDetuner3.offset.setValueAtTime(0, audioCtx.currentTime);
  voiceOscDetuner3.connect(oscillators[3].oscillator.detune);
  voiceOscDetuner3.start();


  const unisonNoteAmp2 = audioCtx.createGain();
  unisonNoteAmp2.gain.value = 0;
  const unisonNoteAmp3 = audioCtx.createGain();
  unisonNoteAmp3.gain.value = 0;


  // Setup oscillator specific note frequency control
  oscillators[1].oscFreqNode.connect(oscillators[1].oscillator.frequency);
  oscillators[1].oscFreqNode.connect(unisonNoteAmp2);
  oscillators[1].oscFreqNode.connect(unisonNoteAmp3);
  unisonNoteAmp2.connect(oscillators[2].oscillator.frequency);
  unisonNoteAmp3.connect(oscillators[3].oscillator.frequency);

  const polyNoteAmp2 = audioCtx.createGain();
  polyNoteAmp2.gain.value = 0;
  oscillators[2].oscFreqNode.connect(polyNoteAmp2);
  polyNoteAmp2.connect(oscillators[2].oscillator.frequency);

  const polyNoteAmp3 = audioCtx.createGain();
  polyNoteAmp3.gain.value = 0;
  oscillators[3].oscFreqNode.connect(polyNoteAmp3);
  polyNoteAmp3.connect(oscillators[3].oscillator.frequency);



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

  this.init = () => {
    Tone.setContext(myToneCtx);
    Tone.start();
    setInitialEngineValues();
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
    const lfo = patch.lfo;
    if (!lfo.triggerSync) { return; }
    if (lfo.pitchValue + lfo.cutoffValue === 0) { return; }

    oscLfo.disconnect();
    oscLfo = null;
    setupOscLfo();
  };

  const triggerDecayRelease = function(time = audioCtx.currentTime) {
    const isDecay = Object.values(oscillators).some(osc => osc.note !== -1);

    const endValue = isDecay ? patch.envelope.sustain : 0;
    let duration;
    const currentValue = universalEgOffsetParam.getValueAtTime(time);

    if (isDecay) {
      universalEgOffsetParam.setValueAtTime(1, time);
      duration = patch.envelope.decayRelease;
    } else {
      universalEgOffsetParam.cancelAndHoldAtTime(time); // kill attack in progress
      universalEgOffsetParam.setValueAtTime(currentValue, time);  // stop at current value
      duration = currentValue * patch.envelope.decayRelease;
    }

    if (browserFeatures['customCurveClearing']) {
      // use custom curve (scaled to amount between current and end values)
      const gainCurve = VS.emulatorConstants.decayReleaseGainCurve.map(
        function(value) { return value * (currentValue - endValue) + endValue }
      );
      universalEgOffsetParam.setValueCurveAtTime(gainCurve, time, duration);
    } else {
      universalEgOffsetParam.linearRampToValueAtTime(endValue, time + duration)
    }
  };

  const triggerEg = function(time = audioCtx.currentTime) {
    const attackEndTimeValue = time + patch.envelope.attack;

    // Amp EG reset
    universalEgOffsetParam.cancelAndHoldAtTime(time);

    if (patch.envelope.attack > 0) {
      universalEgOffsetParam.setValueAtTime(0, time);
      universalEgOffsetParam.linearRampToValueAtTime(1, attackEndTimeValue);
    } else {
      universalEgOffsetParam.setValueAtTime(1, time);
    }

    retriggerLfo();

    // Decay
    triggerDecayRelease(attackEndTimeValue);
  };

  const turnOnAllOscAmps = function(time = audioCtx.currentTime) {
    Object.values(oscillators).forEach(obj => obj.turnOnOscAmp());
  };

  this.playNewNote = function(note, time = audioCtx.currentTime) {
    this.activateAudio();

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
    oscillators[1].oscFreqNodeOffsetParam.setValueAtTime(frequency, time);
    oscillators[1].setRingModPath();

    triggerEg(time);
  };

  // Only used for unison voices
  this.changeCurrentNote = function(note, time = audioCtx.currentTime) {
    let frequency = Tone.Frequency(note, 'midi').toFrequency();
    let lastFrequency = oscillators[1].oscFreqNodeOffsetParam.getValueAtTime(time);

    oscillators[1].oscFreqNodeOffsetParam.setValueAtTime(lastFrequency, time);
    oscillators[1].oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + patch.portamento);
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

  const adjustPolyRingAlgo = function(numberOfKeysDown, time = audioCtx.currentTime, isRingOut = false) {
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

  const swapOscillatorFrequency = function(oscillator, oldFreq, newFreq, time = audioCtx.currentTime) {
    const rampEndTime = time + patch.portamento;
    oscillator.oscFreqNodeOffsetParam.setValueAtTime(oldFreq, time);
    oscillator.oscFreqNodeOffsetParam.linearRampToValueAtTime(newFreq, rampEndTime);
  }

  // Poly voices only!
  this.addNote = function(keysDown) {
    const time = audioCtx.currentTime;
    const lowestFreeOsc = lowestFreeOscillator();
    const noteToAdd = keysDown[keysDown.length -1];
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

  const swapPolyNote = function(keysDown, noteThatStopped, oscAffected) {
    if (oscAffected === null) { return; }
    // find notes that aren't playing
    const time = audioCtx.currentTime;
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

  const turnOffAllOscAmps = function(time = audioCtx.currentTime) {
    const turnOffTime = time + patch.envelope.decayRelease;
    Object.values(oscillators).forEach(obj => {
      obj.oscAmp.gain.cancelScheduledValues(time);
      obj.turnOffOscAmp(turnOffTime);
    });
  };

  this.stopPolyNote = function(keysDown, noteThatStopped) {
    if (keysDown.length === 0) {
      // Ring out
      Object.values(oscillators).forEach(osc => osc.setRingModPath(audioCtx.currentTime, true));
      adjustPolyRingAlgo(keysDown.length, audioCtx.currentTime, true);
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
      const actionTime = audioCtx.currentTime + gracePeriod;
      Object.values(oscillators).forEach(osc => osc.setRingModPath(actionTime));
      adjustPolyRingAlgo(keysDown.length, actionTime);
      oscAffected.turnOffOscAmp(actionTime);
    }
  };

  this.changeVoice = function() {
    /*
    TODO: Try to break out the configurations of different voices
          into an object or something.
    */
    const time = audioCtx.currentTime;
    voiceOscDetuner1.offset.setValueAtTime(patch.vco[1].voiceDetune, time);
    voiceOscDetuner3.offset.setValueAtTime(patch.vco[3].voiceDetune, time);

    Object.values(oscillators).forEach(obj => obj.oscillator.type = patch.vco[obj.oscNumber].shape);

    if (patch.voice.includes('poly')) {
      oscillators[2].oscAmp.gain.setValueAtTime(0, time);
      oscillators[3].oscAmp.gain.setValueAtTime(0, time);
      unisonNoteSwitchController.offset.setValueAtTime(0, time);
      polyNoteSwitchController.offset.setValueAtTime(1, time);
    } else {
      oscillators[2].oscAmp.gain.setValueAtTime(1, time);
      oscillators[3].oscAmp.gain.setValueAtTime(1, time);
      unisonNoteSwitchController.offset.setValueAtTime(1, time);
      polyNoteSwitchController.offset.setValueAtTime(0, time);
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
      thruGainSwitchController.offset.setValueAtTime(0, time);
      modGainSwitchController.offset.setValueAtTime(1, time);
    } else {
      thruGainSwitchController.offset.setValueAtTime(1, time);
      modGainSwitchController.offset.setValueAtTime(0, time);
      Object.values(oscillators).forEach(osc => {
        osc.volumeAmp.gain.cancelScheduledValues(time);
        osc.volumeAmp.gain.setValueAtTime(patch.defaultVcoAmp, time);
      });
    }
  };

  this.stopNote = function() {
    triggerDecayRelease();
  };

  // CHANGE OCTAVE
  this.changeOctave = (octaveOffset, time = audioCtx.currentTime) => {
    Object.values(oscillators).forEach(osc => {
      if (osc.note !== -1) {
        const newNote = osc.note + octaveOffset;
        osc.note = newNote;
        const frequency = Tone.Frequency(newNote, 'midi').toFrequency();
        osc.oscFreqNodeOffsetParam.setValueAtTime(frequency, time);
      }
    });
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

  this.setLfoRate = (value) => {
    oscLfo.frequency.setValueAtTime(value, audioCtx.currentTime);
  };

  this.setLfoWave = () => {
    oscLfo.type = patch.lfo.shape;
    retriggerLfo();
  };

  this.setSustain = (value) => {
    // recalculate vcoEg envelope so that sustain always equals 0 (aka not detuned).
    vcoEgShaper.curve = makeVcoEgShaperCurve();
  };

  this.setLfoPitchInt = () => {
    ampLfoPitch.gain.setValueAtTime(patch.lfo.pitchValue, audioCtx.currentTime);
  };

  this.setLfoCutoffInt = () => {
    ampLfoCutoff.gain.setValueAtTime(patch.lfo.cutoffValue, audioCtx.currentTime);
  };

  this.noteIsPlaying = () => {
    return Object.values(oscillators).some(osc => osc.note !== -1);
  };

  this.setTempo = () => {
    setTempo();
  };

  this.setDetune = () => {
    oscillators[2].oscillator.detune.setValueAtTime(patch.vco[2].detune, audioCtx.currentTime);
    oscillators[3].oscillator.detune.setValueAtTime(patch.vco[3].detune, audioCtx.currentTime);
  };

  this.setVcoEgInt = () => {
    vcoEgIntAmp.gain.setValueAtTime(patch.vco_eg_int, audioCtx.currentTime);
  };

  this.setDelayTime = () => {
    delay.delayTime.setValueAtTime(patch.delay.time, audioCtx.currentTime);
  };

  this.setDelayFeedback = () => {
    delayAmp.gain.setValueAtTime(patch.delay.feedback, audioCtx.currentTime);
  };
};
