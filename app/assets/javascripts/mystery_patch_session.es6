VS.MysteryPatchSession = function(options = {}) {
  const storageKey = options.storageKey || 'mysteryPatchGameData';
  const gameDurationSeconds = options.gameDurationSeconds || 180;

  const rightNow = function() {
    return Math.floor(Date.now() / 1000);
  };

  const parseCookieJson = function(key) {
    const encodedValue = getCookieValue(key);
    if (encodedValue === null) { return null; }

    try {
      return JSON.parse(decodeURIComponent(encodedValue));
    } catch (_) {
      return null;
    }
  };

  const writeGameData = function(payload) {
    const encodedValue = encodeURIComponent(JSON.stringify(payload));

    try {
      window.localStorage.setItem(storageKey, JSON.stringify(payload));
    } catch (_) {
    }

    VS.setCookie('gameData', encodedValue, 1, '/');
    return payload;
  };

  const readGameData = function() {
    try {
      const storedGameData = window.localStorage.getItem(storageKey);
      if (storedGameData) {
        return JSON.parse(storedGameData);
      }
    } catch (_) {
    }

    return parseCookieJson('gameData');
  };

  const normalizeGameData = function(rawGameData, mysteryPatchId) {
    if (
      rawGameData === null ||
      rawGameData === undefined ||
      rawGameData.mysteryPatchId !== mysteryPatchId
    ) {
      return null;
    }

    if (rawGameData.remainingSeconds !== undefined) {
      const status = rawGameData.status || 'paused';
      return {
        mysteryPatchId: rawGameData.mysteryPatchId,
        status: status,
        remainingSeconds: Math.max(Math.floor(rawGameData.remainingSeconds), 0),
        lastResumedAt: rawGameData.lastResumedAt || null,
        pausedAt: rawGameData.pausedAt || null,
        hintsUsed: rawGameData.hintsUsed || 0,
        hintedParams: rawGameData.hintedParams || []
      };
    }

    if (rawGameData.gameDeadline !== undefined) {
      return {
        mysteryPatchId: rawGameData.mysteryPatchId,
        status: 'running',
        remainingSeconds: Math.max(rawGameData.gameDeadline - rightNow(), 0),
        lastResumedAt: rightNow(),
        pausedAt: null,
        hintsUsed: rawGameData.hintsUsed || 0,
        hintedParams: rawGameData.hintedParams || []
      };
    }

    return null;
  };

  const syncGameData = function(gameData, attributes = {}, options = {}) {
    if (!gameData || gameData.mysteryPatchId !== options.mysteryPatchId) {
      return gameData;
    }

    return writeGameData({
      ...gameData,
      ...attributes,
      hintsUsed: options.hintsUsed || 0,
      hintedParams: options.hintedParams || []
    });
  };

  this.startGameData = function(options = {}) {
    const resumedAt = rightNow();

    return writeGameData({
      mysteryPatchId: options.mysteryPatchId,
      status: 'running',
      remainingSeconds: gameDurationSeconds,
      lastResumedAt: resumedAt,
      pausedAt: null,
      hintsUsed: options.hintsUsed || 0,
      hintedParams: options.hintedParams || []
    });
  };

  this.setResultsCookie = function(options = {}) {
    const cookiePayload = {
      mysteryPatchId: options.mysteryPatchId,
      timeSubmitted: rightNow(),
      results: options.resultsData,
      hintsUsed: options.hintsUsed || 0,
      hintedParams: options.hintedParams || []
    };
    const encodedValue = encodeURIComponent(JSON.stringify(cookiePayload));

    VS.setCookie('resultsData', encodedValue, 1, '/');
  };

  this.remainingTimeSeconds = function(gameData, mysteryPatchId) {
    if (gameData !== undefined && gameData.mysteryPatchId === mysteryPatchId) {
      if (gameData.status === 'running' && gameData.lastResumedAt !== null) {
        return Math.max(gameData.remainingSeconds - (rightNow() - gameData.lastResumedAt), 0);
      }

      return Math.max(gameData.remainingSeconds || 0, 0);
    }

    return gameDurationSeconds;
  };

  this.syncGameData = function(gameData, attributes = {}, options = {}) {
    return syncGameData(gameData, attributes, options);
  };

  this.settleRunningGameData = function(options = {}) {
    const gameData = options.gameData;
    if (!gameData || gameData.mysteryPatchId !== options.mysteryPatchId || gameData.status !== 'running') {
      return gameData;
    }

    const nowValue = options.nowValue || rightNow();
    const elapsedSeconds = Math.max(nowValue - (gameData.lastResumedAt || nowValue), 0);
    const updatedRemainingSeconds = Math.max((gameData.remainingSeconds || 0) - elapsedSeconds, 0);

    return syncGameData(
      gameData,
      {
        remainingSeconds: updatedRemainingSeconds,
        lastResumedAt: nowValue
      },
      options
    );
  };

  this.resumeGameData = function(options = {}) {
    return syncGameData(
      options.gameData,
      {
        status: 'running',
        lastResumedAt: rightNow(),
        pausedAt: null
      },
      options
    );
  };

  this.pauseGameData = function(options = {}) {
    const pausedAt = rightNow();
    const settledGameData = this.settleRunningGameData({
      ...options,
      nowValue: pausedAt
    });

    return syncGameData(
      settledGameData,
      {
        status: 'paused',
        lastResumedAt: null,
        pausedAt: pausedAt
      },
      options
    );
  }.bind(this);

  this.resolveSessionState = function(options = {}) {
    const mysteryPatchId = options.mysteryPatchId;
    const now = rightNow();
    const cookieResultsData = parseCookieJson('resultsData');
    const storedGameData = normalizeGameData(readGameData(), mysteryPatchId);

    if (
      cookieResultsData !== null &&
      cookieResultsData.mysteryPatchId === mysteryPatchId &&
      now >= cookieResultsData.timeSubmitted
    ) {
      return {
        status: 'finished',
        gameData: storedGameData,
        resultsData: cookieResultsData.results,
        hintsUsed: cookieResultsData.hintsUsed || 0,
        hintedParams: cookieResultsData.hintedParams || []
      };
    }

    if (
      storedGameData !== null &&
      storedGameData.mysteryPatchId === mysteryPatchId
    ) {
      if (storedGameData.status === 'running' && storedGameData.lastResumedAt !== null) {
        const settledRemainingSeconds =
          storedGameData.remainingSeconds - (now - storedGameData.lastResumedAt);

        if (settledRemainingSeconds <= 0) {
          return {
            status: 'expired_unsubmitted',
            gameData: {
              ...storedGameData,
              remainingSeconds: 0
            },
            resultsData: null,
            hintsUsed: storedGameData.hintsUsed || 0,
            hintedParams: storedGameData.hintedParams || []
          };
        }
      }

      if (storedGameData.remainingSeconds <= 0) {
        return {
          status: 'expired_unsubmitted',
          gameData: {
            ...storedGameData,
            remainingSeconds: 0
          },
          resultsData: null,
          hintsUsed: storedGameData.hintsUsed || 0,
          hintedParams: storedGameData.hintedParams || []
        };
      }

      return {
        status: storedGameData.status === 'paused' ? 'paused' : 'active',
        gameData: storedGameData,
        resultsData: null,
        hintsUsed: storedGameData.hintsUsed || 0,
        hintedParams: storedGameData.hintedParams || []
      };
    }

    return {
      status: 'not_started',
      gameData: null,
      resultsData: null,
      hintsUsed: 0,
      hintedParams: []
    };
  };
};
