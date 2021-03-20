
$(function() {
  let canClick = true;
  $('#synth_name_button').on('click tap', function(e)
    {
      if (canClick == false) { return; }

      canClick = false
      e.preventDefault();
      $('#name').html('<span class="thinking">Thinking...</span>');
      $('#new_bass_patch').css('color', '#ffffff');
      $('#new_keys_patch').css('color', '#ffffff');
      setTimeout(
        function() {
          $.ajax({
            url: 'synth_patch_name',
            data: { format: 'json' },
            error(jqHXR, textStatus, errorThrown) {
              alert(errorThrown);
              canClick = true;
            },
            success(data) {
              $('#name').text(data['name']);

              urlSafePatchName = encodeURIComponent(data['name']);
              $('#new_bass_patch').css('color', '#666666');
              $('#new_keys_patch').css('color', '#666666');
              $('a#new_bass_patch').attr('href', `patch/new?name=${urlSafePatchName}`);
              $('a#new_keys_patch').attr('href', `keys/patch/new?name=${urlSafePatchName}`);
              canClick = true;
            }
          });
        }, 800
      );
    }
  );
});
