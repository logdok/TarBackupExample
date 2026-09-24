// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI

struct RestoreView: View {
    let model: DemoBackupModel

    var body: some View {
        NavigationStack {
            DemoScreen(model: model) {
                DemoSection(
                    "Selective restore",
                    subtitle: "Each action writes to a separate destination below Restored."
                ) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 155), spacing: 10)],
                        spacing: 10
                    ) {
                        DemoActionButton(
                            title: "One exact file",
                            subtitle: "notes/welcome.txt",
                            systemImage: "doc",
                            action: model.extractOneFile
                        )
                        DemoActionButton(
                            title: "Named files",
                            subtitle: "Restore two explicit paths.",
                            systemImage: "doc.on.doc",
                            action: model.extractMultipleFiles
                        )
                        DemoActionButton(
                            title: "Wildcard",
                            subtitle: "Match **/*.txt recursively.",
                            systemImage: "asterisk",
                            tint: .purple,
                            action: model.extractTextFilesWithWildcard
                        )
                        DemoActionButton(
                            title: "Subdirectory",
                            subtitle: "Restore everything below reports/.",
                            systemImage: "folder",
                            tint: .orange,
                            action: model.extractReportsSubdirectory
                        )
                    }
                }

                DemoSection(
                    "Restored output",
                    subtitle: "\(model.restoredFiles.count) files currently exist in the restore workspace."
                ) {
                    if model.restoredFiles.isEmpty {
                        ContentUnavailableView(
                            "Nothing restored yet",
                            systemImage: "arrow.down.doc",
                            description: Text("Create a backup, then choose a restore action above.")
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(model.restoredFiles.enumerated()), id: \.element.id) { index, file in
                                DemoFileRow(name: file.relativePath, size: file.size)
                                if index < model.restoredFiles.count - 1 {
                                    Divider()
                                }
                            }
                        }

                        DemoActionButton(
                            title: "Clear restored output",
                            subtitle: "Keep the source and archive unchanged.",
                            systemImage: "trash",
                            role: .destructive,
                            action: model.clearRestoredFiles
                        )
                    }
                }

                DemoSection(
                    "Destination",
                    subtitle: "The archive paths are preserved below this directory."
                ) {
                    Text(model.restoreDirectoryURL.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Restore")
        }
    }
}
