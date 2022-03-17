// TODO: avoid global scope
const midiMultiples = {
  0: 'C',
  1: 'C#',
  2: 'D',
  3: 'D#',
  4: 'E',
  5: 'F',
  6: 'F#',
  7: 'G',
  8: 'G#',
  9: 'A',
  10: 'A#',
  11: 'B'
};

VS.midiNoteNumbers = {};

let i = 0;
while (i < 128) {
  VS.midiNoteNumbers[i] = midiMultiples[i % 12] + (Math.floor(i / 12) - 2);
  i++;
}
