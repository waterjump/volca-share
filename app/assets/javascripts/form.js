$(function() {
    //var digit, myVar;
    $(".knob").each(function() {
      $(this).data("midi", 63);
    });

    $(".button").each(function() {
      $(this).data("active", true);
    });

    $(".button").click(function(){
      var vco = $(this).attr("id").split('_')[0];
      var value = $(this).data("active");
      var vco_knob = $("#" + vco + "_pitch");
      var input = $("input#" + vco + "_active" );
      if (value == true) {
        $(this).data("active", false);
        $(this).css("background-color", "#d6d7dc");
        vco_knob.css("background-color", "#d6d7dc");
        input.prop("checked", false);
      } else {
        $(this).data("active", true);
        $(this).css("background-color", "#fd9994");
        vco_knob.css("background-color", "#fd9994");
        input.prop("checked", true);
      }
    });

    var calculateClockOffset = function(value, place) {
      var midi_string = '' + value;
      var digit = midi_string[midi_string.length - place];

      return (parseInt(digit, 10)) * 9.98;
    };

    var setDisplay = function(value) {
      if (value > 99) {
        $("#hundreds").css('background-position', calculateClockOffset(value, 3) + '% 0');
      } else {
        $("#hundreds").css('background-position', '100% 0');
      }

      if (value > 9) {
        $("#tens").css('background-position', calculateClockOffset(value, 2) + '% 0');
      } else {
        $("#tens").css('background-position', '100% 0');
      }
      $("#ones").css('background-position', calculateClockOffset(value, 1) + '% 0');
    }

  var dragging = false,
    knob, my_span,
    o_y, last_angle, limit = 140,
    hundreds, tens, ones, midi;
  $('.knob').mousedown(function(e) {
    o_y = e.pageY; // clicked point
    e.preventDefault();
    e.stopPropagation();
    dragging = true;
    knob = $(e.target).closest('.knob');
    range_input = $("input[name=" + knob.attr('id') + "]");
    if (!knob.data("origin")) knob.data("origin", {
      top: knob.offset().top
    });

    last_angle = knob.data("last_angle") || 0;
  })

  $('.knob').mouseenter(function(){
    if (dragging)
      return false;
    setDisplay($(this).data("midi"));
  });

  $(document).mousemove(function(e) {
      if (dragging) {
        $('body').css("cursor", "ns-resize");
        var s_y = e.pageY; // start rotate point
        var degree = last_angle + (o_y - s_y);
        if (degree > limit) {
          last_angle = limit;
          o_y = s_y;
        }
        if (degree < -limit) {
          last_angle = -limit;
          o_y = s_y;
        }
        var degree = last_angle + (o_y - s_y); // relative to the last on
        if (s_y !== o_y) { //start rotate
          knob.css('-moz-transform', 'rotate(' + degree + 'deg)');
          knob.css('-moz-transform-origin', '50% 50%');
          knob.css('-webkit-transform', 'rotate(' + degree + 'deg)');
          knob.css('-webkit-transform-origin', '50% 50%');
          knob.css('-o-transform', 'rotate(' + degree + 'deg)');
          knob.css('-o-transform-origin', '50% 50%');
          knob.css('-ms-transform', 'rotate(' + degree + 'deg)');
          knob.css('-ms-transform-origin', '50% 50%');
          midi = Math.round(((63.5 / limit) * degree) + 63.5);
          range_input.val(midi);
          setDisplay(midi);
        }
      }
    }) // end mousemove

  $(document).mouseup(function(e) {
  	if (!dragging)
      return false;
    dragging = false
    var s_y = e.pageY;
    $('body').css("cursor", "default");

    // Saves the last angle for future iterations
    var s_rad = last_angle + (o_y - s_y);
    if (last_angle > limit) {
      last_angle = limit;
      s_y = o_y;
    }
    if (last_angle < -limit) {
      last_angle = -limit;
      s_y = o_y;
    }
    knob.data("last_angle", s_rad);
    knob.data("midi", midi);
  })
})
