# Festival: The Game — Ubiquitous Language

Glossary of domain terms. Keep implementation details out of this file.

## Terms

### Festival
The generated multi-day event the player attends. In v1 it is always procedurally generated (no real-world data), biased toward the player's stated music tastes.

### Festival Day
One day of the Festival. The natural unit of play and saving; a Run consists of several consecutive Festival Days.

### Run
One complete playthrough of a single Festival, from arrival to final scoring.

### Set
A single performance by one Artist on one Stage with a scheduled start and end time. The player may arrive late, leave early, or stay for the whole Set; enjoyment is earned for the portion actually attended.

### Enjoyment Score
The cumulative, run-total score the player maximizes; the success metric of a Run. It only increases. Earned per minute of attended Sets (and other rewarding activities), scaled by the player's current needs state.

### Need
A decaying personal meter the player must manage (e.g. Hunger, Thirst, Energy, Bladder, Mood). The combined state of all Needs multiplies the rate at which Enjoyment Score is earned; a Need hitting empty triggers a penalty.

### Mood
A Need representing how good a time the player is having *right now* — short-term and decaying, unlike the Enjoyment Score. Raised by fun activities (e.g. mosh pits, drinks, time with friends); drained by boredom, queues, and discomfort. (The design doc's need called "Fun" is this; "Fun" is reserved for casual UI copy only.)

### Audience Zone
One of three bands around a performing Stage — Front, Mid, Back — with increasing enjoyment multiplier and crowd density toward the front. Density scales with the Artist's popularity. Outside the zones a Set earns nothing.

### Mosh Pit
An opt-in zone inside Front at Sets in mosh-appropriate genre neighborhoods, active during the Set's peak. Grants a large Mood boost and enjoyment bonus, drains Energy heavily, and risks Injury per minute inside.

### Injury
State caused by Mosh Pit risk: halved walk speed and a Mood debuff until treated at the First Aid Tent. Costs time, never score.

### Budget
The finite amount of player money for one Run, fixed at Run start and never replenished during the Festival (in v1). Spent on food, drinks, and similar purchases. Distinct from the Enjoyment Score — spending money never directly reduces Enjoyment. Free water taps guarantee Thirst is always solvable without money.

### Tipsy
Temporary state from drinking alcohol: boosts Mood and Social gains, wobbles movement, accelerates Bladder, and overindulgence drains the next day's Energy. Different kinds of alcohol (beer, wine, spirits, …) have different stat profiles and prices. Alcohol is explicit and cartoonish; drugs of any kind are permanently out of scope.

### Campsite
The group's tent location, chosen once at Run start from areas with distinct trade-offs (walk distance vs. sleep quality vs. nightlife). Sleep quality — Energy recovered per hour of sleep — is a property of the Campsite, modified nightly by noise and Tipsy level.

### Collapse
What happens when Hunger, Thirst, or Energy hits empty: the player blacks out and wakes at the First Aid Tent a chunk of festival time later, with the offending Need partly restored and Mood floored. Failures cost time and earning rate only — the Enjoyment Score is never reduced.

### First Aid Tent
Festival facility where the player wakes after a Collapse.

### Stage
A venue within the Festival grounds where Sets are performed. Stages vary in size; an Artist's popularity determines which size of Stage they play.

### Lineup
The full collection of Artists booked for the Festival, together with the assignment of each Artist's Set to a Stage and time slot.

### Schedule Conflict
Two Sets the player wants to see (typically involving Favorite Artists) that overlap in time or are otherwise impossible to fully attend both. The generator deliberately guarantees some Schedule Conflicts each Run.

### Artist
A performer in the Festival lineup. In v1, artists are procedural, with a genre and popularity; the player's favorite artists are entered manually.

### Friend
An autonomous companion NPC in the player's group (0–4 per Run), with their own taste profile and personal schedule. Friends provide Social/Mood income and a shared-experience Enjoyment bonus when nearby. They are company, not characters: no dialogue trees or relationship meters. The whole group shares one campsite automatically.

### Vendor
A food or drink stall on the festival grounds, instantiated from an archetype (menu of items, each defined by price, restoration, Mood bonus, and poisoning risk). Prices carry a location markup.

### Food Poisoning
A timed affliction rolled on eating risky food, with delayed onset: rapid Bladder/Thirst drain, floored Mood, and forced toilet dashes for a few game-hours. Costs time, never score.

### Queue
Waiting line at Vendors and toilets, scaling with nearby crowd. Queueing is dead time that drains Mood; queue timing is part of schedule strategy.

### Genre
A music style drawn from the bundled MusicBrainz genre taxonomy (~2,000 genres with typed relationships). Every Artist has exactly one Genre; the player tags each Favorite Artist with a Genre at setup via searchable autocomplete.

### Genre Distance
How far apart two Genres are in the genre graph. Drives affinity: enjoyment base rate decays continuously from 100% (Favorite Artist) with increasing Genre Distance from any favorite, down to a 10% floor. Also used by the generator to bias the Lineup toward the player's tastes.

### Group Chat
The single social interface: a phone UI showing each Friend's current plan, with one verb — "meet me at X" — which a Friend accepts or declines based on their own schedule.

### Favorite Artist
An artist the player declared as a taste preference during setup. Sets by Favorite Artists grant the highest enjoyment.
