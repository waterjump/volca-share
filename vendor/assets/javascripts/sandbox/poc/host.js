import { initializeWamHost } from 'wam-sdk';
import SimpleSawWam from 'poc-simple-saw-wam';
import SimpleSawOscillatorWam from 'poc-simple-saw-oscillator-wam';

const noteOnStatusByte = 0x90;
const noteOffStatusByte = 0x80;
const midiNoteA4 = 69;
const velocity = 100;
const noteDurationSeconds = 1;
const wamConstructors = {
  oscillator: SimpleSawOscillatorWam,
  processor: SimpleSawWam
};
const wamLabels = {
  oscillator: 'OscillatorNode WAM',
  processor: 'Processor DSP WAM'
};

const hostStatus = document.querySelector('#host-status');
const playButton = document.querySelector('#play-note-button');
const wamModuleSelect = document.querySelector('#wam-module-select');
const pluginMount = document.querySelector('#plugin-mount');

let audioContext = null;
let hostGroupId = null;
let wamInstance = null;

const setHostStatus = (message) => {
  hostStatus.textContent = message;
};

const setButtonEnabled = (enabled) => {
  playButton.disabled = !enabled;
};

const setModuleSelectorEnabled = (enabled) => {
  wamModuleSelect.disabled = !enabled;
};

const destroyCurrentWam = () => {
  if (!wamInstance || !wamInstance.audioNode) { return; }

  wamInstance.audioNode.destroy();
  pluginMount.replaceChildren();
  wamInstance = null;
};

const loadSelectedWam = async (kind) => {
  const WamConstructor = wamConstructors[kind];
  if (!audioContext || !hostGroupId || !WamConstructor) { return; }

  setButtonEnabled(false);
  setModuleSelectorEnabled(false);
  setHostStatus(`Loading ${wamLabels[kind]}...`);

  try {
    destroyCurrentWam();

    wamInstance = await WamConstructor.createInstance(hostGroupId, audioContext);
    wamInstance.audioNode.connect(audioContext.destination);

    const pluginGui = await wamInstance.createGui();
    pluginMount.replaceChildren(pluginGui);

    setHostStatus(`${wamLabels[kind]} ready. Click the button to send MIDI note 69 to the WAM.`);
  } finally {
    setButtonEnabled(true);
    setModuleSelectorEnabled(true);
  }
};

const playSawNote = async () => {
  if (!audioContext || !wamInstance) { return; }

  await audioContext.resume();

  const noteOnTime = audioContext.currentTime + 0.05;
  const noteOffTime = noteOnTime + noteDurationSeconds;

  wamInstance.audioNode.scheduleEvents(
    {
      type: 'wam-midi',
      time: noteOnTime,
      data: { bytes: [noteOnStatusByte, midiNoteA4, velocity] }
    },
    {
      type: 'wam-midi',
      time: noteOffTime,
      data: { bytes: [noteOffStatusByte, midiNoteA4, 0] }
    }
  );

  setHostStatus('Scheduled wam-midi note-on and note-off for A4.');
};

const boot = async () => {
  try {
    audioContext = new window.AudioContext();

    [hostGroupId] = await initializeWamHost(
      audioContext,
      'volca-share-sandbox-poc',
      'volca-share-sandbox-secret'
    );

    playButton.addEventListener('click', playSawNote);
    wamModuleSelect.addEventListener('change', async (event) => {
      try {
        await loadSelectedWam(event.target.value);
      } catch (error) {
        console.error(error);
        setHostStatus(`Module swap failed: ${error.message}`);
      }
    });

    await loadSelectedWam(wamModuleSelect.value);

    setButtonEnabled(true);
    setModuleSelectorEnabled(true);
  } catch (error) {
    console.error(error);
    setHostStatus(`Boot failed: ${error.message}`);
  }
};

window.addEventListener('beforeunload', () => {
  if (wamInstance && wamInstance.audioNode) {
    wamInstance.audioNode.destroy();
  }
  if (audioContext) {
    audioContext.close();
  }
});

boot();
