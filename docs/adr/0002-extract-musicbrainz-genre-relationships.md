---
status: accepted
---

# Extract Genre relationships from MusicBrainz entity pages

MusicBrainz stores typed Genre-to-Genre relationships, but its web-service API
does not expose them and the complete database dump is several gigabytes. The
build-time snapshot tool therefore reads the relationship table on each public
MusicBrainz Genre page at the documented one-request-per-second rate and emits
only stable Genre IDs plus `subgenre`, `fusion`, and `influence` edges. The game
bundles that small CC0 snapshot and never scrapes or contacts MusicBrainz at
runtime; the extractor is intentionally isolated so it can be replaced if an
official relationship API becomes available.

