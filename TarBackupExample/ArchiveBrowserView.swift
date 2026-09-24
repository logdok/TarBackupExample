// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI
import TarBackup

struct ArchiveBrowserView: View {
    let model: DemoBackupModel
    @State private var showsHistory = false

    private var displayedEntries: [TarEntryInfo] {
        showsHistory ? model.archivedHistory : model.archivedEntries
    }

    var body: some View {
        NavigationStack {
            DemoScreen(model: model) {
                DemoSection(
                    "Archive index",
                    subtitle: "Switch between logical contents and every physical TAR entry."
                ) {
                    Picker("Archive view", selection: $showsHistory) {
                        Text("Current (\(model.archivedEntries.count))")
                            .tag(false)
                        Text("History (\(model.archivedHistory.count))")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)

                    if displayedEntries.isEmpty {
                        ContentUnavailableView(
                            "Archive is empty",
                            systemImage: "archivebox",
                            description: Text("Create a backup or append a file from Operations.")
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(displayedEntries.enumerated()), id: \.offset) { index, entry in
                                DemoFileRow(
                                    name: entry.filename,
                                    size: entry.size,
                                    detail: entryDetail(entry, index: index)
                                )
                                if index < displayedEntries.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                if let difference = model.comparison {
                    comparisonSection(difference)
                } else {
                    DemoSection(
                        "Source comparison",
                        subtitle: "No comparison has been run in this session."
                    ) {
                        DemoActionButton(
                            title: "Compare source and archive",
                            subtitle: "Use the sample exclusions and classify every path.",
                            systemImage: "arrow.left.arrow.right",
                            tint: .purple,
                            action: model.compareSourceWithArchive
                        )
                    }
                }

                DemoSection("Storage summary") {
                    LabeledContent("Archive bytes", value: formattedSize(model.archiveSize))
                    LabeledContent("Logical paths", value: "\(model.archivedEntries.count)")
                    LabeledContent("Physical entries", value: "\(model.archivedVersionCount)")
                    LabeledContent("Superseded versions", value: "\(model.supersededVersionCount)")
                }
            }
            .navigationTitle("Archive Browser")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.loadState()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private func entryDetail(_ entry: TarEntryInfo, index: Int) -> String {
        let date = entry.modificationDate.formatted(date: .abbreviated, time: .shortened)
        if showsHistory {
            return "#\(index + 1) · \(formattedSize(entry.size)) · offset \(entry.offset) · \(date)"
        }
        return "\(formattedSize(entry.size)) · offset \(entry.offset) · \(date)"
    }

    private func comparisonSection(_ difference: TarArchiveDiff) -> some View {
        DemoSection(
            difference.isInSync ? "Source is in sync" : "Source comparison",
            subtitle: difference.isInSync
                ? "No metadata differences were found."
                : "TarBackup compares size and whole-second modification time."
        ) {
            comparisonGroup("Added", paths: difference.added, color: .green, icon: "plus.circle.fill")
            comparisonGroup("Modified", paths: difference.modified, color: .orange, icon: "pencil.circle.fill")
            comparisonGroup("Removed", paths: difference.removed, color: .red, icon: "minus.circle.fill")
            comparisonGroup("Unchanged", paths: difference.unchanged, color: .secondary, icon: "checkmark.circle.fill")
        }
    }

    private func comparisonGroup(
        _ title: String,
        paths: [String],
        color: Color,
        icon: String
    ) -> some View {
        DisclosureGroup {
            if paths.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(paths, id: \.self) { path in
                    Text(path)
                        .font(.caption.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                }
            }
        } label: {
            Label("\(title) · \(paths.count)", systemImage: icon)
                .foregroundStyle(color)
        }
    }
}
