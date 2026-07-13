# MuseScore Plugins

A collection of QML plugins for MuseScore Studio 4.x.

## Plugins

- [`swing-rhythm-converter`](plugins/swing-rhythm-converter/) — converts
  quarter-beat rhythms between straight eighths, dotted eighth+sixteenth,
  and triplet swing, within the selection or across the whole score.
  **(Beta - see the plugin's own README for known limitations.)**

## Structure

```
musescore-plugins/
├── README.md
└── plugins/
    └── swing-rhythm-converter/
        ├── SwingRhythmConverter.qml
        └── README.md
```

Each plugin lives in its own subfolder under `plugins/`, with its `.qml`
file and a short README describing what it does and how to install it.
This keeps the repo easy to extend as more plugins are added.
