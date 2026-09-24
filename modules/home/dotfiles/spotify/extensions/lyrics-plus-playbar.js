// Lyrics Plus keeps its "Playbar button" setting in Spotify's localStorage;
// this turns it on, so the player's lyrics button opens Lyrics Plus too
// instead of Spotify's own lyrics page.
(function lyricsPlusPlaybar() {
  if (!Spicetify.LocalStorage) {
    setTimeout(lyricsPlusPlaybar, 300);
    return;
  }

  const key = "lyrics-plus:visual:playbar-button";
  if (Spicetify.LocalStorage.get(key) === "true") return;

  Spicetify.LocalStorage.set(key, "true");
  // Lyrics Plus may have read the key already; notify it the way its own
  // settings toggle does.
  window.dispatchEvent(
    new CustomEvent("lyrics-plus", { detail: { name: "playbar-button", value: true } }),
  );
})();
