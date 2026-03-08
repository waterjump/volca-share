$(function() {
  if (window.location.pathname !== '/mystery_patch') { return; }

  const { sequences, emulatorParams, mysteryPatchParams } = VS;
  const mysteryParams = mysteryPatchParams;
  const patch = emulatorParams;

  let mysteryPatchEngine;
  let gameHasStarted = false;
  let gameFinished = false;
  let mysteryPatchId;
  let digest;
  let gameData;
  let resultsData;
  let intervalId;
  const GAME_DURATION_SECONDS = 120;
  const updatePostGameMessage = function() {
    if (gameFinished) {
      $('#post-game-message').show();
      return;
    }

    $('#post-game-message').hide();
  };

  const updateShowResultsButton = function() {
    const resultsModalIsOpen = $('#results-modal').hasClass('in');
    const hasResults = resultsData !== undefined && resultsData !== null;
    if (gameFinished && hasResults && !resultsModalIsOpen) {
      $('#show-results').show();
      return;
    }
  };

  const setAudibleEngineSwitch = function(engineName) {
    const isMystery = engineName === 'mystery';
    $('#audible-engine-primary').toggleClass('active', !isMystery);
    $('#audible-engine-mystery').toggleClass('active', isMystery);
    $('#mystery-params-scrim').toggleClass('hidden', !isMystery);
  };

  const syncAudibleEngineSwitch = function(fallbackEngine = 'primary') {
    if (!VS.keysEmulatorBridge) {
      setAudibleEngineSwitch(fallbackEngine);
      return;
    }

    setAudibleEngineSwitch(VS.keysEmulatorBridge.getActiveAudibleEngine());
  };

  // TODO: Look into making sequences optional argument for audio engine so
  // I can remove this and sequences from the game mode.
  const sequence = [];
  for (let index = 0; index < 16; index++) {
    sequence.push(
      {
        index: index,
        note: 60,
        slide: false,
        activeStep: true
      }
    );
  }

  // Util functions
  const unrotate = function(rotatedString, rotationAmount) {
    return Array.from(rotatedString, (ch) => {
      const code = ch.charCodeAt(0);

      // Ruby rotates within printable ASCII (32..126) using mod 95
      if (code < 32 || code > 126) return ch;

      const unrot = ((code - 32 - rotationAmount) % 95 + 95) % 95;
      return String.fromCharCode(unrot + 32);
    }).join("");
  };

  const snakeToTitleize = (str) => {
    return String(str)
      .replace(/_/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }

  const rightNow = function() {
    return Math.floor(Date.now() / 1000);
  }

  const showNotStartedState = function() {
    clearInterval(intervalId);
    $('#timer').hide().text('');
    $('#submit-solution').hide();
    $('#show-results').hide();
    $('#post-game-message').hide();
    $('#audible-engine-mystery').addClass('start-game-callout');
  };

  let keyboardHintTimeout = null;

  const showStartedState = function() {
    $('#timer').show();
    $('#submit-solution').show();
    $('#show-results').hide();
    $('#post-game-message').hide();
    $('#audible-engine-mystery').removeClass('start-game-callout');

    keyboardHintTimeout = setTimeout(function() {
      $('#keyboard-highlight').addClass('start-keyboard-callout');
      const $usageBody = VS.findAccordionHeaderBySectionName('Usage').siblings('.accordion-body');
      $usageBody.addClass('start-keyboard-callout');
      VS.expandAccordionSection('Usage');
    }, 2000);
  };

  const showFinishedState = function() {
    clearInterval(intervalId);
    clearInterval(keyboardHintTimeout);
    $('#timer').show().text('Time\'s up!');
    $('#submit-solution').hide();
    $('#audible-engine-mystery').removeClass('start-game-callout');
    updateShowResultsButton();
    updatePostGameMessage();
  };

  const triggerSubmitSolution = function() {
    $('#submit-solution').trigger('click');
  };

  $(document).on('hideKeyboardHighlight', function() {
    if (keyboardHintTimeout) {
      clearInterval(keyboardHintTimeout);
    }
    $('#keyboard-highlight').removeClass('start-keyboard-callout');
    const $usageBody = VS.findAccordionHeaderBySectionName('Usage').siblings('.accordion-body');
    $usageBody.removeClass('start-keyboard-callout');
  })

  const parseCookieJson = function(key) {
    const encodedValue = getCookieValue(key);
    if (encodedValue === null) { return null; }

    try {
      return JSON.parse(decodeURIComponent(encodedValue));
    } catch (_) {
      return null;
    }
  };

  const setGameStartedCookie = function() {
    if (gameData !== undefined && gameData.mysteryPatchId === mysteryPatchId) {
      return;
    }

    const gameStart = rightNow();
    const gameDeadline = gameStart + GAME_DURATION_SECONDS;

    const cookiePayload = {
      mysteryPatchId: mysteryPatchId,
      gameStart: gameStart,
      gameDeadline: gameDeadline
    };
    const encodedValue = encodeURIComponent(JSON.stringify(cookiePayload));
    VS.setCookie('gameData', encodedValue, 1, '/mystery_patch');
    gameData = cookiePayload;
  };

  const setResultsCookie = function() {
    const cookiePayload = {
      mysteryPatchId: mysteryPatchId,
      timeSubmitted: rightNow(),
      results: resultsData
    };
    const encodedValue = encodeURIComponent(JSON.stringify(cookiePayload));
    VS.setCookie('resultsData', encodedValue, 1, '/mystery_patch');
  };

  const remainingTimeSeconds = function() {
    if (gameData !== undefined && gameData.mysteryPatchId === mysteryPatchId) {
      return gameData.gameDeadline - rightNow();
    }
    return GAME_DURATION_SECONDS;
  };

  const startTimer = function() {
    let secondsLeft = remainingTimeSeconds();
    clearInterval(intervalId);

    if (secondsLeft <= 0) {
      gameFinished = true;
      showFinishedState();
      return;
    }

    let minutes = Math.floor(secondsLeft / 60);
    let seconds = secondsLeft % 60;
    $('#timer').text(`${minutes.toString()}:${seconds.toString().padStart(2, '0')}`);

    intervalId = setInterval(function() {
      secondsLeft--;

      if (secondsLeft >= 0) {
        minutes = Math.floor(secondsLeft / 60);
        seconds = secondsLeft % 60;
        $('#timer').text(`${minutes.toString()}:${seconds.toString().padStart(2, '0')}`);
      } else {
        clearInterval(intervalId);
        if (!gameFinished) {
          triggerSubmitSolution();
        } else {
          showFinishedState();
        }
      }
    }, 1000);
  };

  const startGame = function() {
    if (gameHasStarted || gameFinished) { return; }

    gameHasStarted = true;
    showStartedState();
    setGameStartedCookie();
    startTimer();
  };

  const resumeGame = function() {
    if (!gameHasStarted || gameFinished) { return; }

    showStartedState();
    startTimer();
  };

  const resolveSessionStateFromCookies = function() {
    const now = rightNow();
    const cookieResultsData = parseCookieJson('resultsData');
    const cookieGameData = parseCookieJson('gameData');

    if (
      cookieResultsData !== null &&
      cookieResultsData.mysteryPatchId === mysteryPatchId &&
      now >= cookieResultsData.timeSubmitted
    ) {
      // Game finished in previous session
      return {
        status: 'finished',
        gameData: cookieGameData,
        resultsData: cookieResultsData.results
      };
    }

    if (
      cookieGameData !== null &&
      cookieGameData.mysteryPatchId === mysteryPatchId
    ) {
      if (now >= cookieGameData.gameDeadline) {
        // Abandoned
        return {
          status: 'expired_unsubmitted',
          gameData: cookieGameData,
          resultsData: null
        };
      }

      // Continue game
      return {
        status: 'active',
        gameData: cookieGameData,
        resultsData: null
      };
    }

    // New game
    return {
      status: 'not_started',
      gameData: null,
      resultsData: null
    };
  };

  const applySessionState = function(sessionState) {
    gameData = sessionState.gameData || undefined;
    resultsData = sessionState.resultsData || undefined;

    // previously finished
    if (sessionState.status === 'finished') {
      gameHasStarted = true;
      gameFinished = true;
      showFinishedState();
      $('#results-button').click();
      printResultsInfo(false);

      return;
    }

    // abandoned
    if (sessionState.status === 'expired_unsubmitted') {
      gameHasStarted = true;
      gameFinished = true;
      showFinishedState();
      triggerSubmitSolution();
      return;
    }

    // continue
    if (sessionState.status === 'active') {
      gameHasStarted = true;
      gameFinished = false;
      resumeGame();
      return;
    }

    // new game
    gameHasStarted = false;
    gameFinished = false;
    showNotStartedState();
    $('#pre-game-button').click();
  };

  const getMysteryPatch = function() {
    $.get('/mystery_patch.json').done(function(encryptedParams) {
      // Rotate back characters by todays UTC day of month
      const dayOfMonth = new Date().getUTCDate();
      mysteryPatchId = encryptedParams.id;
      digest = encryptedParams.digest;
      decryptedParams = unrotate(encryptedParams.patch, dayOfMonth);

      const base64Salt = btoa('salt489');
      // remove base64 salt from end of string, then base64 decode
      const base64String = decryptedParams.slice(0, -base64Salt.length);
      const decodedString = atob(base64String);
      const mysteryParamsArray = JSON.parse(decodedString);
      mysteryParams.setAllParams(mysteryParamsArray);
      mysteryPatchEngine = new VS.KeysAudioEngine(mysteryParams, sequence);
      mysteryPatchEngine.init();
      if (VS.keysEmulatorBridge) {
        VS.keysEmulatorBridge.registerMysteryEngine(mysteryPatchEngine, mysteryParams);
      }
      syncAudibleEngineSwitch();

      // HANDLE COOKIE-RESTORED GAME SESSION
      const sessionState = resolveSessionStateFromCookies();
      applySessionState(sessionState);
    });
  };

  $('#audible-engine-primary').on('click tap', function() {
    if (VS.keysEmulatorBridge) {
      VS.keysEmulatorBridge.setActiveAudibleEngine('primary');
    }
    syncAudibleEngineSwitch('primary');
    this.blur();
  });

  $('#audible-engine-mystery').on('click tap', function() {
    if (VS.keysEmulatorBridge) {
      VS.keysEmulatorBridge.setActiveAudibleEngine('mystery');
    }
    syncAudibleEngineSwitch('primary');
    if (!gameHasStarted) { startGame(); }
    this.blur();
  });

  $(document).on('keydown', function(event) {
    const targetTag = (event.target && event.target.tagName || '').toLowerCase();
    if (['input', 'textarea', 'select'].includes(targetTag)) { return; }

    if (event.keyCode === 37) {
      $('#audible-engine-primary').trigger('click');
    } else if (event.keyCode === 39) {
      $('#audible-engine-mystery').trigger('click');
    }
  });

  $("#copy-results").on("click", function () {
    let text = $("#share-text").val();

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text)
        .then(function () { $("#copy-status").text("Copied!"); })
        .catch(function () { $("#copy-status").text("Couldn’t copy."); });
      return;
    }

    // fallback (works without async)
    let $ta = $("#share-text");
    $ta.prop("readonly", false);
    $ta[0].focus();
    $ta[0].select();
    $ta[0].setSelectionRange(0, $ta.val().length);

    let ok = document.execCommand("copy");
    $ta.prop("readonly", true);
    window.getSelection().removeAllRanges();

    $("#copy-status").text(ok ? "Copied!" : "Couldn’t copy.");
  });

  $('#results-modal').on('shown.bs.modal hidden.bs.modal', function() {
    updateShowResultsButton();
  });

  $('#show-results').on('click tap', function() {
    if (resultsData === undefined || resultsData === null) { return; }
    $('#results-button').trigger('click');
    printResultsInfo(false);
    this.blur();
  });

  const printResultsInfo = function(animate) {
    let animateInterval = animate ? 500 : 5;
    let $tbody = $("#results-table tbody");
    let emojiSummary = '';
    $tbody.html('');
    let i = 0;
    let entries = Object.entries(resultsData.parameter_scores);
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

    let timer = setInterval(function () {

      // When entries are all done being listed
      if (i >= entries.length) {
        $('#kem-x-out').fadeIn('slow');
        $('#overall-score').html(
          [
            `<h3>Total score:</h3><div class='percentage'>`,
            `${resultsData.total_score}%</div>`
          ].join('')
        ).fadeIn('slow');
        $('#share-text').val([
          `I guessed today's mystery synth patch with ${resultsData.total_score}% `,
          `accuracy.\n${emojiSummary}\n\nvolcashare.com/mystery_patch`,
          `\n\n#VSmysterypatch`
        ].join('')
        );
        $('#share-results').fadeIn('slow');
        $('#keep-playing').fadeIn('slow');
        updateShowResultsButton();

        clearInterval(timer);
        return;
      }

      let key = snakeToTitleize(entries[i][0]);
      let value = entries[i][1];

      let correctVal = value[0];
      let printableVal = value[1];

      // Map voice midi val to voice name
      if (key === 'Voice') {
        printableVal = voiceMidiMap[value[1]];
        correctVal = voiceMidiMap[value[0]]
      } else if (key === 'Lfo Trigger Sync') {
        printableVal = boolMap[value[1]];
        correctVal = boolMap[value[0]];
      }

      let perc = value[3].toFixed(2);

      if ($tbody.length === 0) $tbody = $("#results-table"); // fallback if no tbody

      let $tr = $("<tr>");
      $tr.css('display', 'none');
      $tr.append($("<th class='result-param' scope='row'>").text(key));
      $tr.append($("<td>").text(correctVal));
      $tr.append($("<td>").text(printableVal));
      let $perctd = $('<td>');
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
      $tr.append($perctd);

      $tbody.append($tr);
      $tr.show();
      $tr.addClass('fade-bg-white');

      i += 1;
    }, animateInterval);
  };

  // When '#submit-solution' button is clicked, gather patch params
  // from knob data attributes, POST to /mystery_patch/
  $('#submit-solution').on('click tap', function() {
    gameFinished = true;
    showFinishedState();

    const solutionParams = {
      id: mysteryPatchId,
      digest: digest,
      patch: {
        voice: $('#voice').data('midi'),
        detune: $('#detune').data('midi'),
        portamento: $('#portamento').data('midi'),
        vco_eg_int: $('#vco_eg_int').data('midi'),
        attack: $('#attack').data('midi'),
        decay_release: $('#decay_release').data('midi'),
        vcf_eg_int: $('#vcf_eg_int').data('midi'),
        peak: $('#peak').data('midi'),
        cutoff: $('#cutoff').data('midi'),
        sustain: $('#sustain').data('midi'),
        lfo_rate: $('#lfo_rate').data('midi'),
        lfo_pitch_int: $('#lfo_pitch_int').data('midi'),
        lfo_cutoff_int: $('#lfo_cutoff_int').data('midi'),
        delay_time: $('#delay_time').data('midi'),
        delay_feedback: $('#delay_feedback').data('midi'),
        lfo_trigger_sync: $('input#patch_lfo_trigger_sync').prop('checked'),
        step_trigger: $('input#patch_step_trigger').prop('checked'),
        lfo_shape: patch.lfo.shape === 'sawtooth' ? 'saw' : patch.lfo.shape
      }
    };

    // Submit solution
    $.post('/mystery_patch', solutionParams).done(function(response) {
      $('#results-button').click();

      resultsData = response.results;
      setResultsCookie();
      printResultsInfo(true);
    });
  });

  showNotStartedState();
  getMysteryPatch();
  syncAudibleEngineSwitch('primary');
});
