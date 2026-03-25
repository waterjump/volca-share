VS.MysteryPatchResults = function(options = {}) {
  const inTestEnvironment = options.inTestEnvironment === true;
  const getMysteryPatchNumber = options.getMysteryPatchNumber || function() { return ''; };
  const getHintedParams = options.getHintedParams || function() { return []; };
  const getGameFinished = options.getGameFinished || function() { return false; };

  let resultsData;

  const snakeToTitleize = function(str) {
    return String(str)
      .replace(/_/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, function(c) { return c.toUpperCase(); });
  };

  const revealElement = function(selector, animate = false) {
    if (!animate) {
      $(selector).show();
      return;
    }

    $(selector).fadeIn('slow');
  };

  this.hasResults = function() {
    return resultsData !== undefined && resultsData !== null;
  };

  this.setResultsData = function(data) {
    resultsData = data;
  };

  this.getResultsData = function() {
    return resultsData;
  };

  this.updateShowResultsButton = function() {
    const resultsModalIsOpen = $('#results-modal').hasClass('in');

    if (getGameFinished() && this.hasResults() && !resultsModalIsOpen) {
      $('#show-results').show();
      return;
    }

    $('#show-results').hide();
  }.bind(this);

  this.printResultsInfo = function(animate) {
    if (!this.hasResults()) { return; }

    const animateResults = animate && !inTestEnvironment;
    const animateInterval = animateResults ? 500 : 5;
    let $tbody = $("#results-table tbody");
    let emojiSummary = '';
    let i = 0;
    const entries = Object.entries(resultsData.parameter_scores);
    const hintedParams = new Set(getHintedParams());
    const voiceMidiMap = {
      10: 'poly',
      30: 'unison',
      50: 'octave',
      70: 'fifth',
      100: 'unison ring',
      120: 'poly ring'
    };

    const boolMap = {
      'true': 'on',
      'false': 'off'
    };

    $tbody.html('');

    const renderSummary = function() {
      revealElement('#kem-x-out', animateResults);
      $('#overall-score').html(
        [
          `<h3>Total score:</h3><div class='percentage'>`,
          `${resultsData.total_score}%</div>`,
          '<p class="share-subtitle">Come back tomorrow for a new mystery patch.</div>'
        ].join('')
      );
      revealElement('#overall-score', animateResults);
      $('#share-text').val([
        `Mystery Patch #${getMysteryPatchNumber()}: I guessed today's mystery synth patch with ${resultsData.total_score}% `,
        `accuracy.\n${emojiSummary}\n\nvolcashare.com/mystery_patch`,
        `\n\n#VSmysterypatch`
      ].join(''));
      revealElement('#share-results', animateResults);
      revealElement('#keep-playing', animateResults);
      this.updateShowResultsButton();
    }.bind(this);

    const renderEntry = function(entry) {
      let key = snakeToTitleize(entry[0]);
      const value = entry[1];
      let correctVal = value[0];
      let printableVal = value[1];
      const wasHinted = hintedParams.has(entry[0].toString());

      if (key === 'Voice') {
        printableVal = voiceMidiMap[value[1]];
        correctVal = voiceMidiMap[value[0]];
      } else if (key === 'Lfo Trigger Sync') {
        printableVal = boolMap[value[1]];
        correctVal = boolMap[value[0]];
      }

      const perc = value[3].toFixed(2);

      if ($tbody.length === 0) { $tbody = $("#results-table"); }

      const $tr = $("<tr>");
      if (animateResults) {
        $tr.css('display', 'none');
      }
      $tr.append($("<th class='result-param' scope='row'>").text(key));
      $tr.append($("<td>").text(correctVal));

      const $yourValueTd = $("<td>").text(printableVal);
      if (wasHinted) {
        $yourValueTd.append(' 💡');
      }
      $tr.append($yourValueTd);

      const $perctd = $('<td>');
      $perctd.text(perc);
      if (perc > 80) {
        $perctd.css('font-weight', 'bold');
        $perctd.css('color', '#080');
        $tr.addClass('table-success');
        emojiSummary += '🟩';
      } else if (perc < 50) {
        $perctd.css('font-weight', 'bold');
        $perctd.css('color', '#800');
        $tr.addClass('table-danger');
        emojiSummary += '🟥';
      } else {
        emojiSummary += '🟨';
      }
      if (wasHinted) {
        emojiSummary += '💡';
      }
      $tr.append($perctd);

      $tbody.append($tr);
      if (animateResults) {
        $tr.show();
      }
      $tr.addClass('fade-bg-white');
    };

    if (!animateResults) {
      entries.forEach(renderEntry);
      renderSummary();
      return;
    }

    const timer = setInterval(function() {
      if (i >= entries.length) {
        renderSummary();
        clearInterval(timer);
        return;
      }

      renderEntry(entries[i]);
      i += 1;
    }, animateInterval);
  }.bind(this);

  this.showResults = function(animate = false) {
    if (!this.hasResults()) { return; }

    $('#results-button').trigger('click');
    this.printResultsInfo(animate);
  }.bind(this);

  this.bindEvents = function() {
    $("#copy-results").on("click", function() {
      const text = $("#share-text").val();

      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(text)
          .then(function() { $("#copy-status").text("Copied!"); })
          .catch(function() { $("#copy-status").text("Couldn’t copy."); });
        return;
      }

      const $ta = $("#share-text");
      $ta.prop("readonly", false);
      $ta[0].focus();
      $ta[0].select();
      $ta[0].setSelectionRange(0, $ta.val().length);

      const ok = document.execCommand("copy");
      $ta.prop("readonly", true);
      window.getSelection().removeAllRanges();

      $("#copy-status").text(ok ? "Copied!" : "Couldn’t copy.");
    });

    $('#results-modal').on('shown.bs.modal hidden.bs.modal', function() {
      this.updateShowResultsButton();
    }.bind(this));

    $('#show-results').on('click tap', function(event) {
      if (!this.hasResults()) { return; }
      this.showResults(false);
      event.currentTarget.blur();
    }.bind(this));
  }.bind(this);
};
