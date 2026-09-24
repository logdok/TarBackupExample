# TarBackupExample

TarBackupExample is an iOS 17 SwiftUI application that demonstrates the complete public workflow of the [TarBackup Swift package](https://github.com/logdok/TarBackup).

The app uses TarBackup `1.2.0`, Foundation, SwiftUI, and the Observation framework. It creates a real TAR archive inside its sandbox and exposes every operation through an interactive interface.

## What the example demonstrates

### Backup and exclusions

- Create a sample source tree with documents, reports, settings, media, temporary output, and dependency files.
- Run an incremental backup with `performBackup()`.
- Run a filtered backup with `performBackup(excluding:)`.
- Exclude `.DS_Store`, `node_modules`, and files matching `**/*.tmp`.
- Modify a source file and append its new version with another incremental backup.

### Direct append

- Append one source-directory file with `appendFile(named:)`.
- Append several source-directory files with `appendFiles(named:)`.
- Map an arbitrary file to a custom archive path with `appendFile(at:as:)`.
- Append a batch of `TarAppendItem` values without repacking existing entries.

### Inspection and comparison

- Browse current logical contents with `listContents()`.
- Browse every physical version with `listContents(includingSupersededVersions: true)`.
- Inspect each entry's name, size, offset, and modification date.
- Compare the source directory with the archive using `compareSourceDirectory(excluding:)`.
- Display added, modified, removed, and unchanged paths.

### Restore

- Extract one exact file with `extractFile(named:to:)`.
- Extract multiple explicit paths with `extractFiles(named:to:)`.
- Extract recursively with the `**/*.txt` wildcard.
- Restore the complete `reports/` subdirectory.
- Review and clear restored output from the app.

### Archive editing and maintenance

- Delete one archive path with `deleteFile(named:)`.
- Delete several archive paths with `deleteFiles(named:)`.
- Validate and repair an incomplete archive tail with `repairAndIndexArchive()`.
- Compact the archive immediately with `compactArchive()`.
- Register and request background compaction with `TarCompactorScheduler`.

## Interface

The app is organized into four tabs:

1. **Overview** — package summary, live archive metrics, a guided workflow, and sandbox locations.
2. **Operations** — backup, compare, append, delete, repair, and compaction actions.
3. **Archive** — logical contents, physical history, metadata, and comparison results.
4. **Restore** — exact, batch, wildcard, and subdirectory extraction.

Every operation reports a success, information, or error status. The archive counters and file lists refresh after each action.

## Suggested workflow

1. Open **Overview** and create the sample workspace.
2. Run **Back up with exclusions**.
3. Modify the welcome note and back up again.
4. Open **Archive** and switch from **Current** to **History** to see both versions.
5. In **Operations**, create a diff scenario and inspect its categories in **Archive**.
6. Try all four direct append actions, then delete the single mapped file and source batch.
7. Open **Restore** and try each selection method.
8. Compact the archive and confirm that superseded versions disappear.

## Requirements

- iOS 17 or later
- Xcode 16 or later
- Swift 5.9 or later

## Running the example

Open `TarBackupExample.xcodeproj`, select an iOS Simulator, and run the `TarBackupExample` scheme.

The project can also be regenerated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
open TarBackupExample.xcodeproj
```

The dependency is declared in `project.yml`:

```yaml
packages:
  TarBackup:
    url: https://github.com/logdok/TarBackup.git
    from: 1.2.0
```

The example application's version remains `1.1.0`.

## License

TarBackupExample is available under the MIT License. See [LICENSE](LICENSE).
