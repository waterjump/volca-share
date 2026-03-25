VS.MysteryPatchHints = function(options = {}) {
  const maxHints = options.maxHints || 2;
  const blinkIntervalMs = options.blinkIntervalMs || 500;
  const blinkDurationMs = options.blinkDurationMs || 5000;
  const getGameState = options.getGameState || function() { return {}; };
  const getMysteryPatchId = options.getMysteryPatchId || function() { return null; };
  const currentGuessParams = options.currentGuessParams || function() { return {}; };
  const onProgressChange = options.onProgressChange || function() {};
  const hintTargetSelectors = options.hintTargetSelectors || {};

  let hintRequestInFlight = false;
  let hintsUsed = 0;
  let hintedParams = new Set();
  let blinkingHintParams = new Set();
  let hintBlinkVisible = false;
  let hintBlinkIntervalId = null;
  let hintBlinkTimeoutId = null;

  const hintTargetsFor = function(paramName) {
    return hintTargetSelectors[paramName] || [];
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

  const stopAllBlinking = function() {
    Array.from(blinkingHintParams).forEach(stopBlinkingHintParam);
  };

  const startBlinking = function(hintParams) {
    stopAllBlinking();

    blinkingHintParams = new Set((hintParams || []).filter(function(paramName) {
      return hintTargetsFor(paramName).length > 0;
    }));

    const gameState = getGameState();
    if (blinkingHintParams.size === 0 || gameState.gameFinished || !gameState.gameHasStarted) {
      return;
    }

    setHintHighlightVisible(true);
    hintBlinkIntervalId = setInterval(function() {
      setHintHighlightVisible(!hintBlinkVisible);
    }, blinkIntervalMs);
    hintBlinkTimeoutId = setTimeout(function() {
      stopAllBlinking();
    }, blinkDurationMs);
  };

  const persistProgress = function() {
    onProgressChange({
      hintsUsed: hintsUsed,
      hintedParams: Array.from(hintedParams)
    });
  };

  this.updateButton = function() {
    const gameState = getGameState();
    const gameIsActive = gameState.gameHasStarted && !gameState.gameFinished && !gameState.gameIsPaused;
    const hintsRemaining = maxHints - hintsUsed;
    const $hintButton = $('#request-hint');
    const hintDisabled =
      !gameIsActive || hintRequestInFlight || hintsRemaining <= 0;

    $hintButton.toggleClass('hidden', !gameIsActive);
    $hintButton.toggleClass('disabled', hintDisabled);
    $hintButton.attr('aria-disabled', hintDisabled.toString());

    const hintLabel = hintsRemaining > 0 ?
      `Request a hint (${hintsRemaining} left)` :
      'No hints remaining';

    $hintButton.attr('aria-label', hintLabel);
    $hintButton.attr('title', hintLabel);
  };

  const applyReceivedHint = function(hintParams) {
    (hintParams || []).forEach(function(paramName) {
      hintedParams.add(paramName);
    });
    startBlinking(hintParams);
    persistProgress();
  };

  this.bindEvents = function() {
    $('#request-hint').on('click tap', function(event) {
      event.preventDefault();

      const gameState = getGameState();
      if (
        !gameState.gameHasStarted ||
        gameState.gameFinished ||
        gameState.gameIsPaused ||
        hintRequestInFlight ||
        hintsUsed >= maxHints
      ) {
        return;
      }

      hintRequestInFlight = true;
      this.updateButton();

      $.post('/mystery_patch_hint', {
        mysteryPatchId: getMysteryPatchId(),
        patch: currentGuessParams()
      }).done(function(response) {
        hintsUsed = response.hints_used;
        applyReceivedHint(response.hint_params || []);
      }).fail(function(xhr) {
        if (xhr.status === 429) {
          hintsUsed = maxHints;
          persistProgress();
        }
      }).always(function() {
        hintRequestInFlight = false;
        this.updateButton();
      }.bind(this));
    }.bind(this));

    Object.entries(hintTargetSelectors).forEach(function([paramName, selectors]) {
      selectors.forEach(function(selector) {
        $(document).on('mousedown touchstart pointerdown', selector, function() {
          stopBlinkingHintParam(paramName);
        });
      });
    });
  }.bind(this);

  this.setState = function(state = {}) {
    hintsUsed = state.hintsUsed || 0;
    hintedParams = new Set(state.hintedParams || []);
    stopAllBlinking();
    this.updateButton();
  }.bind(this);

  this.stopAllBlinking = function() {
    stopAllBlinking();
  };

  this.getHintsUsed = function() {
    return hintsUsed;
  };

  this.getHintedParams = function() {
    return Array.from(hintedParams);
  };
};
