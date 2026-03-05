$(function() {
  if (!VS.accordionSectionVisibility) {
    VS.accordionSectionVisibility = {};
  }

  $('.accordion-header').on('click tap', (e) => {
    const accordionHeader = $(e.currentTarget);
    const sectionName = accordionHeader.text().trim();
    if (sectionName === 'Support') {
      return;
    }
    VS.toggleAccordionSection(sectionName);
  });

  $('.accordion-body[style="display:none;"').each(function() {
    const accordionHeader = $(this).siblings('.accordion-header');
    const sectionName = accordionHeader.text().trim();
    const toggleControl = accordionHeader.find('.glyphicon');
    VS.accordionSectionVisibility[sectionName] = false;
    toggleControl.css({ transform: 'rotate(90deg)'});
  });

  $('[data-toggle="tooltip"]').tooltip();
});

VS.setCookie = function(name, value, days, path) {
  let expires = "; max-age=" + (24 * 60 * 60 * days);
  document.cookie = `${name}=${(value || "")}${expires}; path=${path};`;
};

VS.accordionSectionVisibility = VS.accordionSectionVisibility || {};

VS.findAccordionHeaderBySectionName = function(sectionName) {
  let matchedHeader = null;
  $('.accordion-header').each(function() {
    if ($(this).text().trim() === sectionName) {
      matchedHeader = $(this);
      return false;
    }
  });
  return matchedHeader;
};

VS.expandAccordionSection = function(sectionName) {
  const accordionHeader = VS.findAccordionHeaderBySectionName(sectionName);
  if (!accordionHeader || accordionHeader.length === 0) { return false; }

  const accordionBody = accordionHeader.siblings('.accordion-body');
  const toggleControl = accordionHeader.find('.glyphicon');
  VS.setCookie(`accordion${sectionName}`, 'open', 90, '/');
  accordionBody.slideDown(200);
  toggleControl.css({ transform: 'rotate(0deg)'});
  VS.accordionSectionVisibility[sectionName] = true;
  return true;
};

VS.collapseAccordionSection = function(sectionName) {
  const accordionHeader = VS.findAccordionHeaderBySectionName(sectionName);
  if (!accordionHeader || accordionHeader.length === 0) { return false; }

  const accordionBody = accordionHeader.siblings('.accordion-body');
  const toggleControl = accordionHeader.find('.glyphicon');
  VS.setCookie(`accordion${sectionName}`, 'closed', 90, '/');
  accordionBody.slideUp(200);
  toggleControl.css({ transform: 'rotate(90deg)'});
  VS.accordionSectionVisibility[sectionName] = false;
  return true;
};

VS.toggleAccordionSection = function(sectionName) {
  if (VS.accordionSectionVisibility[sectionName] === undefined) {
    VS.accordionSectionVisibility[sectionName] = true;
  }

  if (VS.accordionSectionVisibility[sectionName]) {
    return VS.collapseAccordionSection(sectionName);
  }

  return VS.expandAccordionSection(sectionName);
};

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
