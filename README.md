# TarBackupExample

TarBackupExample is a small iOS 17 SwiftUI application that demonstrates how
to create incremental POSIX TAR backups with the
[TarBackup Swift package](https://github.com/logdok/TarBackup).

The example uses TarBackup `1.0.0` directly from GitHub and shows the complete
workflow without additional dependencies.

## Features

- Generates sample files in the application's sandbox.
- Creates an incremental TAR archive.
- Appends a new file version after the source file changes.
- Displays the source files and current archive index.
- Compacts the archive so that only the latest file versions remain.
- Uses the iOS 17 Observation framework with SwiftUI.

## Demo files

The app creates four sample files inside its Application Support directory:

- `notes/welcome.txt`
- `settings/preferences.json`
- `reports/weekly.csv`
- `media/pattern.ppm`

## Try the backup workflow

1. Select **Create Demo Files**.
2. Select **Run Incremental Backup** to create `demo-backup.tar`.
3. Select **Modify Welcome Note**.
4. Run the incremental backup again to append the updated file.
5. Select **Compact Archive** to remove the obsolete file version.

The screen displays file counts, archive size, modification dates, and the
locations of both the source directory and TAR archive.

## Requirements

- iOS 17 or later
- Xcode 16 or later
- Swift 5.9 or later

## Running the example

Open `TarBackupExample.xcodeproj`, select an iOS Simulator, and run the
`TarBackupExample` scheme.

The project can also be regenerated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
open TarBackupExample.xcodeproj
```

## TarBackup package

Package repository: [github.com/logdok/TarBackup](https://github.com/logdok/TarBackup)

The dependency is declared in `project.yml`:

```yaml
packages:
  TarBackup:
    url: https://github.com/logdok/TarBackup.git
    from: 1.0.0
```

## License

TarBackupExample is available under the MIT License. See `LICENSE` for details.
