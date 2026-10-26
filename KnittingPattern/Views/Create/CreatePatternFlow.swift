//
//  CreatePatternFlow.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData
import PhotosUI

/// Черновик новой схемы, который заполняется по шагам мастера.
@Observable
final class PatternDraft {
    
    nonisolated enum Source { case blank, image }

    var source: Source = .blank
    var craft: Craft = .crochet
    var imageData: Data?
    var name = ""
    var columns = 20
    var rows = 20
    var cellSize: CellSize = .medium
    var cellShape: CellShape = .square
    var showColumnNumbers = true
    var showRowNumbers = true
    var rowDirection: RowDirection = .bottomToTop
    var columnDirection: ColumnDirection = .leftToRight
    /// Перенести цвета фото в фон клеток (для жаккарда и вышивки).
    var sampleImageColors = false

    static let sizeRange = 2...150

    func makePattern() -> Pattern {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var cells: [Cell]?
        if sampleImageColors, let imageData,
           let colors = ImageSupport.sampleColors(from: imageData, columns: columns, rows: rows) {
            cells = colors.map { Cell(background: .custom($0)) }
        }
        return Pattern(
            name: trimmed.isEmpty ? String(localized: "New Chart") : trimmed,
            craft: craft, columns: columns, rows: rows,
            cellSize: cellSize, cellShape: cellShape,
            showColumnNumbers: showColumnNumbers, showRowNumbers: showRowNumbers,
            rowDirection: rowDirection, columnDirection: columnDirection,
            imageData: imageData, cells: cells
        )
    }
}

struct CreatePatternFlow: View {
    
    var onCreate: (Pattern) -> Void
    @State private var draft = PatternDraft()

    var body: some View {
        NavigationStack {
            CreatePatternView(draft: draft, onCreate: onCreate)
        }
        .tint(.accentDark)
    }
}

// MARK: - Шаг 1: источник и тип вязания

struct CreatePatternView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Bindable var draft: PatternDraft
    var onCreate: (Pattern) -> Void

    @State private var photoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SelectableCard(isSelected: draft.source == .blank, action: { draft.source = .blank }) {
                    sourceLabel(icon: "squareshape.split.3x3", title: "Blank Grid", subtitle: nil)
                }
                .frame(height: 88)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    sourceLabel(
                        icon: "photo", title: "From Image",
                        subtitle: draft.imageData == nil ? "A photo of a chart becomes the background layer" : "Photo selected — tap to replace"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(draft.source == .image ? .selected : .card, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(draft.source == .image ? .selectedBorder : .cardBorder)
                    }
                }
                .buttonStyle(.plain)
                .frame(height: 88)

                if let image = ImageSupport.image(from: draft.imageData), draft.source == .image {
                    image.resizable().scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(.rect(cornerRadius: 12))
                        .frame(maxWidth: .infinity)
                }
                if isLoadingPhoto {
                    ProgressView().frame(maxWidth: .infinity)
                }

                Text("Craft")
                    .font(.headline)
                    .foregroundStyle(.ink)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    ForEach(Craft.allCases) { craft in
                        SelectableCard(isSelected: draft.craft == craft, action: { draft.craft = craft }) {
                            VStack(spacing: 12) {
                                Image(systemName: craft == .crochet ? "line.diagonal" : "pause")
                                    .font(.system(size: 34, weight: .light))
                                    .foregroundStyle(.accentDark)
                                Text(craft.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.ink)
                            }
                        }
                        .frame(height: 110)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.background)
        .safeAreaInset(edge: .bottom) {
            NavigationLink("Continue") {
                GridSettingsView(draft: draft, onCreate: onCreate)
            }
            .buttonStyle(PrimaryButtonStyle())
            .bottomActionBar()
        }
        .inlineNavigationTitle("Create Chart")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            isLoadingPhoto = true
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    draft.imageData = ImageSupport.compressedData(from: data) ?? data
                    draft.source = .image
                }
                isLoadingPhoto = false
            }
        }
    }

    private func sourceLabel(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey?) -> some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.accentDark)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.ink)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondaryText)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

extension View {
    
    /// Нижняя кнопка мастера на непрозрачной подложке, чтобы под ней
    /// не просвечивала прокручиваемая форма (заметно на низких экранах, например iPhone Duo).
    func bottomActionBar() -> some View {
        padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background {
                Color.background
                    .shadow(color: .black.opacity(0.06), radius: 6, y: -2)
                    .ignoresSafeArea(edges: [.bottom, .horizontal])
            }
    }
}

#if DEBUG
#Preview("Мастер создания") {
    CreatePatternFlow { _ in }
        .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
