# Asset provenance

Festival: The Game v1 currently uses original, code-drawn pixel placeholder art.

| Asset group | Source | License | Notes |
| --- | --- | --- | --- |
| Player and Friend sprites | `scripts/ui/pixel_art.gd`, Festival: The Game contributors | CC0-1.0 | Original 32 px-scale integer-grid shapes |
| Facility and camp icons | `scripts/ui/pixel_art.gd`, Festival: The Game contributors | CC0-1.0 | Original code-drawn icons |
| Stage, crowd, zones | `scripts/entities/stage_view.gd`, Festival: The Game contributors | CC0-1.0 | Original deterministic code-drawn art |
| UI theme | `ui/festival_theme.tres`, Festival: The Game contributors | CC0-1.0 | Original palette and StyleBox definitions |

No third-party visual assets or runtime asset downloads are used. The listed placeholder art is offered under CC0-1.0 so release packages may redistribute it without additional attribution requirements.

## Audio

| Asset group | Source | License | Notes |
| --- | --- | --- | --- |
| `audio/loops/{rock,electronic,hiphop,acoustic}.wav` | Original procedural synthesis by Festival: The Game contributors | CC0-1.0 | GStreamer `audiotestsrc`, 22.05 kHz mono; square/saw/sine/triangle neighborhoods |
| `audio/loops/crowd.wav` | Original procedural synthesis by Festival: The Game contributors | CC0-1.0 | GStreamer pink-noise crowd bed, 22.05 kHz mono |

Audio is bundled in release exports. Playback never requests network content.
