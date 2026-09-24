// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import Foundation
import Observation
import TarBackup

struct DemoFile: Identifiable {
    let relativePath: String
    let size: UInt64

    var id: String { relativePath }
}

@MainActor
@Observable
final class DemoBackupModel {
    private(set) var sourceFiles: [DemoFile] = []
    private(set) var archivedEntries: [TarEntryInfo] = []
    private(set) var archiveSize: UInt64 = 0
    private(set) var statusMessage = "Create the demo files to get started."
    private(set) var isWorking = false

    let sourceDirectoryURL: URL
    let archiveURL: URL

    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let backupManager: TarBackupManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let demoRootURL = applicationSupportURL.appendingPathComponent(
            "TarBackupExample",
            isDirectory: true
        )

        sourceDirectoryURL = demoRootURL.appendingPathComponent("DemoFiles", isDirectory: true)
        archiveURL = demoRootURL.appendingPathComponent("demo-backup.tar")
        backupManager = TarBackupManager(
            archiveURL: archiveURL,
            sourceDirectoryURL: sourceDirectoryURL
        )
    }

    func loadState() {
        perform(successMessage: nil) {}
    }

    func createDemoFiles() {
        perform(successMessage: "Demo files are ready.") {
            try createDemoFilesIfNeeded()
        }
    }

    func runBackup() {
        perform(successMessage: "Incremental backup completed.") {
            try createDemoFilesIfNeeded()
            try backupManager.performBackup()
        }
    }

    func modifyWelcomeNote() {
        perform(successMessage: "welcome.txt changed. Run backup again to append its new version.") {
            try createDemoFilesIfNeeded()

            let noteURL = sourceDirectoryURL.appendingPathComponent("notes/welcome.txt")
            let handle = try FileHandle(forWritingTo: noteURL)
            defer { try? handle.close() }
            try handle.seekToEnd()

            let update = "\nUpdated at \(Date().formatted(date: .abbreviated, time: .standard)).\n"
            try handle.write(contentsOf: Data(update.utf8))
        }
    }

    func compactArchive() {
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            statusMessage = "Run a backup before compacting the archive."
            return
        }

        perform(successMessage: "Archive compacted to the latest file versions.") {
            try backupManager.compactArchive()
        }
    }

    private func perform(successMessage: String?, operation: () throws -> Void) {
        isWorking = true
        defer { isWorking = false }

        do {
            try operation()
            try refreshState()
            if let successMessage {
                statusMessage = successMessage
            }
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func createDemoFilesIfNeeded() throws {
        try fileManager.createDirectory(
            at: sourceDirectoryURL,
            withIntermediateDirectories: true
        )

        try writeIfMissing(
            Data(
                """
                Welcome to the TarBackup demo.

                Edit this file with the button in the app, then run another backup.
                TarBackup will append the newer version to the existing archive.
                """.utf8
            ),
            relativePath: "notes/welcome.txt"
        )

        try writeIfMissing(
            Data(
                """
                {
                  "theme": "indigo",
                  "automaticBackup": true,
                  "maximumArchiveSizeMB": 50
                }
                """.utf8
            ),
            relativePath: "settings/preferences.json"
        )

        try writeIfMissing(
            Data(
                """
                day,documents,bytes
                Monday,3,12480
                Tuesday,5,28672
                Wednesday,2,8192
                """.utf8
            ),
            relativePath: "reports/weekly.csv"
        )

        try writeIfMissing(makePatternImage(), relativePath: "media/pattern.ppm")
    }

    private func writeIfMissing(_ data: Data, relativePath: String) throws {
        let fileURL = sourceDirectoryURL.appendingPathComponent(relativePath)
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }

        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    private func makePatternImage() -> Data {
        let width = 64
        let height = 64
        var data = Data("P6\n\(width) \(height)\n255\n".utf8)

        for y in 0..<height {
            for x in 0..<width {
                data.append(UInt8((x * 4) % 256))
                data.append(UInt8((y * 4) % 256))
                data.append(UInt8(((x + y) * 2) % 256))
            }
        }

        return data
    }

    private func refreshState() throws {
        sourceFiles = try scanSourceFiles()
        archivedEntries = try backupManager.repairAndIndexArchive()
            .values
            .sorted { $0.filename < $1.filename }

        guard fileManager.fileExists(atPath: archiveURL.path) else {
            archiveSize = 0
            return
        }

        let attributes = try fileManager.attributesOfItem(atPath: archiveURL.path)
        archiveSize = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
    }

    private func scanSourceFiles() throws -> [DemoFile] {
        guard fileManager.fileExists(atPath: sourceDirectoryURL.path),
              let enumerator = fileManager.enumerator(
                at: sourceDirectoryURL,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let normalizedRootPath = sourceDirectoryURL
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path + "/"
        var files: [DemoFile] = []

        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true else { continue }

            let normalizedPath = fileURL
                .standardizedFileURL
                .resolvingSymlinksInPath()
                .path
            guard normalizedPath.hasPrefix(normalizedRootPath) else { continue }

            files.append(
                DemoFile(
                    relativePath: String(normalizedPath.dropFirst(normalizedRootPath.count)),
                    size: UInt64(values.fileSize ?? 0)
                )
            )
        }

        return files.sorted { $0.relativePath < $1.relativePath }
    }
}
