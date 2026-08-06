# App Store listing — i-GB

Metadata for App Store Connect. No emoji anywhere: Apple rejects emoji in the
app name, subtitle and keywords, and flags them in the description as well.

Character limits are Apple's, counted including spaces.

---

## App name (30 max)

```
i-GB: AR Game Board Melaka
```

25 characters.

## Subtitle (30 max)

```
Scan landmarks, learn, play
```

27 characters.

## Promotional text (170 max)

Editable any time without submitting a new build, so use it for what changes.

```
Point your camera at a Melaka landmark card and the questions appear. Seven sites, over 170 questions in History and Mathematics, with revision notes built in.
```

157 characters.

## Keywords (100 max, comma separated, no spaces after commas)

Do not repeat words already in the app name or subtitle — Apple indexes those
separately, so repeating them wastes the budget.

```
augmented,reality,education,quiz,sejarah,matematik,melaka,tourism,school,student,revision,heritage
```

97 characters.

## Description (4000 max)

```
i-GB is an interactive game board that uses augmented reality to turn a set of
printed landmark cards into a learning activity.

Point the camera at a card and the app recognises the landmark, then presents
questions tied to that place. Answer them, collect your score, and move to the
next card.

SEVEN MELAKA LANDMARKS

Kota A'Famosa, Masjid Cina, Masjid Selat, Menara Taming Sari, Muzium Samudera,
Pantai Klebang and Stadium Melaka. Each card carries its own question set, so
every landmark is a different round.

QUESTION BANKS

More than 170 questions across two subjects:

- Sejarah Melaka, written for the seven landmarks above
- Mathematics for primary school, secondary school and higher education,
  graded from basic through to challenge level

Questions come in multiple choice and short answer form, and the app accepts
every reasonable spelling of a written answer.

REVISION NOTES

Nota Permainan collects short notes for each landmark and subject. Notes can
carry diagrams and photographs, and any image opens full screen where it can be
pinched and zoomed, so a scanned page stays readable on a phone.

FOR EDUCATORS

Lecturers and teachers sign in to the admin area to add, edit and reorder both
questions and notes, upload images, and group questions by topic. Changes reach
every device immediately, with no app update needed.

REQUIREMENTS

The app needs a camera and a device that supports ARCore based tracking. An
internet connection is required to fetch questions and notes.
```

Around 1500 characters, well inside the limit.

## What's New (4000 max) — for version 1.0.9

```
- Landmark artwork added to Nota Permainan, so each place is easy to recognise
- Note images and landmark cards now open full screen and can be zoomed
- Notes can now be a picture on its own, with no text required
- Soal Selidik opens the questionnaire directly
- Fixes and small improvements throughout
```

## Support and marketing URLs

App Store Connect requires a support URL. Not yet decided — needs a page that
answers "how do I get the printed cards" and gives a contact address.

## Age rating

4+ expected. There is no user generated content visible to other users, no
advertising, no purchases. The admin area is password protected.

---

## Before the first submission

Two things in the project need attention:

1. `ios/Runner/Info.plist` has `CFBundleDisplayName = My Ar App`. That is the
   name shown under the icon on the home screen. It should read `i-GB`.
2. `NSLocalNetworkUsageDescription` says the app connects to "the lecturer's
   local AR3D question server", but the app talks to a public host over the
   internet. Reviewers read these strings; either correct the wording or drop
   the key if local networking is not used.
