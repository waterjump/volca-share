
$(function() {
  $('#synth_name_button').on('click tap', function(e)
    {
      e.preventDefault();

      $.ajax({
        url: 'synth_patch_name',
        data: { format: 'json' },
        error(jqHXR, textStatus, errorThrown) {
          alert(errorThrown);
        },
        success(data) {
          $('#name').text(data['name']);
          console.log(data);
        }
      });
    }
  );
});