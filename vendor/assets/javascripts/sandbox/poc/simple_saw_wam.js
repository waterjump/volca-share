import { WebAudioModule, WamNode, addFunctionModule } from 'wam-sdk';

const moduleId = 'com.volcashare.sandbox.simple-saw';

const getSimpleSawProcessor = (registeredModuleId) => {
  const audioWorkletGlobalScope = globalThis;
  const ModuleScope = audioWorkletGlobalScope.webAudioModules.getModuleScope(registeredModuleId);
  const { WamProcessor } = ModuleScope;
  const midiNoteToFrequency = (noteNumber) => {
    return 440 * (2 ** ((noteNumber - 69) / 12));
  };

  class SimpleSawProcessor extends WamProcessor {
    constructor(options) {
      super(options);

      this._activeNote = null;
      this._frequency = 440;
      this._phase = 0;
      this._level = 0.15;
    }

    _onMidi(midiData) {
      const [status, noteNumber, noteVelocity] = midiData.bytes;
      const command = status & 0xf0;

      if (command === 0x90 && noteVelocity > 0) {
        this._activeNote = noteNumber;
        this._frequency = midiNoteToFrequency(noteNumber);
        return;
      }

      const isNoteOff = command === 0x80 || (command === 0x90 && noteVelocity === 0);
      if (isNoteOff && this._activeNote === noteNumber) {
        this._activeNote = null;
      }
    }

    _process(startSample, endSample, inputs, outputs) {
      const output = outputs[0];
      if (!output || !output.length) { return; }

      const leftChannel = output[0];
      const rightChannel = output[1] || output[0];

      if (this._activeNote === null) {
        for (let index = startSample; index < endSample; index += 1) {
          leftChannel[index] = 0;
          rightChannel[index] = 0;
        }
        return;
      }

      const phaseIncrement = this._frequency / sampleRate;

      for (let index = startSample; index < endSample; index += 1) {
        const sample = ((this._phase * 2) - 1) * this._level;

        leftChannel[index] = sample;
        rightChannel[index] = sample;

        this._phase += phaseIncrement;
        if (this._phase >= 1) {
          this._phase -= 1;
        }
      }
    }
  }

  if (audioWorkletGlobalScope.AudioWorkletProcessor && !ModuleScope.SimpleSawProcessor) {
    ModuleScope.SimpleSawProcessor = SimpleSawProcessor;
    registerProcessor(registeredModuleId, SimpleSawProcessor);
  }

  return ModuleScope.SimpleSawProcessor;
};

class SimpleSawNode extends WamNode {
  static async addModules(audioContext, registeredModuleId) {
    await super.addModules(audioContext, registeredModuleId);
    await addFunctionModule(audioContext.audioWorklet, getSimpleSawProcessor, registeredModuleId);
  }

  constructor(module) {
    super(module, {
      numberOfInputs: 0,
      numberOfOutputs: 1,
      outputChannelCount: [2],
      processorOptions: { useSab: false }
    });
  }
}

export default class SimpleSawWam extends WebAudioModule {
  constructor(groupId, audioContext) {
    super(groupId, audioContext);

    this._descriptor = {
      ...this._descriptor,
      identifier: moduleId,
      name: 'Simple Saw Sandbox',
      vendor: 'VolcaShare',
      description: 'Minimal WAM sandbox synth that responds to MIDI note events.',
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
    await SimpleSawNode.addModules(this.audioContext, this.moduleId);

    const audioNode = new SimpleSawNode(this);
    await audioNode._initialize();

    return audioNode;
  }

  async createGui() {
    const root = document.createElement('section');
    root.className = 'wam-plugin-card';

    const title = document.createElement('h3');
    title.textContent = this.name;

    const copy = document.createElement('p');
    copy.className = 'wam-plugin-copy';
    copy.textContent = 'The plugin itself has no play button. It waits for the host to send wam-midi note events.';

    const meta = document.createElement('div');
    meta.className = 'wam-plugin-meta';
    meta.innerHTML = `
      <div><strong>Module ID:</strong> ${this.moduleId}</div>
      <div><strong>Instance ID:</strong> ${this.instanceId}</div>
      <div><strong>Signal Path:</strong> Mono synth duplicated to stereo output</div>
      <div><strong>MIDI Mapping:</strong> Note number is converted to frequency inside the processor</div>
    `;

    root.append(title, copy, meta);

    return root;
  }
}
