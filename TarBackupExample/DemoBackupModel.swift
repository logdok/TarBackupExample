// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import Foundation
import Observation
import TarBackup

struct DemoFile: Identifiable {
    let relativePath: String
    let size: UInt64

    var id: String { relativePath }
}

enum DemoStatusTone {
    case info
    case success
    case error
}

@MainActor
@Observable
final class DemoBackupModel {
    static let exclusionPatterns = [".DS_Store", "node_modules", "**/*.tmp"]
    private static var didRegisterBackgroundTask = false

    private(set) var sourceFiles: [DemoFile] = []
    private(set) var archivedEntries: [TarEntryInfo] = []
    private(set) var archivedHistory: [TarEntryInfo] = []
    private(set) var restoredFiles: [DemoFile] = []
    private(set) var comparison: TarArchiveDiff?
    private(set) var archiveSize: UInt64 = 0
    private(set) var statusMessage = "Create the demo files to get started."
    private(set) var statusTone = DemoStatusTone.info
    private(set) var isWorking = false

    let sourceDirectoryURL: URL
    let archiveURL: URL
    let restoreDirectoryURL: URL
    let stagingDirectoryURL: URL

    var archivedVersionCount: Int { archivedHistory.count }
    var supersededVersionCount: Int {
        max(0, archivedHistory.count - archivedEntries.count)
    }

    @ObservationIgnored private let demoRootURL: URL
    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let backupManager: TarBackupManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let rootURL = applicationSupportURL.appendingPathComponent(
            "TarBackupExample",
            isDirectory: true
        )
        demoRootURL = rootURL
        sourceDirectoryURL = rootURL.appendingPathComponent("DemoFiles", isDirectory: true)
        archiveURL = rootURL.appendingPathComponent("demo-backup.tar")
        restoreDirectoryURL = rootURL.appendingPathComponent("Restored", isDirectory: true)
        stagingDirectoryURL = rootURL.appendingPathComponent("ImportCandidates", isDirectory: true)

