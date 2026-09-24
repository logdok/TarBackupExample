// TarBackupExample - Copyright (c) 2026 Vitalii Yurchenko. All Rights Reserved.

import SwiftUI

struct DemoScreen<Content: View>: View {
    let model: DemoBackupModel
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                DemoStatusBanner(
                    message: model.statusMessage,
                    tone: model.statusTone
                )
                content
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct DemoSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct DemoActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .indigo
    var role: ButtonRole?
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(role == .destructive ? Color.red : tint)
                    .frame(width: 28, height: 28)
                    .background(
                        (role == .destructive ? Color.red : tint).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(role == .destructive ? Color.red : Color.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}

struct DemoStatusBanner: View {
    let message: String
    let tone: DemoStatusTone

    private var color: Color {
        switch tone {
        case .info: .indigo
        case .success: .green
        case .error: .red
        }
    }

    private var icon: String {
        switch tone {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.18))
        }
    }
}

struct DemoMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DemoFileRow: View {
    let name: String
    let size: UInt64
    var detail: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.monospaced())
                    .lineLimit(2)
                Text(detail ?? formattedSize(size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }

    private var iconName: String {
        if name.hasSuffix(".json") { return "curlybraces" }
        if name.hasSuffix(".txt") { return "doc.text" }
        if name.hasSuffix(".csv") { return "tablecells" }
        if name.hasSuffix(".ppm") { return "photo" }
        return "doc"
    }
}

func formattedSize(_ size: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
}
