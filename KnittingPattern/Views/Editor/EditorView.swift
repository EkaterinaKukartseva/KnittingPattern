//
//  EditorView.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

struct EditorView: View {
    
    @State private var model: EditorModel
    @State private var tappedCell: GridPoint?
    @State private var isPickingSymbol = false
    @State private var isShowingInfo = false
    @State private var isShowingSettings = false
    @State private var isConfirmingClear = false
    @State private var pinchStartZoom: CGFloat?
    /// Пока пользователь сам не менял масштаб, сетка вписывается в доступную область
    /// (в том числе при повороте и смене размера окна).
    @State private var userZoomed = false
    @State private var canvasSize: CGSize = .zero
    /// Низкий экран (iPhone Duo, альбомная ориентация) — панель инструментов компактнее.
    @State private var isCompactHeight = false
    @State private var customColor = Color.accent
    @State private var patternToRename: Pattern?

    private let pattern: Pattern

    init(pattern: Pattern) {
        self.pattern = pattern
        _model = State(initialValue: EditorModel(pattern: pattern))
    }

    private var baseLayout: ChartLayout { ChartLayout(settings: model.settings) }
    private var layout: ChartLayout { ChartLayout(settings: model.settings, zoom: model.zoom) }

    /// Ограничение масштаба, чтобы холст не стал гигантской текстурой.
    private var maxZoom: CGFloat {
        let base = baseLayout.totalSize
        return min(4, 5000 / max(base.width, base.height))
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            bottomPanel
        }
        .background(Color.background)
        .onGeometryChange(for: Bool.self) { $0.size.height < 680 } action: { isCompactHeight = $0 }
        .inlineNavigationTitle(pattern.name)
        .toolbar { toolbarContent }
        #if os(iOS)
        .toolbarVisibility(.hidden, for: .tabBar)
        #endif
        .sheet(isPresented: $isPickingSymbol, onDismiss: { tappedCell = nil }) {
            SymbolPickerView(craft: pattern.craft, selected: model.currentSymbol) { symbol in
                if let tappedCell {
                    model.place(symbol: symbol, at: tappedCell)
                } else {
                    model.currentSymbol = symbol
                    model.paintsBackground = false
                    if model.tool == .pan || model.tool == .eraser { model.tool = .pencil }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingInfo) {
            PatternInfoView(pattern: pattern, usedStitches: model.usedStitches)
        }
        .sheet(isPresented: $isShowingSettings) {
            EditorSettingsView(pattern: pattern, settings: model.settings) { settings in
                model.apply(settings)
                userZoomed = false
                fitZoom(to: canvasSize)
            }
                .presentationDetents([.large])
        }
        .renamePatternAlert($patternToRename)
        .confirmationDialog("Clear the entire chart?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) { model.clearAll() }
        } message: {
            Text("You can reverse this with Undo.")
        }
    }

    // MARK: Холст

    private var canvasArea: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                chartCanvas
                    .padding(16)
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            }
            .scrollDisabled(model.tool != .pan)
            .simultaneousGesture(magnifyGesture)
            .onChange(of: proxy.size, initial: true) { _, size in
                canvasSize = size
                if !userZoomed { fitZoom(to: size) }
            }
            .overlay(alignment: .top) { selectionBar }
        }
        // Не даём сетке заезжать под системные панели (на Duo они справа).
        .clipped()
    }

    private var chartCanvas: some View {
        let layout = layout
        let image = pattern.showImage ? ImageSupport.image(from: pattern.imageData) : nil
        return Canvas { context, _ in
            ChartRenderer.draw(
                &context, layout: layout, cells: model.cells,
                image: image, imageOpacity: pattern.imageOpacity, selection: model.selection
            )
        }
        .frame(width: layout.totalSize.width, height: layout.totalSize.height)
        .accessibilityElement()
        .accessibilityLabel("Chart grid")
        .accessibilityIdentifier("chartCanvas")
        .gesture(drawGesture(layout: layout), isEnabled: model.tool != .pan)
        .onTapGesture(coordinateSpace: .local) { location in
            guard model.tool == .pan, let cell = layout.cell(at: location) else { return }
            tappedCell = cell
            isPickingSymbol = true
        }
    }

    private func drawGesture(layout: ChartLayout) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                switch model.tool {
                case .pencil, .eraser:
                    if let cell = layout.cell(at: value.location, clamped: true) { model.stroke(to: cell) }
                case .select:
                    if let cell = layout.cell(at: value.location, clamped: true) { model.dragSelection(to: cell) }
                case .fill, .pan:
                    break
                }
            }
            .onEnded { value in
                switch model.tool {
                case .pencil, .eraser:
                    model.endStroke()
                case .select:
                    model.endSelectionDrag()
                case .fill:
                    if let cell = layout.cell(at: value.startLocation) { model.floodFill(at: cell) }
                case .pan:
                    break
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStartZoom ?? model.zoom
                pinchStartZoom = start
                model.zoom = min(max(start * value.magnification, 0.3), maxZoom)
                userZoomed = true
            }
            .onEnded { _ in pinchStartZoom = nil }
    }

    private func fitZoom(to size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let base = baseLayout.totalSize
        let fit = min((size.width - 32) / base.width, (size.height - 32) / base.height)
        model.zoom = min(max(fit, 0.3), min(1.6, maxZoom))
    }

    private func zoomButtons(height: CGFloat) -> some View {
        HStack(spacing: 0) {
            Button {
                userZoomed = true
                model.zoom = max(model.zoom / 1.25, 0.3)
            } label: {
                Image(systemName: "minus.magnifyingglass").frame(width: 38, height: height)
            }
            .accessibilityLabel("Zoom out")
            Button {
                userZoomed = true
                model.zoom = min(model.zoom * 1.25, maxZoom)
            } label: {
                Image(systemName: "plus.magnifyingglass").frame(width: 38, height: height)
            }
            .accessibilityLabel("Zoom in")
        }
        .font(.body)
        .foregroundStyle(.ink)
        .buttonStyle(.plain)
        .background(.card, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.cardBorder) }
    }

    @ViewBuilder private var selectionBar: some View {
        if model.tool == .select, model.selection != nil {
            HStack(spacing: 2) {
                selectionButton("doc.on.doc", "Copy") { model.copySelection() }
                if model.clipboard != nil {
                    selectionButton("doc.on.clipboard", "Paste") { model.paste() }
                }
                selectionButton("arrow.left.and.right.righttriangle.left.righttriangle.right", "Flip horizontally") {
                    model.flipSelection(horizontally: true)
                }
                selectionButton("arrow.up.and.down.righttriangle.up.righttriangle.down", "Flip vertically") {
                    model.flipSelection(horizontally: false)
                }
                selectionButton("paintbrush", "Fill with selected stitch") { model.fillSelection() }
                selectionButton("trash", "Clear", tint: .red) { model.clearSelection() }
                selectionButton("xmark", "Deselect") { model.selection = nil }
            }
            .padding(4)
            .background(Color.card, in: .rect(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Color.cardBorder) }
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
            .padding(.top, 8)
        }
    }

    private func selectionButton(
        _ icon: String, _ label: LocalizedStringKey, tint: Color = .ink, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(tint)
                .frame(width: 38, height: 34)
        }
        .accessibilityLabel(label)
    }

    // MARK: Панель инструментов

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .disabled(!model.canUndo)
                .accessibilityLabel("Undo")
            Button { model.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .disabled(!model.canRedo)
                .accessibilityLabel("Redo")
            Menu {
                Button { patternToRename = pattern } label: {
                    Label("Rename", systemImage: "pencil.line")
                }
                Button { isShowingInfo = true } label: {
                    Label("Description, Notes and Export", systemImage: "square.and.arrow.up")
                }
                Button { isShowingSettings = true } label: {
                    Label("Grid Settings", systemImage: "squareshape.split.3x3")
                }
                Button { pattern.isFavorite.toggle() } label: {
                    Label(pattern.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                          systemImage: pattern.isFavorite ? "heart.slash" : "heart")
                }
                if pattern.imageData != nil {
                    Toggle(isOn: Bindable(pattern).showImage) {
                        Label("Background Photo", systemImage: "photo")
                    }
                }
                Divider()
                Button(role: .destructive) { isConfirmingClear = true } label: {
                    Label("Clear Chart", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }

    private var toolHeight: CGFloat { isCompactHeight ? 40 : 46 }

    private var bottomPanel: some View {
        VStack(spacing: isCompactHeight ? 8 : 12) {
            if model.tool != .pan {
                HStack(spacing: 12) {
                    Button {
                        tappedCell = nil
                        isPickingSymbol = true
                    } label: {
                        Group {
                            if let stitch = Stitch.with(id: model.currentSymbol) {
                                StitchGlyph(stitch: stitch, color: model.currentColor.color)
                                    .padding(8)
                            }
                        }
                        .frame(width: toolHeight + 2, height: toolHeight + 2)
                        .background(model.paintsBackground ? .card : .selected, in: .rect(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(model.paintsBackground ? .cardBorder : .selectedBorder)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Choose stitch symbol")

                    VStack(alignment: .leading, spacing: 6) {
                        Picker("Brush", selection: $model.paintsBackground) {
                            Text("Symbol").tag(false)
                            Text("Cell Fill").tag(true)
                        }
                        .pickerStyle(.segmented)
                        if !isCompactHeight {
                            Text(model.paintsBackground
                                 ? String(localized: "Fill color")
                                 : (Stitch.with(id: model.currentSymbol)?.name ?? String(localized: "Symbol color")))
                                .font(.caption)
                                .foregroundStyle(.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(model.palette, id: \.self) { color in
                            Button { model.selectColor(color) } label: {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 30, height: 30)
                                    .padding(3)
                                    .overlay {
                                        Circle().strokeBorder(
                                            model.currentColor == color ? .accentDark : .clear, lineWidth: 2
                                        )
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                        ColorPicker("Add Color", selection: $customColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: customColor) { _, color in model.pickCustomColor(color) }
                    }
                    .padding(.horizontal, 2)
                }
            }

            HStack(spacing: 8) {
                ForEach(EditorModel.Tool.allCases) { tool in
                    Button { model.tool = tool } label: {
                        Image(systemName: tool.icon)
                            .font(.title3)
                            .foregroundStyle(model.tool == tool ? .accentDark : .ink)
                            .frame(maxWidth: .infinity, minHeight: toolHeight)
                            .background(model.tool == tool ? .selected : .card, in: .rect(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(model.tool == tool ? .selectedBorder : .cardBorder)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tool.title)
                }
                zoomButtons(height: toolHeight)
            }

            if model.tool == .pan {
                Text("Tap a cell to choose a stitch. You can pan and zoom the chart.")
                    .font(.caption)
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isCompactHeight ? 8 : 12)
        .padding(.bottom, 8)
        .background(Color.background.shadow(.drop(color: .black.opacity(0.06), radius: 6, y: -2)))
    }
}

#if DEBUG
#Preview("Editor — Crochet") {
    NavigationStack {
        EditorView(pattern: SampleData.previewPattern)
    }
    .modelContainer(SampleData.previewContainer)
}

#Preview("Editor — Knitting") {
    NavigationStack {
        EditorView(pattern: SampleData.knitStripes())
    }
    .modelContainer(SampleData.previewContainer)
}
#endif
