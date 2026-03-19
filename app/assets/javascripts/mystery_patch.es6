$(function() {
  if (window.location.pathname !== '/mystery_patch') { return; }

  const { sequences, emulatorParams, mysteryPatchParams } = VS;
  const mysteryParams = mysteryPatchParams;
  const patch = emulatorParams;

  let mysteryPatchEngine;
  let gameHasStarted = false;
  let gameFinished = false;
  let mysteryPatchId;
  let mysteryPatchNumber;
  let digest;
  let gameData;
  let resultsData;
  let intervalId;
  let submissionInFlight = false;
  let hintRequestInFlight = false;
  let hintsUsed = 0;
  let hintedParams = new Set();
  let blinkingHintParams = new Set();
  let hintBlinkVisible = false;
  let hintBlinkIntervalId = null;
  let hintBlinkTimeoutId = null;
  const inTestEnvironment = $('body').attr('data-test-env') === 'true';
  const GAME_DURATION_SECONDS = 120;
  const MAX_HINTS = 2;
  const HINT_BLINK_INTERVAL_MS = 500;
  const HINT_BLINK_DURATION_MS = 5000;
  const HINT_TARGET_SELECTORS = {
    voice: ['#voice'],
    detune: ['#detune'],
    portamento: ['#portamento'],
    vco_eg_int: ['#vco_eg_int'],
    cutoff: ['#cutoff'],
    peak: ['#peak'],
    vcf_eg_int: ['#vcf_eg_int'],
    lfo_rate: ['#lfo_rate'],
    lfo_pitch_int: ['#lfo_pitch_int'],
    lfo_cutoff_int: ['#lfo_cutoff_int'],
    attack: ['#attack'],
    decay_release: ['#decay_release'],
    sustain: ['#sustain'],
    delay_time: ['#delay_time'],
    delay_feedback: ['#delay_feedback'],
    lfo_shape: ['#lfo_shape_saw_light', '#lfo_shape_triangle_light', '#lfo_shape_square_light'],
    lfo_trigger_sync: ['#lfo_trigger_sync_light']
  };

  const currentGuessParams = function() {
    return {
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
    };
  };

  const updateHintButton = function() {
    const gameIsActive = gameHasStarted && !gameFinished;
    const hintsRemaining = MAX_HINTS - hintsUsed;
    const $hintButton = $('#request-hint');

    $hintButton.toggleClass('hidden', !gameIsActive);
    $hintButton.prop(
      'disabled',
      !gameIsActive || hintRequestInFlight || hintsRemaining <= 0
    );

    const hintLabel = hintsRemaining > 0 ?
      `Request a hint (${hintsRemaining} left)` :
      'No hints remaining';

    $hintButton.attr('aria-label', hintLabel);
    $hintButton.attr('title', hintLabel);
  };

  const writeGameDataCookie = function(payload) {
    const encodedValue = encodeURIComponent(JSON.stringify(payload));
    VS.setCookie('gameData', encodedValue, 1, '/');
    gameData = payload;
  };

  const hintTargetsFor = function(paramName) {
    return HINT_TARGET_SELECTORS[paramName] || [];
  };

  const setHintHighlightVisible = function(visible) {
    hintBlinkVisible = visible;
    blinkingHintParams.forEach(function(paramName) {
      hintTargetsFor(paramName).forEach(function(selector) {
        $(selector).toggleClass('hint-highlight', visible);
      });
    });
  };

  const stopBlinkingHintParam = function(paramName) {
    if (!blinkingHintParams.has(paramName)) { return; }

    blinkingHintParams.delete(paramName);
    hintTargetsFor(paramName).forEach(function(selector) {
      $(selector).removeClass('hint-highlight');
    });

    if (blinkingHintParams.size === 0) {
      clearInterval(hintBlinkIntervalId);
      clearTimeout(hintBlinkTimeoutId);
      hintBlinkIntervalId = null;
      hintBlinkTimeoutId = null;
      hintBlinkVisible = false;
    }
  };

  const stopAllHintBlinking = function() {
    Array.from(blinkingHintParams).forEach(stopBlinkingHintParam);
  };

  const startHintBlinking = function(hintParams) {
    stopAllHintBlinking();

    blinkingHintParams = new Set((hintParams || []).filter(function(paramName) {
      return hintTargetsFor(paramName).length > 0;
    }));

    if (blinkingHintParams.size === 0 || gameFinished || !gameHasStarted) { return; }

    setHintHighlightVisible(true);
    hintBlinkIntervalId = setInterval(function() {
      setHintHighlightVisible(!hintBlinkVisible);
    }, HINT_BLINK_INTERVAL_MS);
    hintBlinkTimeoutId = setTimeout(function() {
      stopAllHintBlinking();
    }, HINT_BLINK_DURATION_MS);
  };

  const persistGameProgress = function() {
    if (!gameData || gameData.mysteryPatchId !== mysteryPatchId) { return; }

    writeGameDataCookie({
      mysteryPatchId: mysteryPatchId,
      gameStart: gameData.gameStart,
      gameDeadline: gameData.gameDeadline,
      hintsUsed: hintsUsed,
      hintedParams: Array.from(hintedParams)
    });
  };

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

  const sendAnalyticsEvent = function(...args) {
    if (typeof ga !== 'function') { return; }

    ga('send', 'event', ...args);
  };

  const revealElement = function(selector, animate = false) {
    if (!animate) {
      $(selector).show();
      return;
    }

    $(selector).fadeIn('slow');
  };

  const showNotStartedState = function() {
    clearInterval(intervalId);
    $('#timer').hide().text('');
    $('#submit-solution').hide();
    $('#show-results').hide();
    $('#request-hint').addClass('hidden');
    $('#post-game-message').hide();
    $('#audible-engine-mystery').addClass('start-game-callout');
    stopAllHintBlinking();
    updateHintButton();
  };

  let keyboardHintTimeout = null;

  const showStartedState = function() {
    $('#timer-description').text('Remaining time:');
    $('#timer').show();
    $('#submit-solution').show();
    $('#show-results').hide();
    $('#post-game-message').hide();
    $('#audible-engine-mystery').removeClass('start-game-callout');
    updateHintButton();

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
    $('#timer-description').hide();
    $('#timer').show().text('Time\'s up!');
    $('#submit-solution').hide();
    $('#request-hint').addClass('hidden');
    $('#audible-engine-mystery').removeClass('start-game-callout');
    $('#need-practice').show();
    stopAllHintBlinking();
    updateHintButton();
    updateShowResultsButton();
    updatePostGameMessage();
  };

  const triggerSubmitSolution = function() {
    $('#submit-confirmation-modal').modal('hide');
    submitSolution();
  };

  const submitSolution = function() {
    if (submissionInFlight) { return; }

    submissionInFlight = true;
    gameFinished = true;
    showFinishedState();
    const timeLeft = Math.max(remainingTimeSeconds(), 0);

    const solutionParams = {
      id: mysteryPatchId,
      digest: digest,
      patch: currentGuessParams()
    };

    $.post('/mystery_patch', solutionParams).done(function(response) {
      $('#results-button').click();

      resultsData = response.results;
      sendAnalyticsEvent(
        'Mystery Patch',
        'results',
        `total_score_${resultsData.total_score}_time_left_${timeLeft}`,
        Math.round(resultsData.total_score)
      );
      setResultsCookie();
      printResultsInfo(true);
    });
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

    writeGameDataCookie({
      mysteryPatchId: mysteryPatchId,
      gameStart: gameStart,
      gameDeadline: gameDeadline,
      hintsUsed: 0,
      hintedParams: []
    });
  };

  const setResultsCookie = function() {
    const cookiePayload = {
      mysteryPatchId: mysteryPatchId,
      timeSubmitted: rightNow(),
      results: resultsData,
      hintsUsed: hintsUsed,
      hintedParams: Array.from(hintedParams)
    };
    const encodedValue = encodeURIComponent(JSON.stringify(cookiePayload));
    VS.setCookie('resultsData', encodedValue, 1, '/');
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

        // Emphasize countdown clock
        if (secondsLeft == 60 || secondsLeft == 30 || secondsLeft <= 15) {

          $('#timer')
            .css({
              'background-color': 'red',
              'transition': 'background-color 0s'
            });

          setTimeout(function() {
            $('#timer')
              .css({
                'background-color': 'white',
                'transition': 'background-color 1s'
              });
          }, 10);
        }

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
    hintsUsed = 0;
    hintedParams = new Set();
    stopAllHintBlinking();
    sendAnalyticsEvent('Mystery Patch', 'start');
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
        resultsData: cookieResultsData.results,
        hintsUsed: cookieResultsData.hintsUsed || 0,
        hintedParams: cookieResultsData.hintedParams || []
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
          resultsData: null,
          hintsUsed: cookieGameData.hintsUsed || 0,
          hintedParams: cookieGameData.hintedParams || []
        };
      }

      // Continue game
      return {
        status: 'active',
        gameData: cookieGameData,
        resultsData: null,
        hintsUsed: cookieGameData.hintsUsed || 0,
        hintedParams: cookieGameData.hintedParams || []
      };
    }

    // New game
    return {
      status: 'not_started',
      gameData: null,
      resultsData: null,
      hintsUsed: 0,
      hintedParams: []
    };
  };

  const applySessionState = function(sessionState) {
    gameData = sessionState.gameData || undefined;
    resultsData = sessionState.resultsData || undefined;
    hintsUsed = sessionState.hintsUsed || 0;
    hintedParams = new Set(sessionState.hintedParams || []);
    stopAllHintBlinking();

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
    hintsUsed = 0;
    hintedParams = new Set();
    showNotStartedState();
    $('#pre-game-button').click();
  };

  const getMysteryPatch = function() {
    $.get('/mystery_patch.json').done(function(encryptedParams) {
      // Rotate back characters by todays UTC day of month
      const dayOfMonth = new Date().getUTCDate();
      mysteryPatchId = encryptedParams.id;
      mysteryPatchNumber = encryptedParams.number;
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

      $('h1').text(`Mystery Patch #${mysteryPatchNumber}`);

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

  $('#request-hint').on('click tap', function(event) {
    event.preventDefault();
    if (!gameHasStarted || gameFinished || hintRequestInFlight || hintsUsed >= MAX_HINTS) {
      return;
    }

    hintRequestInFlight = true;
    updateHintButton();

    $.post('/mystery_patch_hint', {
      mysteryPatchId: mysteryPatchId,
      patch: currentGuessParams()
    }).done(function(response) {
      hintsUsed = response.hints_used;
      $(document).trigger('mysteryPatchHintReceived', [response.hint_params || []]);
    }).fail(function(xhr) {
      if (xhr.status === 429) {
        hintsUsed = MAX_HINTS;
        persistGameProgress();
      }
    }).always(function() {
      hintRequestInFlight = false;
      updateHintButton();
    });
  });

  $(document).on('mysteryPatchHintReceived', function(_event, hintParams) {
    (hintParams || []).forEach(function(paramName) {
      hintedParams.add(paramName);
    });
    startHintBlinking(hintParams);
    persistGameProgress();
  });

  Object.entries(HINT_TARGET_SELECTORS).forEach(function([paramName, selectors]) {
    selectors.forEach(function(selector) {
      $(document).on('mousedown touchstart pointerdown', selector, function() {
        stopBlinkingHintParam(paramName);
      });
    });
  });

  const printResultsInfo = function(animate) {
    const animateResults = animate && !inTestEnvironment;
    let animateInterval = animateResults ? 500 : 5;
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
        `Mystery Patch #${mysteryPatchNumber}: I guessed today's mystery synth patch with ${resultsData.total_score}% `,
        `accuracy.\n${emojiSummary}\n\nvolcashare.com/mystery_patch`,
        `\n\n#VSmysterypatch`
      ].join('')
      );
      revealElement('#share-results', animateResults);
      revealElement('#keep-playing', animateResults);
      updateShowResultsButton();
    };

    const renderEntry = function(entry) {
      let key = snakeToTitleize(entry[0]);
      let value = entry[1];

      let correctVal = value[0];
      let printableVal = value[1];
      const wasHinted = hintedParams.has(entry[0].toString());

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

    let timer = setInterval(function () {

      // When entries are all done being listed
      if (i >= entries.length) {
        renderSummary();
        clearInterval(timer);
        return;
      }

      renderEntry(entries[i]);

      i += 1;
    }, animateInterval);
  };

  $('#submit-solution').on('click tap', function(event) {
    event.preventDefault();
    if (gameFinished) { return; }

    $('#submit-confirmation-button').trigger('click');
  });

  $('#confirm-submit-solution').on('click tap', function(event) {
    event.preventDefault();
    $('#submit-confirmation-modal').modal('hide');
    submitSolution();
  });

  showNotStartedState();
  getMysteryPatch();
  syncAudibleEngineSwitch('primary');
});
