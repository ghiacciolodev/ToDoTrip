# Privacy policy

Last updated: 19 August 2026

## 1. Read this first

**Nobody runs TodoTrip as a service.** There is no hosted instance, no sign-up
page on the internet, and nobody holding anyone's account. The app is source
code you can read and run yourself.

So this is not a notice in force. It is two things at once:

1. **A description of what the software does with data**, accurate to the code
   in this repository. Every item below matches something that really happens,
   and the point of writing it that way is that a privacy policy ought to be
   checkable against the thing it describes.
2. **A template for anyone who deploys it.** The fields in square brackets have
   no honest answer until somebody runs it for other people. The moment they
   do, those become that person's obligations rather than a formality.

The app asks you to accept this document when you create an account, and the
server records the date and the version you accepted. It refuses to create the
account otherwise.

## 2. Who is responsible

Whoever runs TodoTrip for other people becomes what the GDPR calls the **data
controller**: the party that decides what is collected and why, and the one
users exercise their rights against. That party has to name itself here.

> TodoTrip is operated by [CONTROLLER NAME], [ADDRESS], reachable at
> [CONTACT EMAIL].

Two things do not come for free with the paragraph above, and whoever fills it
in has to deal with them rather than inherit them from this file.

- **An age check.** Section 12 says the app is not for under-16s, and nothing
  in the code enforces it.
- **Somebody who would notice a breach.** Section 11 promises an authority will
  be told within 72 hours. That promise needs a person behind it.

This text is in English only. A controller addressing users in another language
owes them the notice in that language (Art. 12(1)), which is a translation job
for a lawyer rather than for the app's translation files.

## 3. What is stored, and why

**Your account.** Your email address, the name you choose to display, and the
date you signed up. Your password is never stored: what is kept is an Argon2id
hash of it, which cannot be turned back into the password. This is what gives
you an account at all, so the legal basis is performance of the contract with
you (Art. 6(1)(b)).

**That you accepted this policy.** The moment you did and which version you saw.
Kept because a controller has to be able to demonstrate consent (Art. 7(1)),
and a bare yes proves nothing once the text has been edited.

**Your trips.** The name, description, dates, currency, icon and colour of each
trip, its invite codes, and who is a member. Same basis: it is the service.

**What you plan.** Events and to-dos, with their titles, descriptions,
free-text locations, dates, who they are assigned to and who marked them done.
Checklists, their entries, and who ticked each one.

**What you spend.** Amounts, currency, descriptions, who paid, how each expense
is split, and the repayments recorded between members. Balances are never
stored: they are recalculated from these records every time.

**Places you save.** Coordinates, name, category and notes of the pins your
group puts on the trip map.

**Where you are, only while you are sharing it.** See section 4.

