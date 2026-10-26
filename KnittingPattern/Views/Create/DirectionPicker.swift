//
//  DirectionPicker.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

struct DirectionPicker<Value: Hashable>: View {
    
    let title: LocalizedStringKey
    @Binding var selection: Value
    let options: [(Value, String, LocalizedStringKey)]

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.ink)
            Spacer()
            HStack(spacing: 8) {
                ForEach(options, id: \.0) { value, icon, label in
                    SelectableCard(isSelected: selection == value, action: { selection = value }) {
                        Image(systemName: icon)
                            .foregroundStyle(.accentDark)
                    }
                    .frame(width: 64, height: 38)
                    .accessibilityLabel(label)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Выбор направления") {
    @Previewable @State var direction = RowDirection.bottomToTop
    DirectionPicker(
        title: "Row numbering",
        selection: $direction,
        options: [(.bottomToTop, "arrow.up", "Bottom to top"), (.topToBottom, "arrow.down", "Top to bottom")]
    )
    .padding()
    .background(Color.background)
}
#endif