        let manager = TarBackupManager(
            archiveURL: archiveURL,
            sourceDirectoryURL: sourceDirectoryURL
        )
        backupManager = manager
        if !Self.didRegisterBackgroundTask {
            TarCompactorScheduler.shared.registerBackgroundTask(manager: manager)
            Self.didRegisterBackgroundTask = true
        }
    }

    func loadState() {
        perform { nil }
    }

    func createDemoFiles() {
        perform {
            comparison = nil
            try createDemoFilesIfNeeded()
            return "Demo files are ready, including files used by the exclusion example."
        }
    }

    func runBackup() {
        perform {
            comparison = nil
            try createDemoFilesIfNeeded()
            try backupManager.performBackup()
            return "Incremental backup completed without exclusions."
        }
    }

    func runBackupWithExclusions() {
        perform {
            comparison = nil
            try createDemoFilesIfNeeded()
            try backupManager.performBackup(excluding: Self.exclusionPatterns)
            return "Backup completed. node_modules, .DS_Store, and *.tmp were excluded."
        }
    }

    func modifyWelcomeNote() {
        perform {
            comparison = nil
            try createDemoFilesIfNeeded()
            try appendText(
                "\nUpdated at \(Date().formatted(date: .abbreviated, time: .standard)).\n",
                to: sourceDirectoryURL.appendingPathComponent("notes/welcome.txt")
            )
            return "welcome.txt changed. Back it up to append a new stored version."
        }
    }

    func createComparisonScenario() {
        perform {
            try requireArchive()
            try createDemoFilesIfNeeded()
            try appendText(
                "\nChanged for the compare demo at \(Date().formatted()).\n",
                to: sourceDirectoryURL.appendingPathComponent("notes/welcome.txt")
            )
            try write(
                Data("This file exists only on disk until the next backup.\n".utf8),
                relativePath: "pending/new-on-disk.txt"
            )

            let removedCandidateURL = sourceDirectoryURL.appendingPathComponent("reports/weekly.csv")
            if fileManager.fileExists(atPath: removedCandidateURL.path) {
                try fileManager.removeItem(at: removedCandidateURL)
            }

            comparison = try backupManager.compareSourceDirectory(
                excluding: Self.exclusionPatterns
            )
            return "Diff scenario created and compared with the archive."
        }
    }

    func compareSourceWithArchive() {
        perform {
            comparison = try backupManager.compareSourceDirectory(
                excluding: Self.exclusionPatterns
            )
            guard let comparison else { return "Comparison completed." }
            return comparison.isInSync
                ? "Source and archive are in sync."
                : "Comparison found \(comparisonChangeCount(comparison)) changed paths."
        }
    }

    func appendOneSourceFile() {
        perform {
            comparison = nil
            try writeTimestampedFile(relativePath: "manual/source-append.txt")
            let entry = try backupManager.appendFile(named: "manual/source-append.txt")
            return "Appended \(entry.filename) directly from the source directory."
        }
    }

    func appendSourceBatch() {
        perform {
            comparison = nil
            let paths = ["manual/batch-one.txt", "manual/batch-two.txt"]
            for path in paths {
                try writeTimestampedFile(relativePath: path)
            }
            let entries = try backupManager.appendFiles(named: paths)
            return "Appended a source batch containing \(entries.count) files."
        }
    }

    func appendOneMappedFile() {
        perform {
            comparison = nil
            let fileURL = stagingDirectoryURL.appendingPathComponent("external-note.txt")
            try writeTimestampedFile(at: fileURL)
            let entry = try backupManager.appendFile(
                at: fileURL,
                as: "imports/external-note.txt"
            )
            return "Mapped an external file to \(entry.filename)."
        }
    }

    func appendMappedBatch() {
        perform {
            comparison = nil
            let firstURL = stagingDirectoryURL.appendingPathComponent("first.json")
            let secondURL = stagingDirectoryURL.appendingPathComponent("second.json")
            try writeTimestampedFile(at: firstURL)
            try writeTimestampedFile(at: secondURL)

            let entries = try backupManager.appendFiles([
                TarAppendItem(fileURL: firstURL, archivePath: "imports/batch/first.json"),
                TarAppendItem(fileURL: secondURL, archivePath: "imports/batch/second.json")
            ])
            return "Mapped and appended \(entries.count) external files in one batch."
        }
    }

    func deleteOneFile() {
        perform {
            comparison = nil
            let path = "imports/external-note.txt"
            let deleted = try backupManager.deleteFile(named: path)
            return deleted
                ? "Deleted every stored version of \(path)."
                : "Nothing to delete. Append the mapped external file first."
        }
    }

    func deleteMultipleFiles() {
        perform {
            comparison = nil
            let deleted = try backupManager.deleteFiles(named: [
                "manual/batch-one.txt",
                "manual/batch-two.txt"
            ])
            return deleted.isEmpty
                ? "Nothing to delete. Append the source batch first."
                : "Deleted \(deleted.count) archive paths and all of their versions."
        }
    }

    func repairArchive() {
        perform {
            let index = try backupManager.repairAndIndexArchive()
            return "Archive scan and tail repair completed with \(index.count) current entries."
        }
    }

    func compactArchive() {
        perform {
            comparison = nil
            try requireArchive()
            try backupManager.compactArchive()
            return "Archive compacted to one latest version per path."
        }
    }

    func scheduleBackgroundCompaction() {
        TarCompactorScheduler.shared.scheduleCompacting()
        statusTone = .info
        statusMessage = "Background compaction was requested. iOS chooses when it runs."
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
                named: ["settings/preferences.json", "media/pattern.ppm"],
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

    func resetDemo() {
        perform {
            if fileManager.fileExists(atPath: demoRootURL.path) {
                try fileManager.removeItem(at: demoRootURL)
            }
            comparison = nil
            return "The demo workspace was reset."
        }
    }

    private func perform(operation: () throws -> String?) {
        isWorking = true
        defer { isWorking = false }

        do {
            let successMessage = try operation()
            try refreshState()
            if let successMessage {
                statusTone = .success
                statusMessage = successMessage
            }
        } catch {
            statusTone = .error
            statusMessage = error.localizedDescription
        }
    }

    private func createDemoFilesIfNeeded() throws {
        try writeIfMissing(
            Data(
                """
                Welcome to the TarBackup demo.

                Modify this note, then run another backup to append a newer version.
                """.utf8
            ),
            relativePath: "notes/welcome.txt"
        )
        try writeIfMissing(
            Data(
                """
                TarBackup 1.2.0 feature checklist:
                - inspect logical contents and physical history
                - append and delete files
                - compare source files with the archive
                - extract exact paths, wildcards, and subdirectories
                """.utf8
            ),
            relativePath: "notes/feature-checklist.txt"
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
            Data("A nested report used by recursive restore examples.\n".utf8),
            relativePath: "reports/2026/summary.txt"
        )
        try writeIfMissing(makePatternImage(), relativePath: "media/pattern.ppm")
        try writeIfMissing(
            Data("Temporary output excluded by **/*.tmp.\n".utf8),
            relativePath: "build/session.tmp"
        )
        try writeIfMissing(
            Data("Dependency cache excluded by its component name.\n".utf8),
            relativePath: "node_modules/cache.js"
        )
        try writeIfMissing(
            Data("Finder metadata placeholder.\n".utf8),
            relativePath: ".DS_Store"
        )
    }

    private func writeIfMissing(_ data: Data, relativePath: String) throws {
        let fileURL = sourceDirectoryURL.appendingPathComponent(relativePath)
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }
        try write(data, to: fileURL)
    }

    private func write(_ data: Data, relativePath: String) throws {
        try write(data, to: sourceDirectoryURL.appendingPathComponent(relativePath))
    }

    private func write(_ data: Data, to fileURL: URL) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    private func writeTimestampedFile(relativePath: String) throws {
        try writeTimestampedFile(at: sourceDirectoryURL.appendingPathComponent(relativePath))
    }

    private func writeTimestampedFile(at fileURL: URL) throws {
        let contents = "TarBackup append demo generated at \(Date().formatted()).\n"
        try write(Data(contents.utf8), to: fileURL)
    }

    private func appendText(_ text: String, to fileURL: URL) throws {
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(text.utf8))
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
        archivedHistory = try backupManager.listContents(includingSupersededVersions: true)
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

    private func comparisonChangeCount(_ difference: TarArchiveDiff) -> Int {
        difference.added.count + difference.modified.count + difference.removed.count
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

        let normalizedRootPath = rootURL.standardizedFileURL.resolvingSymlinksInPath().path + "/"
        var files: [DemoFile] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true else { continue }

            let normalizedPath = fileURL.standardizedFileURL.resolvingSymlinksInPath().path
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
        "Run an incremental backup before using this operation."
    }
}
