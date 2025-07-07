Project Asymptote Engine Design Document

1. Suspicion System. Each Agent has a SuspicionMangement that stores each suspicion value
of each Player. e.g `{ [Player]: number }` A suspicion value can go from 0.0 to 1.0.

Each Player have statuses which includes, in order of priority:

  i. Minor Trespassing;
 ii. Major Trespassing;
iii. Minor Suspicous;
 iv. Criminal Suspicious;
  v. Disguised; and
 iv. Armed.

Each of these statuses can be stacked, e.g. `{ statuses: { "MINOR_TRESPASSING", "DISGUISED", "ARMED"} }`,
And this effects the speed of which an Agent who detects the Player suspicion value raises.

SuspicionMangement has three states: `CALM`, `SUSPICIOUS`, and `ALERTED`.

 a. Calm State. The manager raises the suspicion value of each player whos in sight, and lowers
    those whos not. Once one of the Player's suspicion value reached a certain threshold,
    below the max suspicion value (1.0), the manager goes to `SUSPICIOUS` state.
 b. Suspicious State. Once in this state, any other Players are ignored and their suspicion
    value decreases. And the manager focuses on the Player who crosses the threshold. Until the
    suspicion value reaches 1.0 and goes to `ALERTED` state or Player's status is higher priority
    than the focused Player.
 c. Alerted State. In this state, only lowers other Players' suspicion value, the focused Player's
    suspicion value remains 1.0.

e.g. A Guard sees a `{ "DISGUISED" }` Player, suspicion for the player raises. Reaches 0.6 which is the
threshold, any other Players with a lower suspicious priority, e.g. `{ "MINOR_TRESPASSING" }`,
are ignored and their suspicion lowers. However, if another Player gets on sight with `{ "ARMED" }`,
the Guard's focus focuses on the armed player and raises the suspicion on them.