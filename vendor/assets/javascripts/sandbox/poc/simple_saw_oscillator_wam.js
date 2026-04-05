import { WebAudioModule } from 'wam-sdk';

const moduleId = 'com.volcashare.sandbox.simple-saw-oscillator';

const midiNoteToFrequency = (noteNumber) => {
  return 440 * (2 ** ((noteNumber - 69) / 12));
};

class SimpleSawOscillatorNode extends GainNode {
  constructor(module) {
    super(module.audioContext, { gain: 1 });

    this.module = module;
    this._activeVoices = new Map();
  }

  get groupId() {
    return this.module.groupId;
  }

  get moduleId() {
    return this.module.moduleId;
  }

  get instanceId() {
    return this.module.instanceId;
  }

  async getParameterInfo() {
    return {};
  }

  async getParameterValues() {
    return {};
  }

  async setParameterValues() {}

  async getState() {
    return {};
  }

  async setState() {}

  async getCompensationDelay() {
    return 0;
  }

  connectEvents() {}

  disconnectEvents() {}

  scheduleEvents(...events) {
    events.forEach((event) => {
      if (event.type !== 'wam-midi') { return; }

      const eventTime = Number.isFinite(event.time) ? event.time : this.context.currentTime;
      this._handleMidiEvent(event.data.bytes, eventTime);
      this.dispatchEvent(new CustomEvent(event.type, { bubbles: true, detail: event }));
    });
  }

  destroy() {
    this._activeVoices.forEach((voice, noteNumber) => {
      this._stopVoice(noteNumber, this.context.currentTime);
    });
    this.disconnect();
  }

  _handleMidiEvent(bytes, time) {
    const [status, noteNumber, velocity] = bytes;
    const command = status & 0xf0;

    if (command === 0x90 && velocity > 0) {
      this._startVoice(noteNumber, time, velocity);
      return;
    }

    if (command === 0x80 || (command === 0x90 && velocity === 0)) {
      this._stopVoice(noteNumber, time);
    }
  }

  _startVoice(noteNumber, time, velocity) {
    this._stopVoice(noteNumber, time);

    const oscillator = new OscillatorNode(this.context, {
      type: 'sawtooth',
      frequency: midiNoteToFrequency(noteNumber)
    });
    const amp = new GainNode(this.context, { gain: 0 });
    const level = Math.max(0.0001, velocity / 127) * 0.2;

    oscillator.connect(amp);
    amp.connect(this);

    amp.gain.cancelScheduledValues(time);
    amp.gain.setValueAtTime(0, time);
    amp.gain.linearRampToValueAtTime(level, time + 0.005);

    oscillator.start(time);

    this._activeVoices.set(noteNumber, { oscillator, amp });
  }

  _stopVoice(noteNumber, time) {
    const voice = this._activeVoices.get(noteNumber);
    if (!voice) { return; }

    const releaseEnd = time + 0.02;

    voice.amp.gain.cancelScheduledValues(time);
    voice.amp.gain.setValueAtTime(voice.amp.gain.value, time);
    voice.amp.gain.linearRampToValueAtTime(0, releaseEnd);
    voice.oscillator.stop(releaseEnd);
    voice.oscillator.onended = () => {
      voice.oscillator.disconnect();
      voice.amp.disconnect();
    };

    this._activeVoices.delete(noteNumber);
  }
}

export default class SimpleSawOscillatorWam extends WebAudioModule {
  constructor(groupId, audioContext) {
    super(groupId, audioContext);

    this._descriptor = {
      ...this._descriptor,
      identifier: moduleId,
      name: 'Simple Saw Oscillator Sandbox',
      vendor: 'VolcaShare',
      description: 'Minimal WAM sandbox synth that uses OscillatorNode and responds to MIDI note events.',
      version: '0.1.0',
      apiVersion: '2.0.0-alpha.6',
      isInstrument: true,
      hasAudioInput: false,
      hasAudioOutput: true,
      hasAutomationInput: false,
      hasAutomationOutput: false,
      hasMidiInput: true,
      hasMidiOutput: false,
      hasMpeInput: false,
      hasMpeOutput: false,
      hasOscInput: false,
      hasOscOutput: false,
      hasSysexInput: false,
      hasSysexOutput: false
    };
  }

  async createAudioNode() {
    return new SimpleSawOscillatorNode(this);
  }

  async createGui() {
    const root = document.createElement('section');
    root.className = 'wam-plugin-card';

    const title = document.createElement('h3');
    title.textContent = this.name;

    const copy = document.createElement('p');
    copy.className = 'wam-plugin-copy';
    copy.textContent = 'This plugin uses built-in OscillatorNode voices on the main thread and waits for the host to send wam-midi note events.';

    const meta = document.createElement('div');
    meta.className = 'wam-plugin-meta';
    meta.innerHTML = `
      <div><strong>Module ID:</strong> ${this.moduleId}</div>
      <div><strong>Instance ID:</strong> ${this.instanceId}</div>
      <div><strong>Signal Path:</strong> OscillatorNode -> GainNode envelope -> plugin output</div>
      <div><strong>MIDI Mapping:</strong> Note number is converted to frequency before creating the oscillator</div>
    `;

    root.append(title, copy, meta);

    return root;
  }
}
