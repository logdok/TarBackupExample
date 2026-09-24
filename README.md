# TarBackupExample

TarBackupExample is a small iOS 17 SwiftUI application that demonstrates how
to create incremental POSIX TAR backups with the
[TarBackup Swift package](https://github.com/logdok/TarBackup).

The example uses TarBackup `1.1.0` directly from GitHub and shows the complete
workflow without additional dependencies.

## Features

- Generates sample files in the application's sandbox.
- Creates an incremental TAR archive.
- Appends a new file version after the source file changes.
- Lists the current archive contents and the total number of stored versions.
- Extracts one explicitly named file.
- Extracts several explicitly named files in one operation.
- Extracts matching files with the recursive `**/*.txt` wildcard.
- Restores the complete `reports/` archive subdirectory.
- Displays every restored file and its destination path.
- Compacts the archive so that only the latest file versions remain.
- Uses the iOS 17 Observation framework with SwiftUI.

## Demo files

The app creates six sample files inside its Application Support directory:

- `notes/welcome.txt`
- `notes/restore-checklist.txt`
- `settings/preferences.json`
- `reports/weekly.csv`
- `reports/2026/summary.txt`
- `media/pattern.ppm`

## Try the backup workflow

1. Select **Create Demo Files**.
2. Select **Run Incremental Backup** to create `demo-backup.tar`.
3. Select **Modify Welcome Note**.
4. Run the incremental backup again to append the updated file.
5. Select **Compact Archive** to remove the obsolete file version.

## Try the restore workflow

After creating a backup, use the **TarBackup 1.1.0 Restore** actions:

1. **Extract One File** restores `notes/welcome.txt`.
2. **Extract Named Files** restores `settings/preferences.json` and
   `media/pattern.ppm` in one call.
3. **Extract with Wildcard** (`**/*.txt`) demonstrates recursive wildcard extraction.
4. **Extract `reports/`** restores the complete reports subtree, including its
   nested `2026` directory.
5. **Clear Restored Files** resets the restore output so the workflow can be
   repeated.

Each operation writes to its own directory below `Restored`, making its result
easy to inspect. The application uses `listContents()` for the current archive
view and `listContents(includingSupersededVersions: true)` for the stored-version
counter.

The screen displays source, archive, and restored file counts; archive size;
modification dates; and the locations of the source, archive, and restore
directories.

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
    from: 1.1.0
```

## License

TarBackupExample is available under the MIT License. See `LICENSE` for details.
