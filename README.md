# MuseScore Plugins

A collection of QML plugins for MuseScore Studio 4.x.

## Plugins

- [`dotted-eighth-to-eighths`](plugins/dotted-eighth-to-eighths/) — rewrites
  every dotted eighth + sixteenth note pair into two straight eighth notes,
  within the selection or across the whole score.

## Structure

```
musescore-plugins/
├── README.md
└── plugins/
    └── dotted-eighth-to-eighths/
        ├── RewriteDottedEighthSixteenth.qml
        └── README.md
```

Each plugin lives in its own subfolder under `plugins/`, with its `.qml`
file and a short README describing what it does and how to install it.
This keeps the repo easy to extend as more plugins are added.
