$(function() {

    var inputForId = function(id){
      return $('input#' + id);
    };

    $('.knob').each(function() {
      $(this).data('midi', 63);
    });

    $('.button').each(function() {
      $(this).data('active', true);
    });

    $('.bottom-row label').click(function(){
      console.log(this);
      if ($('input#' + $(this).attr('for')).is(':checkbox')) {
        $(this).find('span .light').toggleClass('lit');
      } else {
        $('.light[data-radio]').each(function() {
          console.log(this);
          $(this).removeClass('lit');
        });
        $(this).find('span .light').addClass('lit');
      }
    });

    $('.button').click(function(){
      var vco, valie, vcoKnob, input;
      vco = $(this).attr('id').split('_')[0];
      value = $(this).data('active');
      vcoKnob = $('#patch_' + vco + '_pitch');
      input = inputForId($(this).attr('id'));
      if (value == true) {
        $(this).data('active', false);
        $(this).css('background-color', '#d6d7dc');
        vcoKnob.css('background-color', '#d6d7dc');
        input.prop('checked', false);
      } else {
        $(this).data('active', true);
        $(this).css('background-color', '#fd9994');
        vcoKnob.css('background-color', '#fd9994');
        input.prop('checked', true);
      }
    });

    var calculateClockOffset = function(value, place) {
      var midiString = '' + value;
      var digit = midiString[midiString.length - place];

      return (parseInt(digit, 10)) * 9.98;
    };

    var setDisplay = function(value) {
      if (value > 99) {
        $('#hundreds').css('background-position', calculateClockOffset(value, 3) + '% 0');
      } else {
        $('#hundreds').css('background-position', '100% 0');
      }

      if (value > 9) {
        $('#tens').css('background-position', calculateClockOffset(value, 2) + '% 0');
      } else {
        $('#tens').css('background-position', '100% 0');
      }
      $('#ones').css('background-position', calculateClockOffset(value, 1) + '% 0');
    }

  var dragging = false,
    knob, my_span,
    clickedPoint, lastAngle, limit = 140,
    hundreds, tens, ones, midi;

  $('.knob').mousedown(function(e) {
    clickedPoint = e.pageY;
    e.preventDefault();
    e.stopPropagation();
    dragging = true;
    knob = $(e.target).closest('.knob');
    rangeInput = inputForId('patch_' + $(this).attr('id'))
    if (!knob.data('origin')) knob.data('origin', {
      top: knob.offset().top
    });

    lastAngle = knob.data('lastAngle') || 0;
  })

  $('.knob').mouseenter(function(){
    if (dragging)
      return false;
    setDisplay($(this).data('midi'));
  });

  $(document).mousemove(function(e) {
      if (dragging) {
        $('body').css('cursor', 'ns-resize');
        var currentPoint = e.pageY;
        var degree = lastAngle + (clickedPoint - currentPoint);
        if (degree > limit) {
          lastAngle = limit;
          clickedPoint = currentPoint;
        }
        if (degree < -limit) {
          lastAngle = -limit;
          clickedPoint = currentPoint;
        }
        var degree = lastAngle + (clickedPoint - currentPoint); // relative to the last on
        if (currentPoint !== clickedPoint || degree === -limit || degree === limit) { //start rotate
          knob.css('-moz-transform', 'rotate(' + degree + 'deg)');
          knob.css('-moz-transform-origin', '50% 50%');
          knob.css('-webkit-transform', 'rotate(' + degree + 'deg)');
          knob.css('-webkit-transform-origin', '50% 50%');
          knob.css('-o-transform', 'rotate(' + degree + 'deg)');
          knob.css('-o-transform-origin', '50% 50%');
          knob.css('-ms-transform', 'rotate(' + degree + 'deg)');
          knob.css('-ms-transform-origin', '50% 50%');
          midi = Math.round(((63.5 / limit) * degree) + 63.5);
          rangeInput.val(midi);
          setDisplay(midi);
        }
      }
    })

  $(document).mouseup(function(e) {
    if (!dragging)
      return false;
    dragging = false;
    var currentPoint = e.pageY;
    $('body').css('cursor', 'default');

    // Saves the last angle for future iterations
    var currentAngle = lastAngle + (clickedPoint - currentPoint);
    if (lastAngle > limit) {
      lastAngle = limit;
      currentPoint = clickedPoint;
    }
    if (lastAngle < -limit) {
      lastAngle = -limit;
      currentPoint = clickedPoint;
    }
    knob.data('lastAngle', currentAngle);
    knob.data('midi', midi);
  })
})
