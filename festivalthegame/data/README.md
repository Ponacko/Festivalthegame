# Bundled data

`musicbrainz_genres.json` is a build-time snapshot of the complete MusicBrainz
Genre list. It contains only each Genre's stable MusicBrainz identifier and
display name; the game never contacts MusicBrainz at runtime.

- Source: `https://musicbrainz.org/ws/2/genre/all`
- Retrieved: 2026-08-25
- License: MusicBrainz core data, CC0
- Refresh: run `tools/update_musicbrainz_genres.sh` from the project directory
