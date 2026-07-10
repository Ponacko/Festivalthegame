# 1. Bundled MusicBrainz genre taxonomy for the genre model

Date: 2026-07-11

## Status

Accepted

## Context

Personalization requires knowing which genres are similar ("similar genres provide moderate enjoyment", taste-biased lineup generation). v1 defers all runtime external data (no music-service APIs), but a hand-authored list of ~12 genres was rejected as too coarse — the player should be able to tag a favorite artist as "atmospheric black metal", not just "metal".

Candidates considered:

- **MusicBrainz genre taxonomy** — ~2,000 genres as a graph with typed relationships (subgenre-of, fusion-of, influenced-by). CC0 licensed, downloadable dump, few hundred KB.
- **Every Noise at Once** — ~6,000 microgenres with 2D coordinates (similarity = spatial distance). Richer, but Spotify-derived, project defunct, licensing of scraped dumps murky.
- **Hand-authored list + similarity matrix** — trivial to build, far too coarse, and every added genre means hand-editing a matrix.

## Decision

Bundle a build-time snapshot of the MusicBrainz genre graph as a game asset. Genre similarity is derived from graph distance, giving a continuous affinity curve (100% for a Favorite Artist, decaying with genre distance, 10% floor). No runtime network access. The player still tags their typed Favorite Artists with a genre manually (searchable autocomplete); artist→genre auto-detection remains deferred with the other runtime-data features.

## Consequences

- Zero legal risk (CC0) and zero runtime network dependency; works fully offline on mobile.
- Genre granularity (~2,000) exceeds what any hand-authored model could offer, at the cost of ingesting and maintaining a dump-to-asset pipeline.
- Affinity, lineup generation, and any future artist auto-tagging must all speak MusicBrainz genre IDs — switching taxonomies later means migrating the generator and any saved data.
- Graph distance is a cruder similarity signal than ENAO's coordinates; if it produces odd neighborhoods, we may need to weight relationship types (subgenre closer than influenced-by) rather than switch datasets.
