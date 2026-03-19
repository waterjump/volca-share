VS.buildHeadlessBassPatch = function(payload) {
  const emulatorParams = payload && payload.emulator_params ? payload.emulator_params : payload;

  if (!emulatorParams) {
    throw new Error('Bass emulator params are required.');
  }

  if (!VS.emulatorConstants) {
    VS.emulatorConstants = new VS.EmulatorConstants;
  }

  const patchParams = new VS.EmulatorParams;
  patchParams.setAllParams(emulatorParams);

  const audioEngine = new VS.AudioEngine(
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
