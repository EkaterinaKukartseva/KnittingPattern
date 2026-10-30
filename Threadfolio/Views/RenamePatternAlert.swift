//
//  RenamePatternAlert.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import SwiftData

/// Окно «Переименовать схему»: показывается, пока `pattern` не nil.
private struct RenamePatternAlert: ViewModifier {
    
    @Binding var pattern: Pattern?
    @State private var name = ""

    func body(content: Content) -> some View {
        content
            .alert(
                "Rename Chart",
                isPresented: Binding(get: { pattern != nil }, set: { if !$0 { pattern = nil } })
            ) {
                TextField("Name", text: $name)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let pattern, !trimmed.isEmpty {
                        pattern.name = trimmed
                        pattern.updatedAt = .now
                    }
                }
            }
            .onChange(of: pattern?.persistentModelID) {
                name = pattern?.name ?? ""
            }
    }
}

extension View {
    
    func renamePatternAlert(_ pattern: Binding<Pattern?>) -> some View {
        modifier(RenamePatternAlert(pattern: pattern))
    }
}

#if DEBUG
#Preview {
    @Previewable @State var pattern: Pattern? = SampleData.previewPattern
    Button("Rename") { pattern = SampleData.previewPattern }
        .renamePatternAlert($pattern)
        .modelContainer(SampleData.previewContainer)
}
#endif
