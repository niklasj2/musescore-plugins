# Swing Rhythm Converter: Straight / Dotted / Triplet

> **Status: beta.** Core conversions have been tested and work as intended,
> but this hasn't yet been exercised across a wide range of real scores.
> See "Known limitations" below before relying on it for anything important
> - always keep a backup or use MuseScore's undo (Ctrl+Z) after running it.

A MuseScore Studio 4.x QML plugin that converts quarter-beat rhythms
between three interpretations:

- **Straight eighths** (1:1) — two even eighth notes
- **Dotted eighth + sixteenth** (3:1) — the classic dotted "shuffle" rhythm
- **Triplet swing** (2:1) — a quarter-note-triplet + eighth-note-triplet pair
  (the standard notation for a swing/jazz feel)

You pick the *target* pattern in the dialog; the plugin scans the
selection (or the whole score if nothing is selected) and rewrites any
matching occurrence of the *other two* patterns into it. Pairs already in
the target pattern are left untouched.

## Installation

1. Copy `SwingRhythmConverter.qml` into your MuseScore Plugins folder
   (e.g. `Documents/MuseScore4/Plugins/`).
2. In MuseScore Studio, open **Plugins → Plugin Manager** and enable
   "Swing Rhythm Converter: Straight / Dotted / Triplet".
3. Select a region (or select nothing to process the whole score), run
   the plugin, and choose the target pattern in the dialog.

## Notes

- Only rewrites pairs where both notes are actual notes (not rests).
- Preserves pitch and enharmonic spelling (tpc).
- The dotted-eighth+sixteenth (3:1) and triplet-swing (2:1) forms are
  musically distinct feels, not equivalent notations — converting
  between them is a deliberate reinterpretation of the rhythm, not a
  neutral rewrite.

## Known limitations (beta)

- **Chords (multiple pitches at once):** the core logic supports them, but
  they've had far less testing than single-note melodic lines. If you use
  the plugin on chordal passages, double-check the result carefully.
- **Nested/irregular tuplets:** the plugin looks for a plain 3:2 eighth-note
  triplet occupying exactly one quarter beat. Other tuplet ratios, nested
  tuplets, or triplets that don't cleanly span a single quarter beat are
  not recognized and will be left alone.
- **Removing an existing triplet** (converting swing → straight/dotted)
  relies on `removeElement()` targeting the tuplet object specifically.
  This works reliably in testing so far, but tuplet removal is a known
  fragile area of the MuseScore plugin API in general, so edge cases may
  still surface with unusual input.
- **Cross-barline or cross-voice-change patterns** haven't been
  specifically tested; the plugin assumes each quarter-beat pattern sits
  within a single measure and voice.

If you hit an edge case, please note the exact input rhythm and what the
plugin produced — that'll make it much faster to track down.
