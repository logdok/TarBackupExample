// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI

struct ContentView: View {
    @State private var model = DemoBackupModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(model.statusMessage, systemImage: "info.circle.fill")
                        .foregroundStyle(.indigo)
                }

                Section("Actions") {
                    Button {
                        model.createDemoFiles()
                    } label: {
                        Label("Create Demo Files", systemImage: "doc.badge.plus")
                    }

                    Button {
                        model.runBackup()
                    } label: {
                        Label("Run Incremental Backup", systemImage: "archivebox.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        model.modifyWelcomeNote()
                    } label: {
                        Label("Modify Welcome Note", systemImage: "pencil")
                    }

                    Button {
                        model.compactArchive()
                    } label: {
                        Label("Compact Archive", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(model.isWorking)

                Section("TarBackup 1.1.0 Restore") {
                    Button {
                        model.extractOneFile()
                    } label: {
                        Label("Extract One File", systemImage: "doc")
                    }

                    Button {
                        model.extractMultipleFiles()
                    } label: {
                        Label("Extract Named Files", systemImage: "doc.on.doc")
                    }

                    Button {
                        model.extractTextFilesWithWildcard()
                    } label: {
                        Label("Extract **/*.txt", systemImage: "asterisk")
                    }

                    Button {
                        model.extractReportsSubdirectory()
                    } label: {
                        Label("Extract reports/", systemImage: "folder")
                    }

                    Button(role: .destructive) {
                        model.clearRestoredFiles()
                    } label: {
                        Label("Clear Restored Files", systemImage: "trash")
                    }
                    .disabled(model.restoredFiles.isEmpty)
                }
                .disabled(model.isWorking)

                Section("Summary") {
                    LabeledContent("Source files", value: "\(model.sourceFiles.count)")
                    LabeledContent("Current archive entries", value: "\(model.archivedEntries.count)")
                    LabeledContent("Stored entry versions", value: "\(model.archivedVersionCount)")
                    LabeledContent("Restored files", value: "\(model.restoredFiles.count)")
                    LabeledContent("Archive size", value: formattedSize(model.archiveSize))
                }

                Section("Demo Files") {
                    if model.sourceFiles.isEmpty {
                        ContentUnavailableView(
                            "No Demo Files",
                            systemImage: "doc",
                            description: Text("Tap Create Demo Files to generate sample content.")
                        )
                    } else {
                        ForEach(model.sourceFiles) { file in
                            fileRow(name: file.relativePath, size: file.size)
                        }
                    }
                }

                Section("Archive Contents") {
                    if model.archivedEntries.isEmpty {
                        ContentUnavailableView(
                            "Archive Is Empty",
                            systemImage: "archivebox",
                            description: Text("Run the backup to add the demo files.")
                        )
                    } else {
                        ForEach(model.archivedEntries, id: \.filename) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.filename)
                                    .font(.body.monospaced())
                                Text("\(formattedSize(entry.size)) · \(entry.modificationDate.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Restored Files") {
                    if model.restoredFiles.isEmpty {
                        ContentUnavailableView(
                            "Nothing Restored Yet",
                            systemImage: "arrow.down.doc",
                            description: Text("Use a TarBackup 1.1.0 restore action above.")
                        )
                    } else {
                        ForEach(model.restoredFiles) { file in
                            fileRow(name: file.relativePath, size: file.size)
                        }
                    }
                }

                Section("Locations") {
                    pathRow(title: "Source", url: model.sourceDirectoryURL)
                    pathRow(title: "Archive", url: model.archiveURL)
                    pathRow(title: "Restored", url: model.restoreDirectoryURL)
                }
            }
            .navigationTitle("TarBackup Demo")
            .task {
                model.loadState()
            }
        }
    }

    private func fileRow(name: String, size: UInt64) -> some View {
        HStack {
            Text(name)
                .font(.body.monospaced())
            Spacer()
            Text(formattedSize(size))
                .foregroundStyle(.secondary)
        }
    }

    private func pathRow(title: String, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(url.path)
                .font(.caption2.monospaced())
                .textSelection(.enabled)
        }
    }

    private func formattedSize(_ size: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

#Preview {
    ContentView()
}
