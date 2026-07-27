# Privacy policy

Last updated: 27 July 2026

This describes what TodoTrip stores about you, why, who else can see it, and how
to get rid of it. It describes the app as it is actually built — every item
below corresponds to something the code really does.

## Who is responsible

TodoTrip is operated by [CONTROLLER NAME], [ADDRESS], reachable at
[CONTACT EMAIL]. Under the GDPR this is the "data controller": the party that
decides what is collected and why, and the one you exercise your rights against.

## What we store, and why

**Your account.** Your email address, the name you choose to display, and the
date you signed up. Your password is never stored: what is kept is an Argon2id
hash of it, which cannot be turned back into the password. This is needed to
give you an account at all, so the legal basis is performance of our contract
with you (GDPR Art. 6(1)(b)).

**Your trips.** The name, description, dates, currency, icon and colour of each
trip, its invite codes, and who is a member of it. Same basis: it is the service.

**What you plan.** Events and to-dos, with their titles, descriptions, free-text
locations, dates, who they are assigned to and who marked them done. Checklists,
their entries, and who ticked each one.

**What you spend.** Amounts, currency, descriptions, who paid, how each expense
is split between members, and the repayments recorded between you. Balances are
never stored — they are recalculated from these records every time.

**Places you save.** Coordinates, name, category and notes of the pins your group
puts on the trip map.

**Where you are, only while you are sharing it.** See the next section.

**Your sessions.** A hashed copy of each sign-in token, so a session can be
ended. Signing out, changing your password, or deleting your account revokes
them.

**Your IP address, briefly.** Held in the server's memory for a few minutes to
limit repeated sign-in, sign-up and invite-code attempts. It is not written to a
database and not used to identify you. The basis is our legitimate interest in
keeping accounts from being broken into by guesswork (Art. 6(1)(f)).

## Location

Live location is off unless you turn it on, per trip, and it only runs while the
app is open on screen. When it is on:

- your device's coordinates are sent to the server and shared with the other
  members of that trip;
- each position expires **30 minutes** after it is recorded and stops being
  shown to anyone;
- turning sharing off, leaving the trip, being removed from it, or deleting your
  account deletes your stored position immediately.

The legal basis is your consent (Art. 6(1)(a)), given when you allow the
permission and switch sharing on. You can withdraw it at any time by switching
it off, with no effect on anything else in the app.

Positions are not kept as a history: only the most recent one per person per trip
exists, and it is overwritten by the next.

## What other members of a trip can see

Everyone in a trip can see everything in that trip: the plan, the lists, every
expense and every split, the pins, the member list, and — while you are sharing
it — your location. Your email address is visible to other members of trips you
are in.

People who leave a trip stop seeing all of it immediately. Their name stays
attached to expenses they took part in, because deleting those records would
change what everybody else owes.

## Who else receives data

**OpenStreetMap.** When you open the map, your device asks OpenStreetMap's tile
servers for the map images directly. They receive your device's IP address and
which part of the world you are looking at. They do not receive your account, your
trips, or your sign-in token — the map uses a separate connection that carries no
credentials. Their policy: https://osmfoundation.org/wiki/Privacy_Policy

**Google Fonts.** The app currently downloads its typeface from Google's servers
the first time it runs, which discloses your device's IP address to Google. There
is no functional need for this and it is intended to be removed by shipping the
font inside the app.

**Your map app.** If you tap "Get directions", the destination is handed to
whichever maps application you choose to open. What happens next is governed by
that app's own policy, not this one.

We do not use analytics, advertising, tracking pixels, or crash reporting
services, and we do not sell or share your data with anyone for marketing.

## Where it is stored

Data is held on servers located in [HOSTING LOCATION AND PROVIDER]. [If any
processor or server sits outside the EEA, name it here together with the transfer
safeguard relied on — Standard Contractual Clauses or an adequacy decision.]

## How long we keep it

Your account data stays until you delete your account. When you do:

- your email address, your display name and your password are erased;
- every session is revoked;
- trips in which you were the only member are deleted entirely;
- your memberships and your shared location are deleted;
- expenses, splits and repayments you were part of **are kept**, because they
  determine what other people owe each other. They are no longer linked to your
  name or your email — only to an anonymous record.

If you still own a trip that other people are in, you have to hand it over or
close it before your account can be deleted; otherwise that group would be left
with nobody able to administer it.

## Your rights

Under the GDPR you can ask us to: give you a copy of your data (access),
correct it, delete it, restrict or object to how we use it, and hand it to you or
another service in a machine-readable form (portability). Where we rely on your
consent — live location — you can withdraw it at any time.

The app itself lets you do most of this directly: edit your name in Settings,
turn off location sharing, leave a trip, delete your account. For anything else,
write to [CONTACT EMAIL]; we answer within one month.

If you think we are handling your data wrongly you can complain to your national
data protection authority. In Italy that is the Garante per la protezione dei
dati personali (www.gpdp.it).

## Security

Passwords are hashed with Argon2id. Traffic runs over HTTPS. Sign-in tokens are
short-lived and rotate, so a stolen one stops working quickly, and the app stores
them in the device's own encrypted store. Access to anything inside a trip is
checked against your membership of that trip on every request.

No system is perfectly safe. If a breach ever puts your rights at risk we will
tell the supervisory authority within 72 hours and tell you where the law
requires it.

## Children

TodoTrip is not intended for children under 16 and we do not knowingly hold
their data. If you believe a child has an account, write to [CONTACT EMAIL] and
we will remove it.

## Automated decisions

There are none. Nothing in the app profiles you or makes decisions about you
automatically.

## Changes

If this policy changes in a way that matters, we will say so in the app before
the change takes effect. The date at the top always reflects the current version.
