//
//  LibraryView.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    
    enum Filter: String, CaseIterable, Identifiable {
        
        case all, crochet, knitting, favorites
        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .all: "All"
            case .crochet: "Crochet"
            case .knitting: "Knitting"
            case .favorites: "Favorites"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppRouter.self) private var router
    @Query(sort: \Pattern.updatedAt, order: .reverse) private var patterns: [Pattern]
    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var patternToDelete: Pattern?
    @State private var patternToRename: Pattern?

    private var filtered: [Pattern] {
        patterns.filter { pattern in
            let matchesFilter = switch filter {
            case .all: true
            case .crochet: pattern.craft == .crochet
            case .knitting: pattern.craft == .knitting
            case .favorites: pattern.isFavorite
            }
            guard matchesFilter else { return false }
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return true }
            return [pattern.name, pattern.summary, pattern.notes].contains {
                $0.localizedCaseInsensitiveContains(query)
            }
        }
    }

    /// На iPhone — две колонки, на iPad карточки крупнее: 3 в портрете, 4 в альбомной ориентации.
    private var gridColumns: [GridItem] {
        let isRegular = horizontalSizeClass == .regular
        return [GridItem(.adaptive(minimum: isRegular ? 230 : 150, maximum: isRegular ? 340 : 220), spacing: isRegular ? 20 : 14)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                searchField
                filterChips

                if filtered.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 18) {
                        ForEach(filtered) { pattern in
                            NavigationLink(value: pattern) {
                                PatternCard(
                                    pattern: pattern,
                                    onRename: { patternToRename = pattern },
                                    onDelete: { patternToDelete = pattern }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.background)
        #if os(iOS)
        .toolbarVisibility(.hidden, for: .navigationBar)
        #endif
        .renamePatternAlert($patternToRename)
        .confirmationDialog(
            "Delete chart “\(patternToDelete?.name ?? "")”?",
            isPresented: Binding(get: { patternToDelete != nil }, set: { if !$0 { patternToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let patternToDelete { modelContext.delete(patternToDelete) }
                patternToDelete = nil
            }
        } message: {
            Text("This can’t be undone.")
        }
    }

    private var header: some View {
        HStack {
            Text("My Charts")
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(.ink)
            Spacer()
            Button {
                router.isCreating = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.accent, in: .circle)
            }
            .accessibilityLabel("Create Chart")
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondaryText)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.card.opacity(0.6), in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.cardBorder) }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { item in
                    Button {
                        filter = item
                    } label: {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(filter == item ? .accentDark : .ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(filter == item ? .selected : .card, in: .rect(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(filter == item ? .selectedBorder : .cardBorder)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        // Чипы прокручиваются до края экрана, а не обрезаются по отступу.
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .padding(.horizontal, -20)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.accent)
            Text(patterns.isEmpty ? "Your charts will appear here" : "Nothing found")
                .font(.headline)
                .foregroundStyle(.ink)
            if patterns.isEmpty {
                Text("Create a chart from scratch or import a photo of an existing one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.center)
                Button("Create Chart") { router.isCreating = true }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 240)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

#if DEBUG
#Preview("Library") {
    NavigationStack {
        LibraryView()
    }
    .environment(AppRouter())
    .modelContainer(SampleData.previewContainer)
}

#Preview("Library — Empty") {
    NavigationStack {
        LibraryView()
    }
    .environment(AppRouter())
    .modelContainer(for: Pattern.self, inMemory: true)
}
#endif
