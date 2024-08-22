const input = function() {
  this.addListener = function(event, channel, callback) {};
};

window.WebMidi = {
  enable: function(successCallback, errorCallback) {
    if (successCallback) successCallback();
  },
  inputs: [new input],
  getInputByName: function() { return this.inputs[0] }
};

