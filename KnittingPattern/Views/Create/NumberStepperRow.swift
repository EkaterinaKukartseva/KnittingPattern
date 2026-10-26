//
//  NumberStepperRow.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI

struct NumberStepperRow: View {
    
    let title: LocalizedStringKey
    @Binding var value: Int
    var range: ClosedRange<Int> = PatternDraft.sizeRange

    /// Текст поля редактируется свободно и проверяется только по окончании ввода:
    /// иначе при наборе «15» первая «1» сразу превращалась бы в минимум (2).
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.ink)
            Spacer()
            HStack(spacing: 0) {
                stepButton("minus") { setValue(value - 1) }
                TextField("", text: $text)
                    .multilineTextAlignment(.center)
                    .frame(width: 44)
                    .focused($isFocused)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .onSubmit(commit)
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commit() }
                    }
                    .onChange(of: text) { _, newText in
                        let digits = String(newText.filter(\.isNumber).prefix(3))
                        if digits != newText { text = digits }
                        // Допустимое число применяем сразу — на случай, если после ввода
                        // сразу нажмут «Создать» или «Готово».
                        if let number = Int(digits), range.contains(number) { value = number }
                    }
                stepButton("plus") { setValue(value + 1) }
            }
            .padding(4)
            .background(.card.opacity(0.6), in: .rect(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.cardBorder) }
        }
        .onAppear { text = "\(value)" }
        .onChange(of: value) { _, newValue in
            if !isFocused { text = "\(newValue)" }
        }
        #if os(iOS)
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Text("From \(range.lowerBound) to \(range.upperBound)")
                        .font(.footnote)
                        .foregroundStyle(.secondaryText)
                    Spacer()
                    Button("Done") { isFocused = false }
                }
            }
        }
        #endif
    }

    private func setValue(_ newValue: Int) {
        isFocused = false
        value = min(max(newValue, range.lowerBound), range.upperBound)
        text = "\(value)"
    }

    private func commit() {
        setValue(Int(text) ?? value)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.ink)
                .frame(width: 32, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
    }
}

#if DEBUG
#Preview("Поле числа") {
    @Previewable @State var value = 20
    NumberStepperRow(title: "Width (stitch count)", value: $value)
        .padding()
        .background(Color.background)
}
#endif
