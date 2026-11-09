# Daymark — Study Tasks

Daymark is a responsive Flutter web task manager for students. Add, edit, complete, filter, and remove tasks. Tasks are stored locally in the browser, so no sign-in or backend is needed.

## Run locally

```sh
flutter pub get
flutter run -d chrome
```

## Build for web hosting

```sh
flutter build web --release
```

The deployable static site is written to `build/web/`. It can be served by any static web host. Browser storage belongs to the browser and device used to access the app.

## Concepts demonstrated

- Material 3 theme and reusable task, progress, and statistic widgets
- Responsive dashboard layout for phone, tablet, and desktop widths
- Navigator route transition between dashboard and validated task form
- Stateful form input and Provider/ChangeNotifier task state
- Animated task completion and list filter transitions
- `ListView`, `Row`, `Column`, `Stack`, `Card`-style containers, buttons, and `LayoutBuilder`
- Browser-local persistence through `shared_preferences`

## Documentation and screenshots

The examination report and captured UI screenshots are in `documentation/` and `screenshots/`.
