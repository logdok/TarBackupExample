// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI

struct ContentView: View {
    @State private var model = DemoBackupModel()

    var body: some View {
        TabView {
            DashboardView(model: model)
                .tabItem {
                    Label("Overview", systemImage: "square.grid.2x2.fill")
                }

            ArchiveOperationsView(model: model)
                .tabItem {
                    Label("Operations", systemImage: "archivebox.fill")
                }

            ArchiveBrowserView(model: model)
                .tabItem {
                    Label("Archive", systemImage: "list.bullet.rectangle")
                }

            RestoreView(model: model)
                .tabItem {
                    Label("Restore", systemImage: "arrow.down.doc.fill")
                }
        }
        .tint(.indigo)
        .task {
            model.loadState()
        }
        .overlay {
            if model.isWorking {
                ZStack {
                    Color.black.opacity(0.08)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
