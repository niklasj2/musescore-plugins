import QtQuick 2.9
import MuseScore 3.0

MuseScore {
    version: "1.0"
    description: "Rewrites every occurrence of a dotted eighth note + sixteenth note into two straight eighth notes, within the selection, or across the whole score if nothing is selected."
    title: "Dotted Eighth + Sixteenth -> Two Eighths"
    categoryCode: "composing-arranging-tools"
    requiresScore: true
    pluginType: "dialog"
    width: 1
    height: 1

    // Ticks per quarter note, read from the score, so this works regardless of resolution
    property int eighthTicks: Math.round(division / 2)

    // Rebuilds an element (chord or rest) at the given tick as an eighth note
    // with the given pitches (empty array = rest)
    function writeEighth(track, tick, notes) {
        var cur = curScore.newCursor();
        cur.track = track;
        cur.rewindToTick(tick);
        cur.setDuration(1, 8);

        if (notes.length === 0) {
            cur.addRest();
            return;
        }

        cur.addNote(notes[0].pitch, false);

        // Add any additional notes to the chord
        for (var i = 1; i < notes.length; i++) {
            cur.rewindToTick(tick);
            cur.setDuration(1, 8);
            cur.addNote(notes[i].pitch, true);
        }

        // Restore correct pitch spelling (tpc) for all notes in the new chord
        cur.rewindToTick(tick);
        var chord = cur.element;
        if (chord && chord.notes) {
            for (var j = 0; j < chord.notes.length && j < notes.length; j++) {
                chord.notes[j].tpc1 = notes[j].tpc1;
                chord.notes[j].tpc2 = notes[j].tpc2;
            }
        }
    }

    onRun: {
        if (!curScore) {
            console.log("No score is open.");
            Qt.quit();
            return;
        }

        curScore.startCmd();

        var cursor = curScore.newCursor();
        var fullScore = false;
        var startStaff, endStaff, startTick, endTick;

        cursor.rewind(Cursor.SELECTION_START);
        if (!cursor.segment) {
            // No selection - process the whole score
            fullScore = true;
            startStaff = 0;
            endStaff = curScore.nstaves - 1;
            startTick = 0;
            endTick = curScore.lastSegment.tick + 1;
        } else {
            startStaff = cursor.staffIdx;
            startTick = cursor.tick;
            cursor.rewind(Cursor.SELECTION_END);
            endStaff = cursor.staffIdx;
            endTick = (cursor.tick === 0) ? (curScore.lastSegment.tick + 1) : cursor.tick;
            if (endStaff < startStaff) endStaff = startStaff;
        }

        var replaced = 0;

        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                var track = staff * 4 + voice;

                // Collect all notes/chords (ChordRest) in the current track, within the range
                var items = [];
                var c = curScore.newCursor();
                c.track = track;
                if (fullScore) {
                    c.rewind(Cursor.SCORE_START);
                } else {
                    c.rewindToTick(startTick);
                }

                while (c.segment && c.tick < endTick) {
                    if (c.element) {
                        var isRest = (c.element.type === Element.REST);
                        var notes = [];
                        if (!isRest && c.element.notes) {
                            for (var n = 0; n < c.element.notes.length; n++) {
                                notes.push({
                                    pitch: c.element.notes[n].pitch,
                                    tpc1: c.element.notes[n].tpc1,
                                    tpc2: c.element.notes[n].tpc2
                                });
                            }
                        }
                        items.push({
                            tick: c.tick,
                            durNum: c.element.duration.numerator,
                            durDen: c.element.duration.denominator,
                            isRest: isRest,
                            notes: notes
                        });
                    }
                    c.next();
                }

                // Find adjacent pairs: dotted eighth (3/16) directly followed by a sixteenth (1/16).
                // Since items are gathered sequentially from the same voice/track, they are by
                // definition immediately consecutive in time - no gap needs to be checked.
                for (var i = 0; i < items.length - 1; i++) {
                    var a = items[i];
                    var b = items[i + 1];

                    var aIsDottedEighth = (a.durNum === 3 && a.durDen === 16);
                    var bIsSixteenth = (b.durNum === 1 && b.durDen === 16);

                    if (aIsDottedEighth && bIsSixteenth && !a.isRest && !b.isRest) {
                        writeEighth(track, a.tick, a.notes);
                        writeEighth(track, a.tick + eighthTicks, b.notes);
                        replaced++;
                        i++; // skip past the pair we just rewrote
                    }
                }
            }
        }

        curScore.endCmd();
        console.log("Done. Number of pairs rewritten: " + replaced);
        Qt.quit();
    }
}
