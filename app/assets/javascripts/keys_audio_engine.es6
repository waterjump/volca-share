VS.KeysAudioEngine = function(patch) {
  // ===================================================================
  // THIS IS THE ONLY COMPONENT THAT SHOULD INTERACT WITH AUDIO CONTEXT
  // ===================================================================

  const audioCtx = new AudioContext();
  const myToneCtx = new Tone.Context({context: audioCtx, lookAhead: 0.1})
  const masterAmp = audioCtx.createGain();
  const filter = audioCtx.createBiquadFilter();
  const filterEgAmp = audioCtx.createGain();
  const filterEg = audioCtx.createConstantSource();
  const filterEgOffsetParam = new Tone.Param(filterEg.offset);
  const ampEg = audioCtx.createGain();
  const universalEg = audioCtx.createConstantSource();
  const universalEgOffsetParam = new Tone.Param(universalEg.offset);
  const vcoEgShaper = audioCtx.createWaveShaper();
  const vcoEgIntAmp = audioCtx.createGain();
  const ampLfoPitch = audioCtx.createGain();
  const ampLfoCutoff = audioCtx.createGain();
  const builtInDecay = 0.1;
  let osc = [null, null, null, null];
  let oscillatorNoteMap = { 1: -1, 2: -1, 3: -1 }

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

  filterEg.offset.setValueAtTime(0, audioCtx.currentTime);
  filterEg.connect(filterEgAmp);
  filterEg.start();


  ampEg.gain.setValueAtTime(0, audioCtx.currentTime);
  ampEg.connect(filter);

  ampLfoCutoff.connect(filter.detune);

  let oscLfo;

  // NOTE: This is needed to flip the LFO wave upside down so the sawtooth wave
  //  slopes top to bottom and not bottom to top.
  const lfoWaveShaper = audioCtx.createWaveShaper();
  lfoWaveShaper.curve = new Float32Array([1, 0, -1]);

  const setupOscLfo = function() {
    oscLfo = audioCtx.createOscillator();
    oscLfo.type = patch.lfo.shape;
    oscLfo.frequency.setValueAtTime(patch.lfo.frequency, audioCtx.currentTime);
    oscLfo.connect(lfoWaveShaper);
    lfoWaveShaper.connect(ampLfoPitch);
    lfoWaveShaper.connect(ampLfoCutoff);
    oscLfo.start();
  }

  setupOscLfo();

  const thruGainSwitchController = audioCtx.createConstantSource();
  thruGainSwitchController.offset.setValueAtTime(patch.defaultVcoAmp, audioCtx.currentTime);

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

  const oscPolyMonoAmp1 = audioCtx.createGain();
  oscPolyMonoAmp1.gain.value = 1;
  const oscPolyMonoAmp2 = audioCtx.createGain();
  oscPolyMonoAmp2.gain.value = 1;
  const oscPolyMonoAmp3 = audioCtx.createGain();
  oscPolyMonoAmp3.gain.value = 1;

  vcoEgIntAmp.gain.setValueAtTime(0, audioCtx.currentTime);

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
    vcoEgIntAmp.connect(oscillator.detune);

    const thruGain = audioCtx.createGain();
    thruGain.gain.value = 0;
    thruGainSwitchController.connect(thruGain.gain);
    thruGain.connect(ampEg);

    const modGainSwitch = audioCtx.createGain();
    modGainSwitch.gain.value = 0;
    modGainSwitchController.connect(modGainSwitch.gain);

    if (oscNumber === 1) {
      oscillator.connect(oscPolyMonoAmp1);
      oscPolyMonoAmp1.connect(thruGain);
      oscPolyMonoAmp1.connect(modGainSwitch);
      modGainSwitch.connect(oneNotePolyRingAmp);
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

  universalEg.offset.setValueAtTime(0, audioCtx.currentTime);
  universalEg.connect(ampEg.gain);
  universalEg.connect(vcoEgShaper);
  vcoEgShaper.connect(vcoEgIntAmp);
  universalEg.start();

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
  const oscFreqNodeOffsetParam = new Tone.Param(oscFreqNode.offset);
  oscFreqNodeOffsetParam.setValueAtTime(440, audioCtx.currentTime);
  oscFreqNode.connect(osc[1].frequency);
  oscFreqNode.connect(unisonNoteAmp2);
  oscFreqNode.connect(unisonNoteAmp3);
  unisonNoteAmp2.connect(osc[2].frequency);
  unisonNoteAmp3.connect(osc[3].frequency);
  oscFreqNode.start();


  const oscFreqNode2 = audioCtx.createConstantSource();
  const oscFreqNodeOffsetParam2 = new Tone.Param(oscFreqNode2.offset);
  oscFreqNodeOffsetParam2.setValueAtTime(440, audioCtx.currentTime);
  const polyNoteAmp2 = audioCtx.createGain();
  polyNoteAmp2.gain.value = 0;
  oscFreqNode2.connect(polyNoteAmp2);
  polyNoteAmp2.connect(osc[2].frequency);
  oscFreqNode2.start();


  const oscFreqNode3 = audioCtx.createConstantSource();
  const oscFreqNodeOffsetParam3 = new Tone.Param(oscFreqNode3.offset);
  oscFreqNodeOffsetParam3.setValueAtTime(440, audioCtx.currentTime);
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

  const triggerDecayRelease = function(time = audioCtx.currentTime) {
    const isDecay = Object.values(oscillatorNoteMap).some(value => value !== -1);
    const endValue = isDecay ? patch.envelope.sustain : 0;
    let duration;
    const currentValue = universalEgOffsetParam.getValueAtTime(time);

    // filterEgOffsetParam.cancelAndHoldAtTime(time);
    filterEgOffsetParam.cancelScheduledValues(time);
    filterEgOffsetParam.linearRampToValueAtTime(
     endValue,
     time + (patch.envelope.decayRelease * patch.filterEgCoefficient)
    );

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
    // Filter EG reset
    filterEgOffsetParam.cancelAndHoldAtTime(time);

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

    filterEgOffsetParam.setValueAtTime(0, time);
    filterEgOffsetParam.linearRampToValueAtTime(1, attackEndTimeValue);

    // Decay
    triggerDecayRelease(attackEndTimeValue);
  };

  const turnOnAllOscPolyMonoAmps = function(time = audioCtx.currentTime) {
    oscPolyMonoAmp1.gain.cancelScheduledValues(time);
    oscPolyMonoAmp1.gain.setValueAtTime(1, time);
    oscPolyMonoAmp2.gain.cancelScheduledValues(time);
    oscPolyMonoAmp2.gain.setValueAtTime(1, time);
    oscPolyMonoAmp3.gain.cancelScheduledValues(time);
    oscPolyMonoAmp3.gain.setValueAtTime(1, time);
  };

  this.playNewNote = function(note, time = audioCtx.currentTime) {
    this.activateAudio();
    turnOnAllOscPolyMonoAmps();

    if (patch.voice === 'poly ring') {
      oneNotePolyRingAmp.gain.setValueAtTime(1, audioCtx.currentTime);
    }

    // Set frequency of oscillators
    oscillatorNoteMap[1] = note;
    const frequency = Tone.Frequency(note, 'midi').toFrequency();
    oscFreqNodeOffsetParam.setValueAtTime(frequency, time);

    triggerEg(time);
  };

  this.changeCurrentNote = function(note, time = audioCtx.currentTime) {
    let frequency = Tone.Frequency(note, 'midi').toFrequency();
    let lastFrequency = oscFreqNodeOffsetParam.getValueAtTime(time);

    oscFreqNodeOffsetParam.setValueAtTime(lastFrequency, time);
    oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + patch.portamento);
  };

  const lowestFreeOscillator = () => {
    for (let key in oscillatorNoteMap) {
      if (oscillatorNoteMap[key] === -1) {
        return parseInt(key);
      }
    }
    return null;
  };

  const findOscillatorPlayingClosestNote = function(target) {
    let closestKey = null;
    let smallestDifference = Infinity;

    for (let key in oscillatorNoteMap) {
      let difference = Math.abs(oscillatorNoteMap[key] - target);

      if (
        difference < smallestDifference ||
        (difference === smallestDifference && oscillatorNoteMap[key] > oscillatorNoteMap[closestKey])
      ) {
        closestKey = key;
        smallestDifference = difference;
      }
    }

    return parseInt(closestKey);
  };

  // NOTE: This will need changes for when carrier (osc1) stops playing
  const adjustPolyRingAlgo = function(numberOfKeysDown) {
    if (patch.voice !== 'poly ring') { return; }

    if (numberOfKeysDown === 1) {
      oneNotePolyRingAmp.gain.setValueAtTime(1, audioCtx.currentTime);
      twoNotePolyRingAmp.gain.setValueAtTime(0, audioCtx.currentTime);
    } else if (numberOfKeysDown === 2) {
      oneNotePolyRingAmp.gain.setValueAtTime(0, audioCtx.currentTime);
      twoNotePolyRingAmp.gain.setValueAtTime(1, audioCtx.currentTime);
    } else if (numberOfKeysDown === 3) {
      oneNotePolyRingAmp.gain.setValueAtTime(0, audioCtx.currentTime);
      twoNotePolyRingAmp.gain.setValueAtTime(0, audioCtx.currentTime);
    }
  };

  // TODO: Think about making an oscillator class to get rid off all
  //       these switch cases.
  // Poly voices only!
  this.addNote = function(keysDown) {
    const time = audioCtx.currentTime;
    const lowestFreeOsc = lowestFreeOscillator();
    const noteToAdd = keysDown[keysDown.length -1];
    const frequency = Tone.Frequency(noteToAdd, 'midi').toFrequency();
    const closestOscillator = findOscillatorPlayingClosestNote(noteToAdd);
    const closestNote = oscillatorNoteMap[closestOscillator];
    const closestNoteFrequency = Tone.Frequency(closestNote, 'midi').toFrequency();

    if (patch.portamento > 0.008) {
      triggerEg(time);
    }

    // if there's an unused oscillator
    if (lowestFreeOsc !== null) {
      oscillatorNoteMap[lowestFreeOsc] = noteToAdd;

      switch (lowestFreeOsc) {
        case 1:
          oscFreqNodeOffsetParam.setValueAtTime(closestNoteFrequency, time);
          oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + patch.portamento);
          oscPolyMonoAmp1.gain.setValueAtTime(1, time);
          break;
        case 2:
          oscFreqNodeOffsetParam2.setValueAtTime(closestNoteFrequency, time);
          oscFreqNodeOffsetParam2.linearRampToValueAtTime(frequency, time + patch.portamento);
          oscPolyMonoAmp2.gain.setValueAtTime(1, time);
          break;
        case 3:
          oscFreqNodeOffsetParam3.setValueAtTime(closestNoteFrequency, time);
          oscFreqNodeOffsetParam3.linearRampToValueAtTime(frequency, time + patch.portamento);
          oscPolyMonoAmp3.gain.setValueAtTime(1, time);
          break;
      }

    } else {
      // swap closest playing note
      oscillatorNoteMap[closestOscillator] = noteToAdd;
      switch (closestOscillator) {
        case 1:
          oscFreqNodeOffsetParam.setValueAtTime(closestNoteFrequency, time);
          oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + patch.portamento);
          break;
        case 2:
          oscFreqNodeOffsetParam2.setValueAtTime(closestNoteFrequency, time);
          oscFreqNodeOffsetParam2.linearRampToValueAtTime(frequency, time + patch.portamento);
          break;
        case 3:
          oscFreqNodeOffsetParam3.setValueAtTime(closestNoteFrequency, time);
          oscFreqNodeOffsetParam3.linearRampToValueAtTime(frequency, time + patch.portamento);
          break;
      }
    }

    adjustPolyRingAlgo(keysDown.length);
  };

  const findOscByNote = (note) => {
    for (let key in oscillatorNoteMap) {
      if (oscillatorNoteMap[key] === note) {
        return parseInt(key);
      }
    }
    return null;
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
    const notesStillPlaying = Object.values(oscillatorNoteMap);
    const notesNotPlaying = keysDown.filter(note => !notesStillPlaying.includes(note));

    let noteToSwapIn;
    if (notesNotPlaying.length === 1) {
      noteToSwapIn = notesNotPlaying[0];
    } else {
      noteToSwapIn = findClosestValue(notesNotPlaying, noteThatStopped);
    }

    const lastFrequency = Tone.Frequency(oscillatorNoteMap[oscAffected], 'midi').toFrequency();
    const frequency = Tone.Frequency(noteToSwapIn, 'midi').toFrequency();
    oscillatorNoteMap[oscAffected] = noteToSwapIn;

    switch(oscAffected) {
      case 1:
        oscFreqNodeOffsetParam.setValueAtTime(lastFrequency, time);
        oscFreqNodeOffsetParam.linearRampToValueAtTime(frequency, time + patch.portamento);
        break;
      case 2:
        oscFreqNodeOffsetParam2.setValueAtTime(lastFrequency, time);
        oscFreqNodeOffsetParam2.linearRampToValueAtTime(frequency, time + patch.portamento);
        break;
      case 3:
        oscFreqNodeOffsetParam3.setValueAtTime(lastFrequency, time);
        oscFreqNodeOffsetParam3.linearRampToValueAtTime(frequency, time + patch.portamento);
        break;
      default:
        // do nothing
    }
  };

  const turnOffAllOscAmps = function(time = audioCtx.currentTime) {
    const turnOffTime = time + patch.envelope.decayRelease;
    oscPolyMonoAmp1.gain.setValueAtTime(0, turnOffTime);
    oscPolyMonoAmp2.gain.setValueAtTime(0, turnOffTime);
    oscPolyMonoAmp3.gain.setValueAtTime(0, turnOffTime);
  };

  this.stopPolyNote = function(keysDown, noteThatStopped) {
    // important because EG uses oscillatorNoteMap to determine decay vs release
    if (keysDown.length === 0) {
      [1, 2, 3].forEach(i => oscillatorNoteMap[i] = -1);
      turnOffAllOscAmps();
    }
    if (!patch.voice.includes('poly')) { return; }

    const oscAffected = findOscByNote(noteThatStopped);
    if (oscAffected === null) { return; }

    if (keysDown.length > 2) {
      swapPolyNote(keysDown, noteThatStopped, oscAffected);
    } else {
      oscillatorNoteMap[oscAffected] = -1;
      // TODO: Will probably need to account for EG release at some point.
      switch(oscAffected) {
        case 1:
          oscPolyMonoAmp1.gain.setValueAtTime(0, audioCtx.currentTime);
          break;
        case 2:
          oscPolyMonoAmp2.gain.setValueAtTime(0, audioCtx.currentTime);
          break;
        case 3:
          oscPolyMonoAmp3.gain.setValueAtTime(0, audioCtx.currentTime);
          break;
        default:
          // do nothing
      }
    }

    adjustPolyRingAlgo(keysDown.length);
  };

  this.changeVoice = function() {
    /*
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
      oscPolyMonoAmp2.gain.setValueAtTime(0, audioCtx.currentTime);
      oscPolyMonoAmp3.gain.setValueAtTime(0, audioCtx.currentTime);
      unisonNoteSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
      polyNoteSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
    } else {
      oscPolyMonoAmp2.gain.setValueAtTime(1, audioCtx.currentTime);
      oscPolyMonoAmp3.gain.setValueAtTime(1, audioCtx.currentTime);
      unisonNoteSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
      polyNoteSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
    }

    if (patch.voice.includes('ring')) {
      thruGainSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
      modGainSwitchController.offset.setValueAtTime(1, audioCtx.currentTime);
    } else {
      thruGainSwitchController.offset.setValueAtTime(patch.defaultVcoAmp, audioCtx.currentTime);
      modGainSwitchController.offset.setValueAtTime(0, audioCtx.currentTime);
    }
  };

  this.stopNote = function() {
    triggerDecayRelease();
  };

  // CHANGE OCTAVE
  this.changeOctave = (octaveOffset, time = audioCtx.currentTime) => {
    // TODO: This function is in need of a refactor.

    if (oscillatorNoteMap[1] !== -1) {
      const newNote1 = oscillatorNoteMap[1] + octaveOffset;
      oscillatorNoteMap[1] = newNote1;
      const frequency = Tone.Frequency(newNote1, 'midi').toFrequency();
      oscFreqNodeOffsetParam.setValueAtTime(frequency, time);
    }

    if (oscillatorNoteMap[2] !== -1) {
      const frequency2 = Tone.Frequency(
        oscillatorNoteMap[2] + octaveOffset,
        'midi'
      ).toFrequency();
      oscillatorNoteMap[2] = oscillatorNoteMap[2] + octaveOffset;
      oscFreqNodeOffsetParam2.setValueAtTime(frequency2, time);
    }

    if (oscillatorNoteMap[3] !== -1) {
      const frequency3 = Tone.Frequency(
        oscillatorNoteMap[3] + octaveOffset,
        'midi'
      ).toFrequency();
      oscillatorNoteMap[3] = oscillatorNoteMap[3] + octaveOffset;

      oscFreqNodeOffsetParam3.setValueAtTime(frequency3, time);
    }
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

  this.setLfoWave = (value) => {
    if (value === 'saw') {
      value = 'sawtooth';
    }
    oscLfo.type = value;
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
    return Object.values(oscillatorNoteMap).some(value => value !== -1);
  };

  this.setTempo = () => {
    setTempo();
  };

  this.setDetune = () => {
    osc[1].detune.setValueAtTime(patch.vco[1].detune, audioCtx.currentTime);
    osc[3].detune.setValueAtTime(patch.vco[3].detune, audioCtx.currentTime);
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
