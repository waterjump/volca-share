$(function() {
  const accordionSectionVisibility = {};

  const setCookie = function(name, value, days) {
    let expires = "; max-age=" + (24 * 60 * 60 * days);
    document.cookie = `${name}=${(value || "")}${expires}; path=/;`;
  }

  $('.accordion-header').on('click tap', (e) => {
    const accordionHeader = $(e.currentTarget);
    const toggleControl = accordionHeader.find('.glyphicon');
    const sectionName = accordionHeader.text().trim();
    if (sectionName === 'Support') {
      return;
    }
    if (accordionSectionVisibility[sectionName] === undefined) {
      accordionSectionVisibility[sectionName] = true;
    }
    if (accordionSectionVisibility[sectionName]) {
      setCookie(`accordion${sectionName}`, 'closed', 90);
      accordionHeader.siblings('.accordion-body').slideUp(200);
      toggleControl.css({ transform: 'rotate(90deg)'});
      accordionSectionVisibility[sectionName] = false;
    } else {
      setCookie(`accordion${sectionName}`, 'open', 90);
      accordionHeader.siblings('.accordion-body').slideDown(200);
      toggleControl.css({ transform: 'rotate(0deg)'});
      accordionSectionVisibility[sectionName] = true;
    }
  });

  $('.accordion-body[style="display:none;"').each(function() {
    const accordionHeader = $(this).siblings('.accordion-header');
    const sectionName = accordionHeader.text().trim();
    const toggleControl = accordionHeader.find('.glyphicon');
    accordionSectionVisibility[sectionName] = false;
    toggleControl.css({ transform: 'rotate(90deg)'});
  });

  $('[data-toggle="tooltip"]').tooltip();
});

VS.autoRotateAllKnobs = function() {
  $('.knob').each(function() {
    let knobInstance;

    if ($(this).hasClass('dark')) {
      knobInstance = new VS.SnapKnob(this);
    } else {
      knobInstance = new VS.Knob(this);
    }

    knobInstance.setKnob($(this).data('midi'));
  });
};

VS.setActiveKnob = function(element) {
  if ($(element).hasClass('dark')) {
    VS.activeKnob = new VS.SnapKnob(element);
  } else {
    VS.activeKnob = new VS.Knob(element);
  }
};
