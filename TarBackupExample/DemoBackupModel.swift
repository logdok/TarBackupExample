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
    private(set) var archivedVersionCount = 0
    private(set) var restoredFiles: [DemoFile] = []
    private(set) var archiveSize: UInt64 = 0
    private(set) var statusMessage = "Create the demo files to get started."
    private(set) var isWorking = false

    let sourceDirectoryURL: URL
    let archiveURL: URL
    let restoreDirectoryURL: URL

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
        restoreDirectoryURL = demoRootURL.appendingPathComponent("Restored", isDirectory: true)
        backupManager = TarBackupManager(
            archiveURL: archiveURL,
            sourceDirectoryURL: sourceDirectoryURL
        )
    }

    func loadState() {
        perform { nil }
    }

    func createDemoFiles() {
        perform {
            try createDemoFilesIfNeeded()
            return "Demo files are ready."
        }
    }

    func runBackup() {
        perform {
            try createDemoFilesIfNeeded()
            try backupManager.performBackup()
            return "Incremental backup completed."
        }
    }

    func modifyWelcomeNote() {
        perform {
            try createDemoFilesIfNeeded()

            let noteURL = sourceDirectoryURL.appendingPathComponent("notes/welcome.txt")
            let handle = try FileHandle(forWritingTo: noteURL)
            defer { try? handle.close() }
            try handle.seekToEnd()

            let update = "\nUpdated at \(Date().formatted(date: .abbreviated, time: .standard)).\n"
            try handle.write(contentsOf: Data(update.utf8))
            return "welcome.txt changed. Run backup again to append its new version."
        }
    }

    func compactArchive() {
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            statusMessage = "Run a backup before compacting the archive."
            return
        }

        perform {
            try backupManager.compactArchive()
            return "Archive compacted to the latest file versions."
        }
    }

    func extractOneFile() {
        perform {
            try requireArchive()
            let destinationURL = restoreDirectoryURL.appendingPathComponent("OneFile", isDirectory: true)
            _ = try backupManager.extractFile(
                named: "notes/welcome.txt",
                to: destinationURL
            )
            return "Extracted notes/welcome.txt."
        }
    }

    func extractMultipleFiles() {
        perform {
            try requireArchive()
            let destinationURL = restoreDirectoryURL.appendingPathComponent("NamedFiles", isDirectory: true)
            let urls = try backupManager.extractFiles(
                named: [
                    "settings/preferences.json",
                    "media/pattern.ppm"
                ],
                to: destinationURL
            )
            return "Extracted \(urls.count) explicitly named files."
        }
    }

    func extractTextFilesWithWildcard() {
        perform {
            try requireArchive()
            let destinationURL = restoreDirectoryURL.appendingPathComponent("Wildcard", isDirectory: true)
            let urls = try backupManager.extract(
                matching: "**/*.txt",
                to: destinationURL
            )
            return "Wildcard **/*.txt extracted \(urls.count) files."
        }
    }

    func extractReportsSubdirectory() {
        perform {
            try requireArchive()
            let destinationURL = restoreDirectoryURL.appendingPathComponent("Subdirectory", isDirectory: true)
            let urls = try backupManager.extractSubdirectory(
                "reports",
                to: destinationURL
            )
            return "Extracted the reports subdirectory with \(urls.count) files."
        }
    }

    func clearRestoredFiles() {
        perform {
            if fileManager.fileExists(atPath: restoreDirectoryURL.path) {
                try fileManager.removeItem(at: restoreDirectoryURL)
            }
            return "Restored demo files removed."
        }
    }

    private func perform(operation: () throws -> String?) {
        isWorking = true
        defer { isWorking = false }

        do {
            let successMessage = try operation()
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
                TarBackup 1.1.0 restore checklist:
                - inspect the archive
                - extract exact files
                - try a wildcard
                - restore a complete subdirectory
                """.utf8
            ),
            relativePath: "notes/restore-checklist.txt"
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

        try writeIfMissing(
            Data(
                """
                This nested report demonstrates recursive wildcard and subdirectory extraction.
                """.utf8
            ),
            relativePath: "reports/2026/summary.txt"
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
        sourceFiles = try scanFiles(in: sourceDirectoryURL)
        archivedEntries = try backupManager.listContents()
        archivedVersionCount = try backupManager
            .listContents(includingSupersededVersions: true)
            .count
        restoredFiles = try scanFiles(in: restoreDirectoryURL)

        guard fileManager.fileExists(atPath: archiveURL.path) else {
            archiveSize = 0
            return
        }

        let attributes = try fileManager.attributesOfItem(atPath: archiveURL.path)
        archiveSize = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
    }

    private func requireArchive() throws {
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            throw DemoBackupError.archiveMissing
        }
    }

    private func scanFiles(in rootURL: URL) throws -> [DemoFile] {
        guard fileManager.fileExists(atPath: rootURL.path),
              let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        let normalizedRootPath = rootURL
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

private enum DemoBackupError: LocalizedError {
    case archiveMissing

    var errorDescription: String? {
        "Run an incremental backup before trying extraction."
    }
}
