$(function() {
  window.acceptCookies = function() {
    document.cookie = "cookie_consent=accepted; path=/; max-age=" + (60*60*24*365);
    document.getElementById('cookie-banner').style.display = 'none';
  };
});
