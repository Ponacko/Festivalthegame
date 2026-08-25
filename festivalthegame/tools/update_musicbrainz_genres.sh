#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_PATH="${1:-$PROJECT_DIR/data/musicbrainz_genres.json}"
API_ROOT="https://musicbrainz.org/ws/2/genre/all"
USER_AGENT="FestivalTheGame/0.1 (https://github.com/Ponacko/Festivalthegame)"
SNAPSHOT_DIR="$(mktemp -d)"
trap 'rm -rf "$SNAPSHOT_DIR"' EXIT

fetch_page() {
	local offset="$1"
	curl --fail --silent --show-error \
		-A "$USER_AGENT" \
		"$API_ROOT?fmt=json&limit=100&offset=$offset" \
		-o "$SNAPSHOT_DIR/$offset.json"
}

fetch_page 0
genre_count="$(jq -r '."genre-count"' "$SNAPSHOT_DIR/0.json")"

for ((offset = 100; offset < genre_count; offset += 100)); do
	# MusicBrainz asks clients to stay at or below one request per second.
	sleep 1
	fetch_page "$offset"
done

mkdir -p "$(dirname "$OUTPUT_PATH")"
jq -s \
	'[.[].genres[] | {id: .id, name: .name}] | unique_by(.id) | sort_by(.name)' \
	"$SNAPSHOT_DIR"/*.json > "$SNAPSHOT_DIR/musicbrainz_genres.json"

actual_count="$(jq length "$SNAPSHOT_DIR/musicbrainz_genres.json")"
if [[ "$actual_count" != "$genre_count" ]]; then
	printf 'Expected %s Genres, produced %s\n' "$genre_count" "$actual_count" >&2
	exit 1
fi

mv "$SNAPSHOT_DIR/musicbrainz_genres.json" "$OUTPUT_PATH"
printf 'Wrote %s MusicBrainz Genres to %s\n' "$actual_count" "$OUTPUT_PATH"

