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
