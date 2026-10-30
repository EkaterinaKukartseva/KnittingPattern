//
//  DirectionPicker.swift
//  Threadfolio
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

struct DirectionPicker<Value: Hashable>: View {

    struct Option {
        
        let value: Value
        let icon: String
        let label: LocalizedStringKey

        init(_ value: Value, _ icon: String, _ label: LocalizedStringKey) {
            self.value = value
            self.icon = icon
            self.label = label
        }
    }

    let title: LocalizedStringKey
    @Binding var selection: Value
    let options: [Option]

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.ink)
            Spacer()
            HStack(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    SelectableCard(isSelected: selection == option.value, action: { selection = option.value }) {
                        Image(systemName: option.icon)
                            .foregroundStyle(.accentDark)
                    }
                    .frame(width: 64, height: 38)
                    .accessibilityLabel(option.label)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Direction Picker") {
    @Previewable @State var direction = RowDirection.bottomToTop
    DirectionPicker(title: "Row numbering",
                    selection: $direction,
                    options: [.init(.bottomToTop, "arrow.up", "Bottom to top"), .init(.topToBottom, "arrow.down", "Top to bottom")])
    .padding()
    .background(Color.background)
}
#endif
