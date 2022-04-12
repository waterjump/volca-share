$(function() {
  const accordionSectionVisibility = {};

  $('.accordion-header').on('click tap', (e) => {
    const accordionHeader = $(e.currentTarget);
    const toggleControl = accordionHeader.find('.glyphicon');
    const sectionName = accordionHeader.text();
    if (accordionSectionVisibility[sectionName] === undefined) {
      accordionSectionVisibility[sectionName] = true;
    }
    if (accordionSectionVisibility[sectionName]) {
      accordionHeader.siblings('.accordion-body').slideUp(200);
      toggleControl.css({ transform: 'rotate(90deg)'});
      accordionSectionVisibility[sectionName] = false;
    } else {
      accordionHeader.siblings('.accordion-body').slideDown(200);
      toggleControl.css({ transform: 'rotate(0deg)'});
      accordionSectionVisibility[sectionName] = true;
    }
  });
});
