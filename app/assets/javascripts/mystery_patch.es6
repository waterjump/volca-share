$(function() {
  if (window.location.pathname !== '/mystery_patch') { return; }

  const { sequences, emulatorParams, mysteryPatchParams } = VS;
  const mysteryParams = mysteryPatchParams;
  const patch = emulatorParams;

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

  let mysteryPatchEngine;
  let gameHasStarted = false;
  let gameFinished = false;
  let mysteryPatchId;
  let digest;
  let gameData;
  let resultsData;
  let intervalId;
  let timeLeft = 120; // 2 minutes

  const startGame = function() {
    startTimer();
    $('#submit-solution').fadeIn('slow');
    gameHasStarted = true;

    setGameStartedCookie();
  };

  const setGameStartedCookie = function() {
    if (gameData !== undefined && gameData.mysteryPatchId === mysteryPatchId) {
      return;
    }

    let gameStart = rightNow();
    let gameDeadline = gameStart + 120;

    const cookiePayload = {
      mysteryPatchId: mysteryPatchId,
      gameStart: gameStart,
      gameDeadline: gameDeadline
    };
    value = encodeURIComponent(JSON.stringify(cookiePayload));
    VS.setCookie('gameData', value, 1, '/mystery_patch');
  };

  const setResultsCookie = function() {
    const cookiePayload = {
      mysteryPatchId: mysteryPatchId,
      timeSubmitted: rightNow(),
      results: resultsData
    };
    value = encodeURIComponent(JSON.stringify(cookiePayload));
    VS.setCookie('resultsData', value, 1, '/mystery_patch');
  };

  const startTimer = function() {
    $('#timer').html('2:00');
    let timeLeft;

    if (gameData !== undefined && gameData.mysteryPatchId === mysteryPatchId) {
      // if gameData is set, calculate remaining time
      timeLeft = gameData.gameDeadline - rightNow();
    } else {
      // otherwise start with a full clock
      timeLeft = 120; // otherwise start with a full clock
    }
    clearInterval(intervalId);

    intervalId = setInterval(function() {
      if (timeLeft >= 0) {
        let minutes = Math.floor(timeLeft / 60);
        let seconds = timeLeft % 60;
        $('#timer').text(`${minutes.toString()}:${seconds.toString().padStart(2, '0')}`);
        timeLeft--;
      } else {
        clearInterval(intervalId);
        $('#timer').text('Time\'s up!');
        if (!gameFinished) {
          $('#submit-solution').click();
          gameFinished = true;
        }

      }
    }, 1000);
  };

  const getMysteryPatch = function() {
    $.get('/mystery_patch.json').done(function(encryptedParams) {
      // Rotate back characters by todays UTC day of month
      dayOfMonth = new Date().getUTCDate();
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

      // =====================================
      // HANDLE GAME ALREADY PLAYED TODAY CASE
      // =====================================
      let currentUtcTimestamp = rightNow();
      let encodedResultsData = getCookieValue('resultsData');

      if (encodedResultsData !== null) {
        let resultsInfoFromCookie = JSON.parse(decodeURIComponent(encodedResultsData));
        if (resultsInfoFromCookie.mysteryPatchId === mysteryPatchId) {
          if (currentUtcTimestamp >= resultsInfoFromCookie.timeSubmitted) {
            resultsData = resultsInfoFromCookie.results;
            gameFinished = true;
          }
        }
      }

      let encodedGameData = getCookieValue('gameData');
      if (encodedGameData !== null) {
        let payload = JSON.parse(decodeURIComponent(encodedGameData));

        if (payload.mysteryPatchId === mysteryPatchId) {
          gameData = payload;
          if (!gameFinished) {
            if (currentUtcTimestamp >= payload.gameDeadline) {
              gameFinished = true;
            } else {
              // console.log('Continuing game in progress');
              gameHasStarted = true;
              startGame();
            }
          }
        } else {
          // console.log('Starting new game...');
        }
      }

      if (gameFinished) {
        if (resultsData !== undefined) {
          // Show previous results
          $('#results-button').click();
          $('#submit-solution').hide();
          printResultsInfo(false);
          return;
        } else {
          // Show message
          alert('Come back tomorrow when a new mystery patch will be available');
          return;
        }
      } else if (!gameHasStarted) {
        $('#pre-game-button').click();
      }
      // =========================================
      // END HANDLE GAME ALREADY PLAYED TODAY CASE
      // =========================================
    });
  };

  const playMysteryNote = function() {
    mysteryPatchEngine.activateAudio();
    mysteryPatchEngine.playNewNote(48);
    setTimeout(() => {
      mysteryPatchEngine.triggerSequencerRelease();
    }, 1000);
  };

  // When "play mystery patch"  button is clicked, play a c3 for 1 second
  $('#play-mystery-patch').on('click tap', function() {
    if (!gameHasStarted && !gameFinished) {
      startGame();
     }
     playMysteryNote();
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
        $('#share-text').text([
          `I guessed today's mystery synth patch with ${resultsData.total_score}% `,
          `accuracy.\n${emojiSummary}\n\nvolcashare.com/mystery_patch`,
          `\n\n#VSmysterypatch`
        ].join('')
        );
        $('#share-results').fadeIn('slow');
        $('#button-container').fadeIn('slow');

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
    $(this).hide();
    clearInterval(intervalId);
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
        lfo_shape: patch.lfo.shape
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

  getMysteryPatch();
});
