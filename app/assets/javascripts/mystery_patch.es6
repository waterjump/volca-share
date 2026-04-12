$(function() {
  if (window.location.pathname !== '/mystery_patch') { return; }

  const { emulatorParams, mysteryPatchParams } = VS;
  const mysteryParams = mysteryPatchParams;
  const patch = emulatorParams;

  let mysteryPatchEngine;
  let gameHasStarted = false;
  let gameFinished = false;
  let gameIsPaused = false;
  let mysteryPatchId;
  let mysteryPatchNumber;
  let digest;
  let gameData;
  let intervalId;
  let submissionInFlight = false;
  let keyboardHintTimeout = null;
  let shouldScheduleKeyboardHint = false;

  const inTestEnvironment = $('body').attr('data-test-env') === 'true';
  const GAME_DURATION_SECONDS = 180;
  const MAX_HINTS = 2;
  const HINT_BLINK_INTERVAL_MS = 500;
  const HINT_BLINK_DURATION_MS = 5000;
  const PRE_GAME_MODAL_HIDDEN_STORAGE_KEY = 'mysteryPatchPreGameModalHidden';
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

  const session = new VS.MysteryPatchSession({
    storageKey: 'mysteryPatchGameData',
    gameDurationSeconds: GAME_DURATION_SECONDS
  });

  const preGameModalHidden = function() {
    try {
      return window.localStorage.getItem(PRE_GAME_MODAL_HIDDEN_STORAGE_KEY) === 'true';
    } catch (_) {
      return false;
    }
  };

  const setPreGameModalHidden = function(hidden) {
    try {
      window.localStorage.setItem(PRE_GAME_MODAL_HIDDEN_STORAGE_KEY, hidden ? 'true' : 'false');
    } catch (_) {
    }
  };

  const showPreGameModal = function() {
    if (preGameModalHidden()) { return; }

    $('#pre-game-button').click();
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

  const hints = new VS.MysteryPatchHints({
    maxHints: MAX_HINTS,
    blinkIntervalMs: HINT_BLINK_INTERVAL_MS,
    blinkDurationMs: HINT_BLINK_DURATION_MS,
    hintTargetSelectors: HINT_TARGET_SELECTORS,
    getGameState: function() {
      return {
        gameHasStarted: gameHasStarted,
        gameFinished: gameFinished,
        gameIsPaused: gameIsPaused
      };
    },
    getMysteryPatchId: function() {
      return mysteryPatchId;
    },
    currentGuessParams: currentGuessParams,
    onProgressChange: function(state) {
      if (!gameData || gameData.mysteryPatchId !== mysteryPatchId) { return; }

      gameData = session.syncGameData(gameData, {}, {
        mysteryPatchId: mysteryPatchId,
        hintsUsed: state.hintsUsed,
        hintedParams: state.hintedParams
      });
    }
  });

  const results = new VS.MysteryPatchResults({
    inTestEnvironment: inTestEnvironment,
    getMysteryPatchNumber: function() {
      return mysteryPatchNumber;
    },
    getHintedParams: function() {
      return hints.getHintedParams();
    },
    getGameFinished: function() {
      return gameFinished;
    }
  });

  const updatePauseButton = function() {
    const $pauseButton = $('#toggle-pause');
    const shouldShow = gameHasStarted && !gameFinished;

    $pauseButton.css('display', shouldShow ? 'inline-block' : 'none');
    if (!shouldShow) { return; }

    $pauseButton.text(gameIsPaused ? 'Resume' : 'Pause');
    $pauseButton.attr('aria-label', gameIsPaused ? 'Resume timer' : 'Pause timer');
  };

  const updatePausedInteractionLock = function() {
    const paused = gameHasStarted && !gameFinished && gameIsPaused;

    $('#mystery-game-interface-lock').toggleClass('hidden', !paused);
    $('#mystery-game-controls-lock').toggleClass('hidden', !paused);

    $('#audible-engine-primary, #audible-engine-mystery, #submit-solution')
      .prop('disabled', paused)
      .attr('aria-disabled', paused.toString());

    if (VS.keysEmulatorBridge && typeof VS.keysEmulatorBridge.setInteractionEnabled === 'function') {
      VS.keysEmulatorBridge.setInteractionEnabled(!paused);
    }
  };

  const updatePostGameMessage = function() {
    $('#post-game-message').toggle(gameFinished);
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

  const sequence = [];
  for (let index = 0; index < 16; index++) {
    sequence.push({
      index: index,
      note: 60,
      slide: false,
      activeStep: true
    });
  }

  const unrotate = function(rotatedString, rotationAmount) {
    return Array.from(rotatedString, function(ch) {
      const code = ch.charCodeAt(0);

      if (code < 32 || code > 126) { return ch; }

      const unrot = ((code - 32 - rotationAmount) % 95 + 95) % 95;
      return String.fromCharCode(unrot + 32);
    }).join("");
  };

  const sendAnalyticsEvent = function() {
    if (typeof ga !== 'function') { return; }

    ga('send', 'event', ...arguments);
  };

  const renderTimer = function(secondsLeft) {
    const minutes = Math.floor(secondsLeft / 60);
    const seconds = secondsLeft % 60;
    $('#timer').text(`${minutes.toString()}:${seconds.toString().padStart(2, '0')}`);
  };

  const remainingTimeSeconds = function() {
    return session.remainingTimeSeconds(gameData, mysteryPatchId);
  };

  const settleRunningGameData = function() {
    gameData = session.settleRunningGameData({
      gameData: gameData,
      mysteryPatchId: mysteryPatchId,
      hintsUsed: hints.getHintsUsed(),
      hintedParams: hints.getHintedParams()
    });
  };

  const showNotStartedState = function() {
    clearInterval(intervalId);
    clearTimeout(keyboardHintTimeout);
    $('#timer').hide().text('');
    $('#timer-description').hide();
    $('#submit-solution').hide();
    $('#post-game-message').hide();
    $('#audible-engine-mystery').addClass('start-game-callout');
    $('#need-practice').hide();
    hints.stopAllBlinking();
    hints.updateButton();
    results.updateShowResultsButton();
    updatePauseButton();
    updatePausedInteractionLock();
  };

  const showStartedState = function() {
    clearTimeout(keyboardHintTimeout);
    $('#timer-description').show().text('Remaining time:');
    $('#timer').show();
    $('#submit-solution').show();
    $('#post-game-message').hide();
    $('#audible-engine-mystery').removeClass('start-game-callout');
    $('#need-practice').hide();
    hints.updateButton();
    results.updateShowResultsButton();
    updatePauseButton();
    updatePausedInteractionLock();

    if (!shouldScheduleKeyboardHint) { return; }

    shouldScheduleKeyboardHint = false;
    keyboardHintTimeout = setTimeout(function() {
      $('#keyboard-highlight').addClass('start-keyboard-callout');
      const $usageBody = VS.findAccordionHeaderBySectionName('Usage').siblings('.accordion-body');
      $usageBody.addClass('start-keyboard-callout');
      VS.expandAccordionSection('Usage');
    }, 2000);
  };

  const showPausedState = function() {
    clearInterval(intervalId);
    clearTimeout(keyboardHintTimeout);
    $('#timer-description').show().text('Remaining time (paused):');
    $('#timer').show();
    $('#submit-solution').show();
    $('#post-game-message').hide();
    $('#audible-engine-mystery').removeClass('start-game-callout');
    hints.stopAllBlinking();
    hints.updateButton();
    results.updateShowResultsButton();
    updatePauseButton();
    updatePausedInteractionLock();
  };

  const showFinishedState = function() {
    clearInterval(intervalId);
    clearTimeout(keyboardHintTimeout);
    $('#timer-description').hide();
    $('#timer').show().text('Time\'s up!');
    $('#submit-solution').hide();
    $('#audible-engine-mystery').removeClass('start-game-callout');
    $('#need-practice').show();
    hints.stopAllBlinking();
    hints.updateButton();
    results.updateShowResultsButton();
    updatePostGameMessage();
    updatePauseButton();
    updatePausedInteractionLock();
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

    $.post('/mystery_patch', {
      id: mysteryPatchId,
      digest: digest,
      patch: currentGuessParams()
    }).done(function(response) {
      results.setResultsData(response.results);
      sendAnalyticsEvent(
        'Mystery Patch',
        'results',
        `total_score_${response.results.total_score}_time_left_${timeLeft}`,
        Math.round(response.results.total_score)
      );
      session.setResultsCookie({
        mysteryPatchId: mysteryPatchId,
        resultsData: response.results,
        hintsUsed: hints.getHintsUsed(),
        hintedParams: hints.getHintedParams()
      });
      results.showResults(true);
    });
  };

  $(document).on('hideKeyboardHighlight', function() {
    if (keyboardHintTimeout) {
      clearTimeout(keyboardHintTimeout);
    }
    shouldScheduleKeyboardHint = false;
    $('#keyboard-highlight').removeClass('start-keyboard-callout');
    const $usageBody = VS.findAccordionHeaderBySectionName('Usage').siblings('.accordion-body');
    $usageBody.removeClass('start-keyboard-callout');
  });

  const startTimer = function() {
    let secondsLeft = remainingTimeSeconds();
    clearInterval(intervalId);

    if (secondsLeft <= 0) {
      gameFinished = true;
      showFinishedState();
      return;
    }

    renderTimer(secondsLeft);

    intervalId = setInterval(function() {
      if (gameIsPaused) {
        clearInterval(intervalId);
        return;
      }

      secondsLeft--;

      if (secondsLeft >= 0) {
        if (secondsLeft === 60 || secondsLeft === 30 || secondsLeft <= 15) {
          $('#timer').css({
            'background-color': 'red',
            'transition': 'background-color 0s'
          });

          setTimeout(function() {
            $('#timer').css({
              'background-color': 'white',
              'transition': 'background-color 1s'
            });
          }, 10);
        }

        renderTimer(secondsLeft);
        return;
      }

      clearInterval(intervalId);
      if (!gameFinished) {
        triggerSubmitSolution();
        return;
      }

      showFinishedState();
    }, 1000);
  };

  const startGame = function() {
    if (gameHasStarted || gameFinished) { return; }

    gameHasStarted = true;
    gameIsPaused = false;
    shouldScheduleKeyboardHint = true;
    hints.setState({ hintsUsed: 0, hintedParams: [] });
    sendAnalyticsEvent('Mystery Patch', 'start');
    showStartedState();
    gameData = session.startGameData({
      mysteryPatchId: mysteryPatchId,
      hintsUsed: hints.getHintsUsed(),
      hintedParams: hints.getHintedParams()
    });
    startTimer();
  };

  const resumeGame = function() {
    if (!gameHasStarted || gameFinished) { return; }

    gameData = session.resumeGameData({
      gameData: gameData,
      mysteryPatchId: mysteryPatchId,
      hintsUsed: hints.getHintsUsed(),
      hintedParams: hints.getHintedParams()
    });

    gameIsPaused = false;
    showStartedState();
    startTimer();
  };

  const pauseGame = function() {
    if (!gameHasStarted || gameFinished || gameIsPaused) { return; }

    gameData = session.pauseGameData({
      gameData: gameData,
      mysteryPatchId: mysteryPatchId,
      hintsUsed: hints.getHintsUsed(),
      hintedParams: hints.getHintedParams()
    });

    if (remainingTimeSeconds() <= 0) {
      gameFinished = true;
      showFinishedState();
      triggerSubmitSolution();
      return;
    }

    gameIsPaused = true;
    if (VS.keysEmulatorBridge && typeof VS.keysEmulatorBridge.stopAllNotes === 'function') {
      VS.keysEmulatorBridge.stopAllNotes();
    }
    showPausedState();
    renderTimer(remainingTimeSeconds());
  };

  const applySessionState = function(sessionState) {
    gameData = sessionState.gameData || undefined;
    results.setResultsData(sessionState.resultsData || undefined);
    hints.setState({
      hintsUsed: sessionState.hintsUsed || 0,
      hintedParams: sessionState.hintedParams || []
    });
    gameIsPaused = sessionState.status === 'paused';

    if (sessionState.status === 'finished') {
      gameHasStarted = true;
      gameFinished = true;
      showFinishedState();
      results.showResults(false);
      return;
    }

    if (sessionState.status === 'expired_unsubmitted') {
      gameHasStarted = true;
      gameFinished = true;
      gameIsPaused = false;
      showFinishedState();
      triggerSubmitSolution();
      return;
    }

    if (sessionState.status === 'active') {
      gameHasStarted = true;
      gameFinished = false;
      gameIsPaused = false;
      settleRunningGameData();
      resumeGame();
      return;
    }

    if (sessionState.status === 'paused') {
      gameHasStarted = true;
      gameFinished = false;
      gameIsPaused = true;
      showPausedState();
      renderTimer(remainingTimeSeconds());
      return;
    }

    gameHasStarted = false;
    gameFinished = false;
    gameIsPaused = false;
    shouldScheduleKeyboardHint = false;
    results.setResultsData(undefined);
    hints.setState({ hintsUsed: 0, hintedParams: [] });
    showNotStartedState();
    showPreGameModal();
  };

  const getMysteryPatch = function() {
    $.get('/mystery_patch.json').done(function(encryptedParams) {
      const dayOfMonth = new Date().getUTCDate();
      mysteryPatchId = encryptedParams.id;
      mysteryPatchNumber = encryptedParams.number;
      digest = encryptedParams.digest;
      const decryptedParams = unrotate(encryptedParams.patch, dayOfMonth);

      const base64Salt = btoa('salt489');
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

      applySessionState(session.resolveSessionState({
        mysteryPatchId: mysteryPatchId
      }));
    });
  };

  $('#audible-engine-primary').on('click tap', function() {
    if (gameIsPaused) { return; }
    if (VS.keysEmulatorBridge) {
      VS.keysEmulatorBridge.setActiveAudibleEngine('primary');
    }
    syncAudibleEngineSwitch('primary');
    this.blur();
  });

  $('#audible-engine-mystery').on('click tap', function() {
    if (gameIsPaused) { return; }
    if (VS.keysEmulatorBridge) {
      VS.keysEmulatorBridge.setActiveAudibleEngine('mystery');
    }
    syncAudibleEngineSwitch('primary');
    if (!gameHasStarted) { startGame(); }
    this.blur();
  });

  $('#toggle-pause').on('click tap', function() {
    if (gameIsPaused) {
      resumeGame();
    } else {
      pauseGame();
    }
    this.blur();
  });

  document.addEventListener('visibilitychange', function() {
    if (document.visibilityState === 'hidden') {
      pauseGame();
    }
  });

  window.addEventListener('pagehide', function() {
    pauseGame();
  });

  const isPausedGameKey = function(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) { return false; }

    const emulatorConstants = VS.emulatorConstants;
    const keyCode = event.keyCode;
    const musicalTypingKeyCodes = emulatorConstants && emulatorConstants.keyCodes || [];

    return (
      musicalTypingKeyCodes.includes(keyCode) ||
      keyCode === (emulatorConstants && emulatorConstants.zKeyCode) ||
      keyCode === (emulatorConstants && emulatorConstants.xKeyCode) ||
      keyCode === 37 ||
      keyCode === 39
    );
  };

  window.addEventListener('keydown', function(event) {
    if (!gameIsPaused || !isPausedGameKey(event)) { return; }

    event.preventDefault();
    event.stopImmediatePropagation();
  }, true);

  window.addEventListener('keyup', function(event) {
    if (!gameIsPaused || !isPausedGameKey(event)) { return; }

    event.preventDefault();
    event.stopImmediatePropagation();
  }, true);

  $(document).on('keydown', function(event) {
    const targetTag = (event.target && event.target.tagName || '').toLowerCase();
    if (['input', 'textarea', 'select'].includes(targetTag)) { return; }
    if (gameIsPaused) { return; }

    if (event.keyCode === 37) {
      $('#audible-engine-primary').trigger('click');
    } else if (event.keyCode === 39) {
      $('#audible-engine-mystery').trigger('click');
    }
  });

  $('#submit-solution').on('click tap', function(event) {
    event.preventDefault();
    if (gameFinished || gameIsPaused) { return; }

    $('#submit-confirmation-button').trigger('click');
  });

  $('#confirm-submit-solution').on('click tap', function(event) {
    event.preventDefault();
    if (gameIsPaused) { return; }
    $('#submit-confirmation-modal').modal('hide');
    submitSolution();
  });

  $('#pre-game-modal').on('show.bs.modal', function() {
    $('#hide-pre-game-modal').prop('checked', preGameModalHidden());
  });

  $('#hide-pre-game-modal').on('change', function() {
    setPreGameModalHidden($(this).prop('checked'));
  });

  hints.bindEvents();
  results.bindEvents();
  showNotStartedState();
  getMysteryPatch();
  syncAudibleEngineSwitch('primary');
});
