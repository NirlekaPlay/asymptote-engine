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

2. Patrolling. A Guard can have a patrolling duty. A map or level has posts, each posts are grouped so that
specific Guards can only patrol around their designated posts.

Each posts contains information, which includes the position, of course, the facing direction, tells the Guard
once in a post to face what direction, and if its occupied or not.
e.g. `{ cframe: CFrame, occupied: boolean }` (CFrames can have both position and orientation so thats handy)

A Guard typical routine for patrolling are:

 a. If the Guard is not on any posts, it tries to randomly find one designated under them. It checks if those
    posts are occupied or not. If it is occupied, keep searching. If it finds a post thats unoccupied, then
    it sets said post as occupied and begins to walk to it.
 b. Once a Guard is on a post, it waits for a random time, and after thats done, it tries to find an unoccupied
    post designated under them. If it does not find one, stays there until it does. Once it does find one,
    release the current post and sets the selected post as occupied, and walks to it. And the cycle repeats.
 c. A Guard may release a post under certain circumstances, which includes, but not limited to:

     i. A Guard becomes alerted.

3. Trespassing. Trespassing can be split to 2 classifications:

 a. Minor Trespassing.
 b. Major Trespassing.

Trespassing status is affected by a Player's disguise. e.g. An undisguised Player is in an
employees-only area. This gives the Player a Minor Trespassing status. If the Player is in a more
restricted area such as security rooms, then it gives the Player a Major Trespassing status.

If a Player wears a disguise, then Minor Trespassing zones will not give them its status. And 
Major Trespassing zones will now give them Minor Trespassing status.