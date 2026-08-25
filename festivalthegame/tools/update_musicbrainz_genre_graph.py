#!/usr/bin/env python3
"""Build the offline typed Genre graph from public MusicBrainz entity pages."""

from __future__ import annotations

import argparse
import html
import json
import re
import time
import urllib.error
import urllib.request
from pathlib import Path


USER_AGENT = "FestivalTheGame/0.1 (https://github.com/Ponacko/Festivalthegame)"
RELATIONSHIP_SECTION = re.compile(
    r'<h2 class="relationships">Relationships</h2>(.*?)<div id="sidebar">', re.DOTALL
)
ROW = re.compile(r"<tr><th>(.*?)</th><td.*?>(.*?)</td></tr>", re.DOTALL)
GENRE_LINK = re.compile(r'href="/genre/([0-9a-f-]{36})"')
TYPES = {
    "subgenre of": "subgenre",
    "subgenres": "subgenre",
    "fusion of": "fusion",
    "has fusion genres": "fusion",
    "influenced by": "influence",
    "influenced genres": "influence",
}


def fetch_page(genre_id: str, cache_dir: Path, delay: float) -> str:
    cache_path = cache_dir / f"{genre_id}.html"
    if cache_path.exists():
        return cache_path.read_text(encoding="utf-8")

    url = f"https://musicbrainz.org/genre/{genre_id}"
    for attempt in range(6):
        started = time.monotonic()
        try:
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(request, timeout=30) as response:
                page = response.read().decode("utf-8")
            cache_path.write_text(page, encoding="utf-8")
            elapsed = time.monotonic() - started
            time.sleep(max(0.0, delay - elapsed))
            return page
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as error:
            if attempt == 5:
                raise RuntimeError(f"Could not fetch {url}: {error}") from error
            time.sleep(min(30.0, 2.0 ** attempt))
    raise AssertionError("retry loop must return or raise")


def relation_edges(source_id: str, page: str) -> set[tuple[str, str, str]]:
    section_match = RELATIONSHIP_SECTION.search(page)
    if not section_match:
        return set()
    edges: set[tuple[str, str, str]] = set()
    for raw_label, cell in ROW.findall(section_match.group(1)):
        label = html.unescape(re.sub(r"<.*?>", "", raw_label)).strip().rstrip(":")
        relation_type = TYPES.get(label)
        if relation_type is None:
            continue
        for target_id in GENRE_LINK.findall(cell):
            if target_id == source_id:
                continue
            left, right = sorted((source_id, target_id))
            edges.add((left, right, relation_type))
    return edges


def main() -> None:
    parser = argparse.ArgumentParser()
    project_dir = Path(__file__).resolve().parent.parent
    parser.add_argument(
        "--catalog", type=Path, default=project_dir / "data/musicbrainz_genres.json"
    )
    parser.add_argument(
        "--output", type=Path, default=project_dir / "data/musicbrainz_genre_graph.json"
    )
    parser.add_argument(
        "--cache", type=Path, default=Path("/tmp/festivalthegame_musicbrainz_genres")
    )
    parser.add_argument("--delay", type=float, default=1.05)
    args = parser.parse_args()

    genres = json.loads(args.catalog.read_text(encoding="utf-8"))
    known_ids = {genre["id"] for genre in genres}
    args.cache.mkdir(parents=True, exist_ok=True)
    edges: set[tuple[str, str, str]] = set()
    for index, genre in enumerate(genres, start=1):
        page = fetch_page(genre["id"], args.cache, args.delay)
        edges.update(relation_edges(genre["id"], page))
        if index % 100 == 0 or index == len(genres):
            print(f"Scanned {index}/{len(genres)} Genres; found {len(edges)} edges", flush=True)

    output = {
        "genre_ids": sorted(known_ids),
        "edges": [
            {"from": left, "to": right, "type": relation_type}
            for left, right, relation_type in sorted(edges)
            if left in known_ids and right in known_ids
        ],
    }
    args.output.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(output['edges'])} typed relationships to {args.output}")


if __name__ == "__main__":
    main()
