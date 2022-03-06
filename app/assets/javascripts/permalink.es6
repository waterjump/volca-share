$(function() {
  if ($('.emulator').length === 0) { return; }

  let permalinkQueryString = function() {
    let result = {};
    let dataMidiParams = [
      'attack', 'decay_release', 'cutoff_eg_int', 'octave', 'peak', 'cutoff',
      'lfo_rate', 'lfo_int', 'vco1_pitch', 'vco2_pitch', 'vco3_pitch'
    ];

    dataMidiParams.forEach(function(param) {
      result[param] = $(`#${param}`).data('midi');
    });

    [1, 2, 3].forEach(function(vcoNumber){
      result[`vco${vcoNumber}_active`] =
        $(`#vco${vcoNumber}_active_button`).data('active');
    });

    result['vco_group'] = $("input[name='patch[vco_group]']:checked").val();

    $('.bottom-row label').each(function() {
      if (!$(`input#${$(this).attr('for')}`).is(':checkbox')) { return; }
      if ($(this).attr('for').includes('wave')) { return; }

      const myInput = $(`input#${$(this).attr('for')}`);
      let param = myInput.attr('id').replace('patch_', '');
      result[param] = myInput.prop('checked');
    });

    result['lfo_wave'] =
      $('#patch_lfo_wave').prop('checked') ? 'square' : 'triangle';

    [1, 2, 3].forEach(function(vcoNumber){
      let checkbox = $(`#patch_vco${vcoNumber}_wave`);
      result[`vco${vcoNumber}_wave`] =
        checkbox.prop('checked') ? 'square' : 'sawtooth';
    });

    return Object.entries(result).map(param => param.join('=')).join('&');
  }

  $('#permalink-link').on('click tap', function() {
    let queryString = permalinkQueryString();
    window.history.replaceState({}, '', `${location.pathname}?${queryString}`);
    $('#green-check-mark').show();
    $('#green-check-mark').fadeOut(1000);
  });
});
