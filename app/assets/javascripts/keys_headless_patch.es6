VS.buildDefaultKeysSequence = function() {
  const sequence = [];

  for (let index = 0; index < 16; index++) {
    sequence.push(
      {
        index: index,
        note: 60,
        slide: false,
        activeStep: true
      }
    );
  }

  return sequence;
};

VS.buildHeadlessKeysPatch = function(payload) {
  const emulatorParams = payload && payload.emulator_params ? payload.emulator_params : payload;

  if (!emulatorParams) {
    throw new Error('Keys emulator params are required.');
  }

  if (!VS.emulatorConstants) {
    VS.emulatorConstants = new VS.EmulatorConstants;
  }

  const patchParams = new VS.KeysEmulatorParams;
  patchParams.setAllParams(emulatorParams);

  const audioEngine = new VS.KeysAudioEngine(
    patchParams,
    [],
    { enableSequencer: false }
  );
  audioEngine.init();

  return {
    audioEngine: audioEngine,
    patchParams: patchParams
  };
};
