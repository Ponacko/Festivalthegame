# Bundled data

`musicbrainz_genres.json` is a build-time snapshot of the complete MusicBrainz
Genre list. It contains only each Genre's stable MusicBrainz identifier and
display name; the game never contacts MusicBrainz at runtime.

- Source: `https://musicbrainz.org/ws/2/genre/all`
- Retrieved: 2026-08-25
- License: MusicBrainz core data, CC0
- Refresh: run `tools/update_musicbrainz_genres.sh` from the project directory

`musicbrainz_genre_graph.json` is the matching build-time snapshot of typed
Genre relationships (`subgenre`, `fusion`, and `influence`). MusicBrainz does
not currently expose these through its web-service API, so the refresh tool
reads each public Genre relationship page at a rate of no more than one request
per second and caches pages outside the repository.

- Source: `https://musicbrainz.org/genre/{MusicBrainz Genre ID}`
- Retrieved: 2026-08-26
- License: MusicBrainz core relationship data, CC0
- Refresh: run `tools/update_musicbrainz_genre_graph.py`
