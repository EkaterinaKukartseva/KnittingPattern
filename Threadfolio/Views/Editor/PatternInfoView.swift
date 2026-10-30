//
//  PatternInfoView.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData
import PhotosUI

/// Описание, заметки, фото и экспорт схемы.
struct PatternInfoView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Bindable var pattern: Pattern
    let usedStitches: [Stitch]

    @State private var exportURL: URL?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Chart name", text: $pattern.name)
                    Toggle("Favorites", isOn: $pattern.isFavorite)
                        .tint(Color.accent)
                }

                Section {
                    TextField(
                        pattern.craft == .crossStitch ? "Fabric, floss, size…" : "Yarn, hook or needles, gauge, size…",
                        text: $pattern.summary, axis: .vertical
                    )
                        .lineLimit(3...8)
                } header: {
                    Text("Description")
                }

                Section {
                    TextField("Where you stopped, what to change, ideas…", text: $pattern.notes, axis: .vertical)
                        .lineLimit(4...12)
                } header: {
                    Text("Notes")
                }

                Section("Chart Photo") {
                    if let image = ImageSupport.image(from: pattern.imageData) {
                        image.resizable().scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(.rect(cornerRadius: 10))
                            .frame(maxWidth: .infinity)
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(pattern.imageData == nil ? "Add Photo" : "Replace Photo", systemImage: "photo")
                    }
                    if pattern.imageData != nil {
                        Button("Remove Photo", role: .destructive) {
                            pattern.imageData = nil
                            pattern.showImage = false
                        }
                    }
                }

                if !usedStitches.isEmpty {
                    Section("Legend") {
                        ForEach(usedStitches) { stitch in
                            HStack(spacing: 12) {
                                StitchGlyph(stitch: stitch).frame(width: 26, height: 26)
                                Text(stitch.name)
                            }
                        }
                    }
                }

                if !threads.isEmpty {
                    Section("Threads") {
                        ForEach(threads) { ThreadRow(thread: $0) }
                    }
                }

                if !otherColors.isEmpty {
                    Section("Colors") {
                        ColorSwatches(colors: otherColors)
                    }
                }

                Section {
                    if let exportURL {
                        ShareLink(item: exportURL, message: Text(shareText)) {
                            Label("Share Chart", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        HStack {
                            ProgressView()
                            Text("Preparing image…").foregroundStyle(Color.secondaryText)
                        }
                    }
                } footer: {
                    Text("The chart saves automatically. Sharing creates a PNG with the grid and legend.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .inlineNavigationTitle("About Chart")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: "\(pattern.name)|\(pattern.summary)|\(pattern.updatedAt)") {
                // Небольшая пауза, чтобы не перерисовывать PNG на каждую букву.
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                renderExport()
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        pattern.imageData = ImageSupport.compressedData(from: data) ?? data
                        pattern.showImage = true
                        pattern.updatedAt = .now
                    }
                }
            }
        }
    }

    private var threads: [ThreadUsage] { ThreadUsage.threads(of: pattern) }
    private var otherColors: [CellColor] { ThreadUsage.otherColors(of: pattern) }

    private var shareText: String {
        [pattern.name, pattern.summary].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    private func renderExport() {
        let renderer = ImageRenderer(content: PatternExportView(pattern: pattern, usedStitches: usedStitches))
        renderer.scale = pattern.columns * pattern.rows > 6000 ? 1.5 : 2
        guard let cgImage = renderer.cgImage else { return }
        exportURL = ImageSupport.writePNG(cgImage, named: pattern.name)
    }
}

#if DEBUG
#Preview("About Chart") {
    PatternInfoView(pattern: SampleData.previewPattern, usedStitches: [Stitch.crochet[2]])
        .modelContainer(SampleData.previewContainer)
}
#endif
