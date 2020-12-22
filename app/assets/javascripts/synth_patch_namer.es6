
$(function() {
  $('#synth_name_button').on('click tap', function(e)
    {
      e.preventDefault();
      $('#name').html('<span class="thinking">Thinking...</span>');
      setTimeout(
        function() {
          $.ajax({
            url: 'synth_patch_name',
            data: { format: 'json' },
            error(jqHXR, textStatus, errorThrown) {
              alert(errorThrown);
            },
            success(data) {
              $('#name').text(data['name']);

              urlSafePatchName = encodeURIComponent(data['name']);
              $('a#new_bass_patch').attr('href', `patch/new?name=${urlSafePatchName}`);
              $('a#new_keys_patch').attr('href', `keys/patch/new?name=${urlSafePatchName}`);
            }
          });
        }, 800
      );
    }
  );
});
