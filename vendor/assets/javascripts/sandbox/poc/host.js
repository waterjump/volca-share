import { initializeWamHost } from 'wam-sdk';
import SimpleSawWam from 'poc-simple-saw-wam';

const noteOnStatusByte = 0x90;
const noteOffStatusByte = 0x80;
const midiNoteA4 = 69;
const velocity = 100;
const noteDurationSeconds = 1;

const hostStatus = document.querySelector('#host-status');
const playButton = document.querySelector('#play-note-button');
const pluginMount = document.querySelector('#plugin-mount');

let audioContext = null;
let wamInstance = null;

const setHostStatus = (message) => {
  hostStatus.textContent = message;
};

const setButtonEnabled = (enabled) => {
  playButton.disabled = !enabled;
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

    const [hostGroupId] = await initializeWamHost(
      audioContext,
      'volca-share-sandbox-poc',
      'volca-share-sandbox-secret'
    );

    wamInstance = await SimpleSawWam.createInstance(hostGroupId, audioContext);
    wamInstance.audioNode.connect(audioContext.destination);

    const pluginGui = await wamInstance.createGui();
    pluginMount.replaceChildren(pluginGui);

    playButton.addEventListener('click', playSawNote);
    setButtonEnabled(true);
    setHostStatus('Host ready. Click the button to send MIDI note 69 to the WAM.');
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
