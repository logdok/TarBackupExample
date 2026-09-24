// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI

struct DashboardView: View {
    let model: DemoBackupModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            DemoScreen(model: model) {
                hero

                LazyVGrid(columns: columns, spacing: 12) {
                    DemoMetric(
                        title: "Source files",
                        value: "\(model.sourceFiles.count)",
                        systemImage: "folder.fill",
                        color: .blue
                    )
                    DemoMetric(
                        title: "Current entries",
                        value: "\(model.archivedEntries.count)",
                        systemImage: "archivebox.fill",
                        color: .indigo
                    )
                    DemoMetric(
                        title: "Stored versions",
                        value: "\(model.archivedVersionCount)",
                        systemImage: "clock.arrow.circlepath",
                        color: .orange
                    )
                    DemoMetric(
                        title: "Archive size",
                        value: formattedSize(model.archiveSize),
                        systemImage: "externaldrive.fill",
                        color: .green
                    )
                }

                DemoSection(
                    "Quick start",
                    subtitle: "A short workflow that shows incremental TAR backups."
                ) {
                    VStack(spacing: 10) {
                        DemoActionButton(
                            title: "1. Create sample workspace",
                            subtitle: "Generate documents, settings, reports, and excluded files.",
                            systemImage: "doc.badge.plus",
                            action: model.createDemoFiles
                        )
                        DemoActionButton(
                            title: "2. Back up with exclusions",
                            subtitle: "Create the TAR while skipping temporary and dependency files.",
                            systemImage: "archivebox.fill",
                            tint: .green,
                            action: model.runBackupWithExclusions
                        )
                        DemoActionButton(
                            title: "3. Modify and back up again",
                            subtitle: "Change welcome.txt, then repeat step 2 to store a new version.",
                            systemImage: "pencil.and.outline",
                            tint: .orange,
                            action: model.modifyWelcomeNote
                        )
                    }
                }

                DemoSection(
                    "Workspace locations",
                    subtitle: "Long-press a path to select and copy it."
                ) {
                    pathRow("Source", url: model.sourceDirectoryURL, icon: "folder")
                    Divider()
                    pathRow("Archive", url: model.archiveURL, icon: "archivebox")
                    Divider()
                    pathRow("Restored", url: model.restoreDirectoryURL, icon: "arrow.down.doc")
                }
            }
            .navigationTitle("TarBackup")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
                Spacer()
                Text("PACKAGE 1.2.0")
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: Capsule())
            }
            Text("Explore every TarBackup workflow")
                .font(.title2.bold())
            Text("Create, inspect, compare, edit, repair, compact, and selectively restore a real TAR archive.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private func pathRow(_ title: String, url: URL, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(url.path)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}
