# Offline mobile smoke test

Test one representative landscape phone and tablet on each supported platform.

- Install the release package, disable Wi-Fi/mobile data, and cold-start successfully.
- Generate a Run with 10 Favorites, four Friends, and each campsite option; verify touch-only movement and every HUD action.
- Exercise Schedule, Map, Group Chat/meet request, water, toilet, Vendor purchase, Queue leave, Mosh, First Aid, camp changing, pause, speed, and Sound controls.
- Suspend/kill during arena play, an active Queue, Tipsy/poisoning, night choice, and morning recap; relaunch and verify exact autosave resume with no replayed effects.
- Complete all three Days, verify scoreboard/high-score persistence, then create a new generated Run.
- Confirm Stage music is confined to Audience range, crowd ambience scales, and pause/transitions/resume do not duplicate audio.
- Check safe areas and scrolling at representative 16:9, 20:9, and 4:3 resolutions.
- Profile the busiest popular Set with four Friends: sustained frame time must remain at or below 16.7 ms and static memory below 256 MiB.
- Confirm no network permission/request and no missing taxonomy, data, art, or audio while offline.
