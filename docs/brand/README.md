# Brand assets

Two files belong here. Neither is in the repository yet, so save them from
wherever you keep them, under exactly these names:

| File | What it is |
|---|---|
| `wordmark.png` | The "ToDoTrip" lettering, teal on a transparent background. |
| `icon.png` | The 512×512 app icon: a white T on the brand teal. |

## Turning the wordmark on in the README

The repository README opens with a plain `<h1>TodoTrip</h1>`, so that it does
not show a broken image while these files are missing. Once `wordmark.png` is
here, replace that heading with:

```html
<p align="center">
  <img src="docs/brand/wordmark.png" alt="TodoTrip" width="320">
</p>
```

The same snippet is left as a comment at the top of the README.

## The app icon

`icon.png` is what a launcher icon would be generated from. The app still ships
Flutter's default; replacing it needs the `flutter_launcher_icons` package and
one entry in `pubspec.yaml` — a dependency nobody has agreed to yet.
