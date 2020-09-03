$(function() {
  let shouldStop = false;
  let stopped = false;

  const handleSuccess = function(stream) {
    const options = {mimeType: 'audio/webm'};
    const recordedChunks = [];
    const mediaRecorder = new MediaRecorder(stream, options);

    mediaRecorder.onstart = function() { stopped = false };

    mediaRecorder.ondataavailable =  function(e) {
      if (e.data.size > 0) {
        recordedChunks.push(e.data);
      }

      if(shouldStop === true && stopped === false) {
        mediaRecorder.stop();
        stopped = true;
        stream.getTracks()[0].stop();
      }
    }

    mediaRecorder.addEventListener('stop', function() {
      console.log('stopped!');
      shouldStop = false

      blob = new Blob(recordedChunks, { type: 'audio/webm' });

      let blobUrl =  URL.createObjectURL(blob);
      $('#source').attr('src', blobUrl);
      $("#player")[0].load();

      let xhr = new XMLHttpRequest();
      xhr.responseType = 'json';
      xhr.open("POST", '/keys/audio_clip_upload', true);
      xhr.onload = function (oEvent) {
        $('#patch_audio_clip').val(xhr.response.path);
      };

      let formData = new FormData();
      formData.append("authenticity_token", $('input[name=authenticity_token]').val());
      formData.append("audio_clip", blob);

      xhr.send(formData);
    });

    mediaRecorder.start(100);
  };

  $('#record').on('click', function() {
    navigator.mediaDevices.enumerateDevices()
    .then(function(devices) {
      devices.forEach(function(device) {
        if (device.kind == 'audioinput' && device.deviceId == '926958eeedd418bf7ce3d4f9af22723bfb95322b8514d1125a784b169f9f3485') {
          navigator.mediaDevices.getUserMedia({ audio: { deviceId: device.deviceId }, video: false })
             .then(handleSuccess);
        }
      });
    })
    .catch(function(err) {
      console.log(err.name + ": " + err.message);
    });
  });

  $('#stop').on('click', function() {
    shouldStop = true;
  });
});
