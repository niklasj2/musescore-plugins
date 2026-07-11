# Dotted Eighth + Sixteenth → Two Eighths

A MuseScore Studio 4.x QML plugin that rewrites every dotted eighth note +
sixteenth note pair into two straight eighth notes.

- Operates on the current selection, or the whole score if nothing is selected
- Works across all staves and voices
- Preserves pitch and enharmonic spelling (tpc)
- Only rewrites actual notes (not rests) in the matched pattern

## Installation

1. Copy `RewriteDottedEighthSixteenth.qml` into your MuseScore Plugins folder
   (e.g. `Documents/MuseScore4/Plugins/`).
2. In MuseScore Studio, open **Plugins → Plugin Manager** and enable
   "Dotted Eighth + Sixteenth → Two Eighths".
3. Select a region (or select nothing to process the whole score) and run
   the plugin from the **Plugins** menu.

## Notes

Only pairs where both the dotted eighth and the sixteenth are actual notes
(not rests) are rewritten, matching the intended musical pattern.
