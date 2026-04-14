# Contributing

Thanks for contributing to `bee_dynamic_launcher`.

## Local setup

1. Install Flutter stable.
2. Clone the repository.
3. Run:

```bash
flutter pub get
```

## Development workflow

Before opening a pull request, run:

```bash
flutter analyze
flutter test
flutter pub publish --dry-run
```

## Pull request guidelines

- Keep changes scoped to one concern.
- Add or update tests when behavior changes.
- Update `README.md` and `CHANGELOG.md` for user-facing changes.
- Avoid unrelated formatting-only diffs.

## Reporting issues

Use GitHub issue templates and include:
- Flutter/Dart versions
- Platform details
- Repro steps
- Relevant logs
