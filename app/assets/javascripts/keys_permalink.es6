$(function() {
  if ($('.keys.emulator').length === 0) { return; }

  let permalinkQueryString = function() {
    let result = {};
    let dataMidiParams = [
      'voice', 'detune', 'portamento', 'vco_eg_int', 'attack', 'decay_release',
      'vcf_eg_int', 'octave', 'peak', 'cutoff', 'sustain',
      'lfo_rate', 'lfo_pitch_int', 'lfo_cutoff_int', 'delay_time', 'delay_feedback'
    ];

    dataMidiParams.forEach(function(param) {
      result[param] = $(`#${param}`).data('midi');
    });

    $('.bottom-row label').each(function() {
      if (!$(`input#${$(this).attr('for')}`).is(':checkbox')) { return; }
      if ($(this).attr('for').includes('wave')) { return; }

      const myInput = $(`input#${$(this).attr('for')}`);
      let param = myInput.attr('id').replace('patch_', '');
      result[param] = myInput.prop('checked');
    });

    result['lfo_shape'] =
      $('input[name="patch[lfo_shape]"]:checked').val();

    return Object.entries(result).map(param => param.join('=')).join('&');
  }

  $('#permalink').on('click tap', function() {
    let queryString = permalinkQueryString();
    window.history.replaceState({}, '', `${location.pathname}?${queryString}`);
    $('.green-check-mark').show();
    $('.green-check-mark').fadeOut(2000);
  });
});
