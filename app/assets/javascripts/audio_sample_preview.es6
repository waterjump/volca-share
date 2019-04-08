$(function() {
  if (($('body.show').length === 0) && ($('body.form').length === 0)) {
  return;
}
  const loadAudioSample = function() {
    const element = $('.sample');
    if (element.data('embed-code') === undefined) {
      return;
    }
    element.html(element.data('embed-code'));
  };

  loadAudioSample();
});
