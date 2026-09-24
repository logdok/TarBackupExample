// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI

struct ArchiveOperationsView: View {
    let model: DemoBackupModel

    var body: some View {
        NavigationStack {
            DemoScreen(model: model) {
                DemoSection(
                    "Incremental backup & compare",
                    subtitle: "Exercise performBackup, exclusions, and source comparison."
                ) {
                    actionGrid {
                        DemoActionButton(
                            title: "Create files",
                            subtitle: "Prepare the sample source tree.",
                            systemImage: "doc.badge.plus",
                            action: model.createDemoFiles
                        )
                        DemoActionButton(
                            title: "Standard backup",
                            subtitle: "Back up every visible regular file.",
                            systemImage: "archivebox",
                            action: model.runBackup
                        )
                        DemoActionButton(
                            title: "Backup + exclude",
                            subtitle: "Apply the three sample patterns.",
                            systemImage: "line.3.horizontal.decrease.circle",
                            tint: .green,
                            action: model.runBackupWithExclusions
                        )
                        DemoActionButton(
                            title: "Modify a file",
                            subtitle: "Create a newer logical version.",
                            systemImage: "pencil",
                            tint: .orange,
                            action: model.modifyWelcomeNote
                        )
                        DemoActionButton(
                            title: "Create diff",
                            subtitle: "Make added, modified, and removed paths.",
                            systemImage: "arrow.left.arrow.right",
                            tint: .purple,
                            action: model.createComparisonScenario
                        )
                        DemoActionButton(
                            title: "Compare now",
                            subtitle: "Classify disk paths against the archive.",
                            systemImage: "checklist",
                            tint: .purple,
                            action: model.compareSourceWithArchive
                        )
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(DemoBackupModel.exclusionPatterns, id: \.self) { pattern in
                                Text(pattern)
                                    .font(.caption.monospaced().weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.indigo.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }

                DemoSection(
                    "Direct append",
                    subtitle: "Append source files or map arbitrary files without repacking existing entries."
                ) {
                    actionGrid {
                        DemoActionButton(
                            title: "Source file",
                            subtitle: "appendFile(named:)",
                            systemImage: "doc.badge.plus",
                            action: model.appendOneSourceFile
                        )
                        DemoActionButton(
                            title: "Source batch",
                            subtitle: "appendFiles(named:)",
                            systemImage: "doc.on.doc",
                            action: model.appendSourceBatch
                        )
                        DemoActionButton(
                            title: "Mapped file",
                            subtitle: "appendFile(at:as:)",
                            systemImage: "arrow.right.doc.on.clipboard",
                            tint: .teal,
                            action: model.appendOneMappedFile
                        )
                        DemoActionButton(
                            title: "Mapped batch",
                            subtitle: "appendFiles([TarAppendItem])",
                            systemImage: "square.stack.3d.up",
                            tint: .teal,
                            action: model.appendMappedBatch
                        )
                    }
                }

                DemoSection(
                    "Maintenance",
                    subtitle: "Delete, repair, and compact the real archive."
                ) {
                    actionGrid {
                        DemoActionButton(
                            title: "Delete one",
                            subtitle: "Remove the mapped external note.",
                            systemImage: "trash",
                            tint: .red,
                            action: model.deleteOneFile
                        )
                        DemoActionButton(
                            title: "Delete batch",
                            subtitle: "Remove both manual batch paths.",
                            systemImage: "trash.slash",
                            tint: .red,
                            action: model.deleteMultipleFiles
                        )
                        DemoActionButton(
                            title: "Repair & index",
                            subtitle: "Validate headers and repair the tail.",
                            systemImage: "stethoscope",
                            tint: .blue,
                            action: model.repairArchive
                        )
                        DemoActionButton(
                            title: "Compact now",
                            subtitle: "Keep only each path's latest version.",
                            systemImage: "arrow.triangle.2.circlepath",
                            tint: .green,
                            action: model.compactArchive
                        )
                        DemoActionButton(
                            title: "Schedule compaction",
                            subtitle: "Ask iOS for a powered background run.",
                            systemImage: "clock.badge.checkmark",
                            tint: .blue,
                            action: model.scheduleBackgroundCompaction
                        )
                    }
                }

                DemoSection("Reset demo") {
                    DemoActionButton(
                        title: "Delete demo workspace",
                        subtitle: "Remove source files, archive, imports, and restored output.",
                        systemImage: "trash.fill",
                        role: .destructive,
                        action: model.resetDemo
                    )
                }
            }
            .navigationTitle("Operations")
        }
    }

    private func actionGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 155), spacing: 10)],
            spacing: 10,
            content: content
        )
    }
}
