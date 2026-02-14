//
//  MarkdownEditorView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI

struct MarkdownEditorView: View {
    @Binding var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    
    var body: some View {
        VStack(spacing: 0) {
            // 툴바
            FormattingToolbar(
                text: $text,
                selection: $selection
            )
            
            // 편집기
            TextEditor(text: $text, selection: $selection)
                .font(.body)
                .padding(8)
        }
    }
}

struct FormattingToolbar: View {
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    
    @State private var selectedColor: Color = .primary
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Bold
                Button {
                    toggleBold()
                } label: {
                    Image(systemName: "bold")
                        .frame(width: 44, height: 44)
                        .background(isBold ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                
                // Italic
                Button {
                    toggleItalic()
                } label: {
                    Image(systemName: "italic")
                        .frame(width: 44, height: 44)
                        .background(isItalic ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                
                // Underline
                Button {
                    toggleUnderline()
                } label: {
                    Image(systemName: "underline")
                        .frame(width: 44, height: 44)
                        .background(isUnderlined ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Header 1
                Button {
                    applyHeader(level: 1)
                } label: {
                    Text("H1")
                        .fontWeight(.bold)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .cornerRadius(8)
                }
                
                // Header 2
                Button {
                    applyHeader(level: 2)
                } label: {
                    Text("H2")
                        .fontWeight(.bold)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .cornerRadius(8)
                }
                
                Divider()
                    .frame(height: 30)
                
                // List
                Button {
                    insertListItem()
                } label: {
                    Image(systemName: "list.bullet")
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .cornerRadius(8)
                }
                
                // Numbered list
                Button {
                    insertNumberedList()
                } label: {
                    Image(systemName: "list.number")
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .cornerRadius(8)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Color picker
                ColorPicker("", selection: Binding(
                    get: { getSelectionColor() },
                    set: { setSelectionColor($0) }
                ))
                .labelsHidden()
                .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(height: 52)
        .background(.quaternary)
    }
    
    // MARK: - Computed Properties
    
    private var isBold: Bool {
        let attributes = selection.typingAttributes(in: text)
        if let font = attributes.font {
            let resolved = font.resolve(in: fontResolutionContext)
            return resolved.isBold
        }
        return false
    }
    
    private var isItalic: Bool {
        let attributes = selection.typingAttributes(in: text)
        if let font = attributes.font {
            let resolved = font.resolve(in: fontResolutionContext)
            return resolved.isItalic
        }
        return false
    }
    
    private var isUnderlined: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.underlineStyle != nil
    }
    
    // MARK: - Actions
    
    private func toggleBold() {
        text.transformAttributes(in: &selection) {
            let font = $0.font ?? .default
            let resolved = font.resolve(in: fontResolutionContext)
            $0.font = font.bold(!resolved.isBold)
        }
    }
    
    private func toggleItalic() {
        text.transformAttributes(in: &selection) {
            let font = $0.font ?? .default
            let resolved = font.resolve(in: fontResolutionContext)
            $0.font = font.italic(!resolved.isItalic)
        }
    }
    
    private func toggleUnderline() {
        text.transformAttributes(in: &selection) {
            if $0.underlineStyle != nil {
                $0.underlineStyle = nil
            } else {
                $0.underlineStyle = .single
            }
        }
    }
    
    private func applyHeader(level: Int) {
        text.transformAttributes(in: &selection) {
            switch level {
            case 1:
                $0.font = .system(.title).bold()
            case 2:
                $0.font = .system(.title2).bold()
            default:
                $0.font = .system(.body)
            }
        }
    }
    
    private func insertListItem() {
        var newText = AttributedString("\n- ")
        text.replaceSelection(&selection, with: newText)
    }
    
    private func insertNumberedList() {
        var newText = AttributedString("\n1. ")
        text.replaceSelection(&selection, with: newText)
    }
    
    private func getSelectionColor() -> Color {
        let attributes = selection.typingAttributes(in: text)
        return attributes.foregroundColor ?? .primary
    }
    
    private func setSelectionColor(_ color: Color) {
        text.transformAttributes(in: &selection) {
            $0.foregroundColor = color
        }
    }
}

#Preview {
    MarkdownEditorView(text: .constant(AttributedString("테스트 텍스트를 입력하세요...")))
}