**Notifications.** When somebody adds an expense, records a repayment, assigns
you a task, adds something to the plan or joins a trip, a notification is
stored for each person who should hear about it. It holds the facts as they
were at that moment (a name, an amount, a description, the trip's name) copied
rather than looked up later, so it still reads as a sentence after the expense
it describes has been deleted. It also records whether you have read it. You
can delete them one at a time or all at once, and switch a trip to silent,
which stops new ones being created for you.

**Your sessions.** A hashed copy of each sign-in token, so a session can be
ended. Signing out, changing your password or deleting your account revokes
them all.

**Your IP address, briefly.** Held in the server's memory for a few minutes to
limit repeated sign-in, sign-up and invite-code attempts. It is not written to
a database and not used to identify you. The basis is the legitimate interest
in keeping accounts from being broken into by guesswork (Art. 6(1)(f)).

**A request identifier, in the log.** Each request writes one line recording the
method, the path, the status and how long it took, with a random identifier so
the lines belonging to one request can be found together. It carries no account
and no content.

## 4. Location

Live location is off unless you turn it on, per trip, and it runs only while the
app is open on screen. When it is on:

- your device's coordinates are sent to the server and shared with the other
  members of that trip;
- each position expires **30 minutes** after it is recorded and stops being
  shown to anyone;
- turning sharing off, leaving the trip, being removed from it, or deleting
  your account deletes your stored position immediately.

The legal basis is your consent (Art. 6(1)(a)), given when you allow the
permission and switch sharing on. You can withdraw it at any moment by
switching it off, with no effect on anything else in the app.

Positions are not kept as a history. Only the most recent one per person per
trip exists, and the next one overwrites it.

## 5. What other members of a trip can see

Everyone in a trip can see everything in it: the plan, the lists, every expense
and every split, the pins, the member list, and your location while you are
sharing it. Your email address is visible to the other members of trips you are
in.

People who leave a trip stop seeing all of it immediately. Their name stays
attached to the expenses they took part in, because deleting those records would
change what everybody else owes.

Any member can export a trip's expenses as a spreadsheet. That file holds every
expense, who paid, and what each person's share was, including people who have
left. Once it leaves the app it is an ordinary file, and where it goes next is
up to whoever exported it.

## 6. Who else receives data

**The map tile provider.** When you open the map, your device asks a tile server
for the images directly. It receives your device's IP address and which part of
the world you are looking at. It does not receive your account, your trips or
your sign-in token: the map uses a separate connection that carries no
credentials at all. Which provider it is depends on the build. Unless stated
otherwise it is OpenStreetMap, whose policy is at
https://osmfoundation.org/wiki/Privacy_Policy

**Your map app.** If you tap "Get directions", the destination is handed to
whichever maps application you choose to open. What happens next is governed by
that app's policy, not this one.

The typeface, the icons and everything else the app draws with are inside the
app itself. Nothing else is fetched from a third party at any point.

There is no analytics, no advertising, no tracking pixel and no crash reporting
service. Nowhere in the code is anything sold or shared with anybody for
marketing, which is a claim you can check rather than trust.

## 7. Where it is stored

Data is held on servers located in [HOSTING LOCATION AND PROVIDER]. [If any
processor or server sits outside the EEA, name it here together with the
transfer safeguard relied on: Standard Contractual Clauses, or an adequacy
decision.]

## 8. How long it is kept

Your account data stays until you delete your account. When you do:

- your email address, your display name and your password are erased;
- every session is revoked;
- trips in which you were the only member are deleted entirely;
- your memberships and your shared location are deleted;
- expenses, splits and repayments you were part of **are kept**, because they
  determine what other people owe each other. They are no longer linked to your
  name or your email, only to an anonymous record.

If you still own a trip that other people are in, you have to hand it over or
close it before your account can be deleted. Otherwise that group would be left
with nobody able to administer it.

Notifications are deleted on their own schedule, whether or not you ask:
**30 days** after you have read one, **90 days** if you never did. Deleting a
trip deletes every notification about it.

Live location is the shortest-lived of all of it. Each position stops being
readable **30 minutes** after it was recorded.

## 9. Your rights

Under the GDPR you can ask for a copy of your data (access), have it corrected
or deleted, restrict or object to how it is used, and have it handed to you or
another service in a machine-readable form (portability). Where consent is the
basis, which here means live location and your acceptance of this policy, you
can withdraw it at any time.

The app lets you do most of this without asking anybody: edit your name in
Settings, turn off location sharing, leave a trip, delete your account, and
export a trip's expenses as a spreadsheet. That export is the portable,
machine-readable copy of the part of your data worth having in one file. This
is deliberate, and it is the half a controller cannot get wrong.

For anything the app cannot do itself, a running instance owes you a reply
within one month at [CONTACT EMAIL].

If you think your data is being handled wrongly you can complain to your
national data protection authority. In Italy that is the Garante per la
protezione dei dati personali (www.gpdp.it).

## 10. Automated decisions

There are none. Nothing in the app profiles you or makes decisions about you
automatically.

## 11. Security

Passwords are hashed with Argon2id. Traffic runs over HTTPS. Sign-in tokens are
short-lived and rotate, so a stolen one stops working quickly, and the app keeps
them in the device's own encrypted store. Access to anything inside a trip is
checked against your membership of that trip on every request, and an open
realtime connection is rechecked every minute, so losing access ends it rather
than waiting for the app to be closed.

No system is perfectly safe. Whoever runs an instance owes the supervisory
authority notice within 72 hours of a breach that puts users' rights at risk,
and owes those users notice where the law requires it.

## 12. Children

TodoTrip is not intended for children under 16. Nothing in the code checks an
age, so an instance that expects to reach any is relying on this sentence and
nothing else.

## 13. The source code

TodoTrip is free software, released under the Apache License 2.0. Every claim on
this page can be checked against the code that makes it, which is the point of
publishing it: https://github.com/ghiacciolodev/ToDoTrip

If you are reading this inside a copy that somebody else is running, be aware
that this licence does not oblige them to publish their changes. What their
version does with your data is a question for them, and their answer is the one
that binds them, not this file.

## 14. Changes

This file lives beside the code and changes with it. The date at the top is the
last time it did, and it is the version recorded against your account when you
accepted it. A running instance owes its users notice in the app before a change
that matters takes effect.
