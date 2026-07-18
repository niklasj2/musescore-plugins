import QtQuick 2.9
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import MuseScore 3.0

MuseScore {
    id: root
    version: "1.0"
    description: "Swing Rhythm Converter: Straight / Dotted / Triplet. Converts quarter-beat rhythms (straight eighths, dotted eighth+sixteenth, or triplet swing) into whichever of the three you choose, within the selection or across the whole score if nothing is selected."
    title: "Swing Rhythm Converter"
    categoryCode: "composing-arranging-tools"
    requiresScore: true
    pluginType: "dialog"
    width: 420
    height: 330

    // Pattern codes: 0 = straight eighths, 1 = dotted eighth + sixteenth, 2 = triplet swing
    property int targetPattern: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Label {
            text: "Convert quarter-beat rhythms to:"
            font.bold: true
        }

        ButtonGroup { id: patternGroup }

        RadioButton {
            text: "Straight eighths (1:1)"
            checked: true
            ButtonGroup.group: patternGroup
            onCheckedChanged: if (checked) targetPattern = 0
        }
        RadioButton {
            text: "Dotted eighth + sixteenth (3:1)"
            ButtonGroup.group: patternGroup
            onCheckedChanged: if (checked) targetPattern = 1
        }
        RadioButton {
            text: "Triplet swing: quarter + eighth (2:1)"
            ButtonGroup.group: patternGroup
            onCheckedChanged: if (checked) targetPattern = 2
        }

        Label {
            text: "Only pairs where both notes are actual notes (not rests) are converted."
            font.pixelSize: 11
            opacity: 0.7
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            id: errorLabel
            text: ""
            color: "#c0392b"
            visible: text.length > 0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            Button {
                text: "Cancel"
                onClicked: closePlugin()
            }
            Button {
                text: "Convert"
                onClicked: {
                    try {
                        runConversion(targetPattern);
                        closePlugin();
                    } catch (e) {
                        console.log("Rhythm Converter error: " + e);
                        errorLabel.text = "Error: " + e;
                    }
                }
            }
        }
    }

    // Closes the dialog window without using Qt.quit()/quit(), which are
    // unreliable in MuseScore 4 (Qt.quit() can silently do nothing, or in
    // some cases crash the whole application instead of just the plugin).
    function closePlugin() {
        root.parent.Window.window.close();
    }

    // Ticks per quarter note, read from the score
    property int division_: 480

    function ticksOf(num, den) {
        // Nominal tick length of a plain (non-tuplet) duration num/den (fraction of a whole note)
        return Math.round(division_ * 4 * num / den);
    }

    // Writes a single chord/rest at "tick" with the given nominal duration num/den.
    // Used for the non-tuplet patterns (straight, dotted).
    function placeChord(track, tick, num, den, notes) {
        var cur = curScore.newCursor();
        cur.track = track;
        cur.rewindToTick(tick);
        cur.setDuration(num, den);

        if (notes.length === 0) {
            cur.addRest();
            return;
        }

        cur.addNote(notes[0].pitch, false);
        for (var i = 1; i < notes.length; i++) {
            cur.rewindToTick(tick);
            cur.setDuration(num, den);
            cur.addNote(notes[i].pitch, true);
        }

        cur.rewindToTick(tick);
        var chord = cur.element;
        if (chord && chord.notes) {
            for (var j = 0; j < chord.notes.length && j < notes.length; j++) {
                chord.notes[j].tpc1 = notes[j].tpc1;
                chord.notes[j].tpc2 = notes[j].tpc2;
            }
        }
    }

    // Writes the triplet-swing pattern (a quarter-note-triplet + eighth-note-triplet,
    // 2:1, spanning one quarter beat) at "tick", per standard notation convention.
    function placeSwing(track, tick, longNotes, shortNotes) {
        var cur = curScore.newCursor();
        cur.track = track;
        cur.rewindToTick(tick);
        // Creates an eighth-note-triplet (3-in-2) frame spanning one quarter beat.
        // The second argument is the tuplet's TOTAL time span (one quarter note),
        // not the duration of each individual note - see MuseScore's own example:
        // cursor.addTuplet(fraction(3, 2), fraction(1, 4)); // triplet of 3 eighths
        cur.addTuplet(fraction(3, 2), fraction(1, 4));

        // Long note: occupies 2 of the 3 triplet slots (quarter-note-triplet notehead)
        cur.setDuration(1, 4);
        if (longNotes.length === 0) {
            cur.addRest();
        } else {
            cur.addNote(longNotes[0].pitch, false);
            for (var i = 1; i < longNotes.length; i++) {
                cur.addNote(longNotes[i].pitch, true);
            }
        }

        // Short note: the remaining slot (eighth-note-triplet notehead)
        cur.setDuration(1, 8);
        if (shortNotes.length === 0) {
            cur.addRest();
        } else {
            cur.addNote(shortNotes[0].pitch, false);
            for (var j = 1; j < shortNotes.length; j++) {
                cur.addNote(shortNotes[j].pitch, true);
            }
        }

        // Restore correct pitch spelling (tpc) for both notes
        cur.rewindToTick(tick);
        if (cur.element && cur.element.notes) {
            for (var k = 0; k < cur.element.notes.length && k < longNotes.length; k++) {
                cur.element.notes[k].tpc1 = longNotes[k].tpc1;
                cur.element.notes[k].tpc2 = longNotes[k].tpc2;
            }
        }
        var shortTick = tick + Math.round(2 * division_ / 3);
        cur.rewindToTick(shortTick);
        if (cur.element && cur.element.notes) {
            for (var m = 0; m < cur.element.notes.length && m < shortNotes.length; m++) {
                cur.element.notes[m].tpc1 = shortNotes[m].tpc1;
                cur.element.notes[m].tpc2 = shortNotes[m].tpc2;
            }
        }
    }

    // Clears an existing tuplet spanning one quarter beat at "tick". The key detail
    // (confirmed via a real published plugin's source, "New Retrograde"): you must
    // call removeElement() on the tuplet object itself (element.tuplet), not on the
    // note/rest element - removing the element alone leaves the tuplet framing intact.
    function clearTupletSpan(track, tick) {
        var cur = curScore.newCursor();
        cur.track = track;
        cur.rewindToTick(tick);
        if (cur.element && cur.element.tuplet) {
            removeElement(cur.element.tuplet);
        }
    }

    function writePattern(pattern, track, tick, firstNotes, secondNotes) {
        if (pattern === 0) {
            placeChord(track, tick, 1, 8, firstNotes);
            placeChord(track, tick + ticksOf(1, 8), 1, 8, secondNotes);
        } else if (pattern === 1) {
            placeChord(track, tick, 3, 16, firstNotes);
            placeChord(track, tick + ticksOf(3, 16), 1, 16, secondNotes);
        } else if (pattern === 2) {
            placeSwing(track, tick, firstNotes, secondNotes);
        }
    }

    // Identifies the quarter-note-triplet + eighth-note-triplet swing figure: a
    // quarter-note-triplet (occupying 2 of 3 slots as a single element) followed by
    // an eighth-note-triplet. Note: we deliberately don't compare a.tuplet === b.tuplet
    // by object identity - the "tuplet" property appears to return a fresh QML wrapper
    // object on each read, so such a comparison is always false even for the same
    // underlying tuplet. Truthy tuplet + matching nominal durations is a reliable
    // enough signature for two adjacent items in the same voice.
    function isSwingPair(a, b) {
        if (a.isRest || b.isRest) return false;
        if (!a.tuplet || !b.tuplet) return false;
        return (a.durNum === 1 && a.durDen === 4 && b.durNum === 1 && b.durDen === 8);
    }

    // Identifies straight (0) or dotted (1) pairs. Returns -1 if no match.
    function detectPairPattern(a, b) {
        if (a.isRest || b.isRest) return -1;
        if (a.tuplet || b.tuplet) return -1;
        if (a.durNum === 1 && a.durDen === 8 && b.durNum === 1 && b.durDen === 8) return 0;
        if (a.durNum === 3 && a.durDen === 16 && b.durNum === 1 && b.durDen === 16) return 1;
        return -1;
    }

    function runConversion(target) {
        if (!curScore) {
            console.log("No score is open.");
            return;
        }

        division_ = (typeof division !== 'undefined' && division) ? division : (curScore.division || 480);
        curScore.startCmd();

        try {

        var cursor = curScore.newCursor();
        var fullScore = false;
        var startStaff, endStaff, startTick, endTick;

        cursor.rewind(Cursor.SELECTION_START);
        if (!cursor.segment) {
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
                            tuplet: c.element.tuplet,
                            notes: notes
                        });
                    }
                    c.next();
                }

                for (var i = 0; i < items.length; i++) {
                    if (i + 1 < items.length && isSwingPair(items[i], items[i + 1])) {
                        if (target !== 2) {
                            clearTupletSpan(track, items[i].tick);
                            writePattern(target, track, items[i].tick, items[i].notes, items[i + 1].notes);
                            replaced++;
                        }
                        i += 1;
                        continue;
                    }
                    if (i + 1 < items.length) {
                        var pairPattern = detectPairPattern(items[i], items[i + 1]);
                        if (pairPattern !== -1 && pairPattern !== target) {
                            writePattern(target, track, items[i].tick, items[i].notes, items[i + 1].notes);
                            replaced++;
                            i += 1;
                        }
                    }
                }
            }
        }

        console.log("Done. Number of pairs rewritten: " + replaced);

        } finally {
            curScore.endCmd();
        }

        // Restore the original selection, since running the plugin otherwise leaves
        // the selection wherever the last write operation happened to land it - which
        // makes it awkward to immediately re-run the plugin with a different target
        // over the same region.
        if (!fullScore) {
            curScore.startCmd();
            curScore.selection.selectRange(startTick, endTick, startStaff, endStaff + 1);
            curScore.endCmd();
        }
    }
}
