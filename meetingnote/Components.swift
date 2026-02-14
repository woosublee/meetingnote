//
//  Components.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .fill(Color.cardBg)
            )
    }
}

// MARK: - App Divider
struct AppDivider: View {
    var body: some View {
        Divider()
            .background(Color.appBorder)
    }
}

// MARK: - Pulse View
struct PulseView: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Waveform Visualization View
struct WaveformVisualizationView: View {
    let levels: [Float]
    let color: Color

    var body: some View {
        Canvas { context, size in
            let count = levels.count
            guard count > 0 else { return }
            let totalSpacing = size.width * 0.4
            let barWidth = (size.width - totalSpacing) / CGFloat(count)
            let gapWidth = totalSpacing / CGFloat(count)

            for (index, level) in levels.enumerated() {
                let barHeight = max(4, CGFloat(level) * size.height * 0.9)
                let x = CGFloat(index) * (barWidth + gapWidth)
                let y = (size.height - barHeight) / 2
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                let opacity = Double(0.35 + 0.65 * min(CGFloat(level), 1.0))
                context.fill(path, with: .color(color.opacity(opacity)))
            }
        }
    }
}

// MARK: - Loading Dots View
struct LoadingDotsView: View {
    @State private var animatingDots: [Bool] = [false, false, false]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDots[index] ? 1.0 : 0.5)
                    .opacity(animatingDots[index] ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animatingDots[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<3 {
                animatingDots[index] = true
            }
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    init(icon: String, title: String, isSelected: Bool = false, badge: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.badge = badge
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .textSecondary)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white : .textSecondary)

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.cardBg)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                    .fill(isSelected ? Color.cardBg : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page Header
struct PageHeader: View {
    let icon: String
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?
    let actionIcon: String?

    init(
        icon: String,
        title: String,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        actionIcon: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
        self.actionIcon = actionIcon
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                if let action = action, let label = actionLabel {
                    Button(action: action) {
                        if let icon = actionIcon {
                            Label(label, systemImage: icon)
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Text(label)
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, AppDesign.defaultPadding)
            .padding(.vertical, 12)
            .background(Color.sidebarBg)

            AppDivider()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.textSecondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Growing Text Editor (macOS: no internal scroll, expands to content height)
#if os(macOS)
import AppKit

/// Content-height text editor backed by NSTextView without NSScrollView.
/// Place inside a SwiftUI ScrollView; the outer ScrollView handles all scrolling.
struct GrowingTextEditor: View {
    @Binding var text: String
    var fontSize: CGFloat = 16
    var lineSpacing: CGFloat = 7
    var foregroundColor: Color = .textPrimary
    var minHeight: CGFloat = 300
    var markdownStyling: Bool = false

    @State private var height: CGFloat = 300

    var body: some View {
        _GrowingTextViewRepresentable(
            text: $text,
            height: $height,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            foregroundColor: foregroundColor,
            markdownStyling: markdownStyling
        )
        .frame(height: max(minHeight, height))
    }
}

private extension NSAttributedString.Key {
    static let listMarker = NSAttributedString.Key("com.meetingnote.listMarker")
}

// MARK: - Markdown Layout Manager (불렛/체크박스 마커 직접 렌더링)
private class MarkdownLayoutManager: NSLayoutManager {
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard let ts = textStorage else { return }
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        ts.enumerateAttribute(.listMarker, in: charRange, options: []) { value, range, _ in
            guard let marker = value as? String, !marker.isEmpty else { return }
            let paraStart = range.location
            let glyphIdx = self.glyphRange(
                forCharacterRange: NSRange(location: paraStart, length: 1),
                actualCharacterRange: nil
            ).location
            guard glyphIdx < self.numberOfGlyphs else { return }

            // lineRect + 폰트 메트릭으로 baseline 계산 (프리픽스 font 0.01에 무관)
            let lineRect = self.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: nil)
            let markerFont = NSFont.systemFont(ofSize: (textStorage as? MarkdownTextStorage)?.fontSize ?? 16)
            let baseline = origin.y + lineRect.origin.y + markerFont.ascender

            let indent = (ts.attribute(.paragraphStyle, at: paraStart, effectiveRange: nil)
                            as? NSParagraphStyle)?.headIndent ?? 20
            let lineTop = baseline - markerFont.ascender

            if marker == "☐" || marker == "☑" {
                let boxSize: CGFloat = 14
                let bx = origin.x + indent - boxSize - 5
                let by = lineTop + (markerFont.ascender - boxSize) / 2
                let boxRect = NSRect(x: bx, y: by, width: boxSize, height: boxSize)
                let path = NSBezierPath(roundedRect: boxRect, xRadius: 3, yRadius: 3)
                if marker == "☑" {
                    NSColor(Color.appPrimary).setFill()
                    path.fill()
                    let check = NSBezierPath()
                    check.move(to: NSPoint(x: bx + 3.5, y: by + boxSize / 2))
                    check.line(to: NSPoint(x: bx + 6, y: by + boxSize - 3.5))
                    check.line(to: NSPoint(x: bx + boxSize - 3, y: by + 3.5))
                    NSColor(Color.textPrimary).setStroke()
                    check.lineWidth = 1.8
                    check.lineCapStyle = .round
                    check.lineJoinStyle = .round
                    check.stroke()
                } else {
                    NSColor(Color.appSecondary).setStroke()
                    path.lineWidth = 1.3
                    path.stroke()
                }
            } else {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: markerFont,
                    .foregroundColor: NSColor(Color.textPrimary)
                ]
                let ns = marker as NSString
                let sz = ns.size(withAttributes: attrs)
                let x = origin.x + indent - sz.width - 4
                let y = lineTop + (markerFont.ascender - sz.height) / 2
                ns.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
            }
        }
    }
}

// MARK: - Markdown Text View (IME-aware NSTextView subclass + 체크박스 클릭)
private class MarkdownTextView: NSTextView {
    var isComposing = false

    override func setMarkedText(_ string: Any, selectedRange: NSRange,
                                replacementRange: NSRange) {
        isComposing = true
        super.setMarkedText(string, selectedRange: selectedRange,
                            replacementRange: replacementRange)
    }
    override func unmarkText() {
        isComposing = false
        super.unmarkText()
    }
    override func insertText(_ string: Any, replacementRange: NSRange) {
        isComposing = false
        super.insertText(string, replacementRange: replacementRange)
    }
    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    // MARK: Enter — 리스트 연속 (Notion 스타일)
    override func insertNewline(_ sender: Any?) {
        guard let ts = textStorage else {
            super.insertNewline(sender)
            return
        }
        let nsStr = ts.string as NSString
        let cursorLoc = selectedRange().location
        guard cursorLoc <= nsStr.length else {
            super.insertNewline(sender)
            return
        }
        let lineRange = nsStr.lineRange(for: NSRange(location: cursorLoc, length: 0))
        let line = nsStr.substring(with: lineRange)
        let trimLine = line.hasSuffix("\n") ? String(line.dropLast()) : line

        // 불렛: "- " 또는 "* "
        if trimLine.hasPrefix("- ") || trimLine.hasPrefix("* ") {
            let bulletChar = String(trimLine.prefix(2))
            if trimLine == "-" || trimLine == "- "
                || trimLine == "*" || trimLine == "* " {
                let contentLen = line.hasSuffix("\n") ? lineRange.length - 1 : lineRange.length
                let replaceRange = NSRange(location: lineRange.location, length: contentLen)
                if shouldChangeText(in: replaceRange, replacementString: "") {
                    ts.replaceCharacters(in: replaceRange, with: "")
                    didChangeText()
                }
                return
            }
            super.insertNewline(sender)
            insertText(bulletChar, replacementRange: NSRange(location: selectedRange().location, length: 0))
            return
        }

        // 체크박스: "[]" 또는 "[x]"
        if trimLine.hasPrefix("[]") || trimLine.lowercased().hasPrefix("[x]") {
            let content = trimLine.hasPrefix("[]")
                ? trimLine.dropFirst(2).trimmingCharacters(in: .whitespaces)
                : trimLine.dropFirst(3).trimmingCharacters(in: .whitespaces)
            if content.isEmpty {
                let contentLen = line.hasSuffix("\n") ? lineRange.length - 1 : lineRange.length
                let replaceRange = NSRange(location: lineRange.location, length: contentLen)
                if shouldChangeText(in: replaceRange, replacementString: "") {
                    ts.replaceCharacters(in: replaceRange, with: "")
                    didChangeText()
                }
                return
            }
            super.insertNewline(sender)
            insertText("[] ", replacementRange: NSRange(location: selectedRange().location, length: 0))
            return
        }

        // 오더리스트: "N. "
        let sns = trimLine as NSString
        var n = 0
        while n < sns.length && sns.character(at: n) >= "0".utf16.first! && sns.character(at: n) <= "9".utf16.first! { n += 1 }
        if n > 0 && n + 1 < sns.length && sns.character(at: n) == ".".utf16.first! && sns.character(at: n + 1) == " ".utf16.first! {
            let numStr = String(trimLine.prefix(n))
            let num = (Int(numStr) ?? 0) + 1
            let body = trimLine.dropFirst(n + 2).trimmingCharacters(in: .whitespaces)
            if body.isEmpty {
                let contentLen = line.hasSuffix("\n") ? lineRange.length - 1 : lineRange.length
                let replaceRange = NSRange(location: lineRange.location, length: contentLen)
                if shouldChangeText(in: replaceRange, replacementString: "") {
                    ts.replaceCharacters(in: replaceRange, with: "")
                    didChangeText()
                }
                return
            }
            super.insertNewline(sender)
            insertText("\(num). ", replacementRange: NSRange(location: selectedRange().location, length: 0))
            return
        }

        super.insertNewline(sender)
    }

    // MARK: 체크박스 클릭 토글
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if toggleCheckboxIfHit(at: point) { return }
        super.mouseDown(with: event)
    }

    private func toggleCheckboxIfHit(at point: NSPoint) -> Bool {
        guard let ts = textStorage, let lm = layoutManager, let tc = textContainer else { return false }
        let origin = textContainerOrigin
        let adjusted = NSPoint(x: point.x - origin.x, y: point.y - origin.y)

        // 클릭 위치에서 가장 가까운 글리프 → 해당 줄의 paragraph 시작 찾기
        let glyphIdx = lm.glyphIndex(for: adjusted, in: tc)
        let charIdx = lm.characterIndexForGlyph(at: glyphIdx)
        let nsStr = ts.string as NSString
        let lineRange = nsStr.lineRange(for: NSRange(location: charIdx, length: 0))
        let line = nsStr.substring(with: lineRange)
        let trimLine = line.hasSuffix("\n") ? String(line.dropLast()) : line

        // 체크박스 줄인지 확인
        let isUnchecked = trimLine.hasPrefix("[]")
        let isChecked = trimLine.lowercased().hasPrefix("[x]")
        guard isUnchecked || isChecked else { return false }

        // 클릭이 마커 영역(headIndent 왼쪽)에 있는지 확인
        let indent = (ts.attribute(.paragraphStyle, at: lineRange.location, effectiveRange: nil)
                        as? NSParagraphStyle)?.headIndent ?? 20
        if adjusted.x > indent + origin.x + 4 { return false }

        // 토글: [] ↔ [x]
        let prefixLen = isUnchecked ? 2 : 3
        let replacement = isUnchecked ? "[x]" : "[]"
        let prefixRange = NSRange(location: lineRange.location, length: prefixLen)

        if shouldChangeText(in: prefixRange, replacementString: replacement) {
            ts.replaceCharacters(in: prefixRange, with: replacement)
            didChangeText()
        }
        return true
    }
}

// MARK: - Markdown Text Storage (inline syntax highlighting)
private class MarkdownTextStorage: NSTextStorage {
    private let backing = NSMutableAttributedString()
    var fontSize: CGFloat
    var lineSpacing: CGFloat

    // Pre-compiled regexes
    private static let codeRE     = try! NSRegularExpression(pattern: "`([^`]+?)`")
    private static let strikeRE   = try! NSRegularExpression(pattern: "~~(.+?)~~")

    init(fontSize: CGFloat, lineSpacing: CGFloat) {
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
    required init?(pasteboardPropertyList propertyList: Any, ofType dataType: NSPasteboard.PasteboardType) { fatalError() }

    // MARK: NSTextStorage Primitives
    override var string: String { backing.string }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard location < backing.length else { range?.pointee = NSRange(location: location, length: 0); return [:] }
        return backing.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backing.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        guard range.location != NSNotFound, range.location + range.length <= backing.length else { return }
        beginEditing()
        backing.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    private var highlightScheduled = false

    override func processEditing() {
        super.processEditing()
        // 하이라이팅을 다음 run loop으로 지연
        // — 동기 실행 시 IME 조합 완료 직후 전체 attribute reset이 글자 렌더링 깨뜨림
        // — baseline 기반 마커 좌표는 지연에도 안정적
        if !highlightScheduled {
            highlightScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self, self.backing.length > 0 else {
                    self?.highlightScheduled = false
                    return
                }
                // IME 조합 중이면 스킵 — 다음 편집 시 재시도
                for lm in self.layoutManagers {
                    for tc in lm.textContainers {
                        if let tv = tc.textView, tv.hasMarkedText() {
                            self.highlightScheduled = false
                            return
                        }
                    }
                }
                self.beginEditing()
                self.applyHighlighting()
                self.edited(.editedAttributes,
                            range: NSRange(location: 0, length: self.backing.length),
                            changeInLength: 0)
                self.endEditing()
                self.highlightScheduled = false
            }
        }
    }

    // MARK: Colors & Fonts
    private func basePara() -> NSMutableParagraphStyle {
        let p = NSMutableParagraphStyle(); p.lineSpacing = lineSpacing; return p
    }
    private var textClr:    NSColor { NSColor(Color.textPrimary) }
    private var dimClr:     NSColor { NSColor(Color.textTertiary) }
    private var headingClr: NSColor { NSColor(Color.textPrimary) }
    private var strikeClr:  NSColor { NSColor(Color.textSecondary) }
    private func bodyFont(_ s: CGFloat? = nil) -> NSFont { NSFont.systemFont(ofSize: s ?? fontSize) }
    private func boldFont(_ s: CGFloat? = nil) -> NSFont { NSFont.systemFont(ofSize: s ?? fontSize, weight: .bold) }
    private func monoFont()                    -> NSFont { NSFont.monospacedSystemFont(ofSize: max(fontSize - 1, 12), weight: .regular) }
    private func listParaStyle(headIndent: CGFloat = 20) -> NSMutableParagraphStyle {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = lineSpacing
        para.headIndent = headIndent
        para.firstLineHeadIndent = headIndent
        let font = NSFont.systemFont(ofSize: fontSize)
        para.minimumLineHeight = font.ascender - font.descender + font.leading
        return para
    }

    // MARK: Highlight
    private func applyHighlighting() {
        let str = backing.string
        guard !str.isEmpty else { return }
        let nsStr = str as NSString
        let total = nsStr.length
        let full  = NSRange(location: 0, length: total)

        // 1 — Reset base
        backing.setAttributes([
            .font: bodyFont(), .foregroundColor: textClr,
            .paragraphStyle: basePara(), .strikethroughStyle: 0,
            .backgroundColor: NSColor.clear
        ], range: full)

        // 2 — Block-level (line by line)
        var loc = 0
        var inCode = false
        while loc < total {
            let lr = nsStr.lineRange(for: NSRange(location: loc, length: 0))
            guard lr.length > 0 else { break }
            let line        = nsStr.substring(with: lr)
            let lineContent = line.hasSuffix("\n") ? String(line.dropLast()) : line
            let cLen        = line.hasSuffix("\n") ? lr.length - 1 : lr.length
            let cr          = NSRange(location: lr.location, length: cLen)

            if lineContent.hasPrefix("```") {
                inCode.toggle()
                backing.addAttributes([.foregroundColor: dimClr, .font: monoFont()], range: cr)
            } else if inCode {
                backing.addAttributes([.font: monoFont(), .foregroundColor: NSColor(white: 0.70, alpha: 1.0)], range: cr)
            } else {
                applyBlockLine(lineContent: lineContent, cr: cr)
            }
            loc = NSMaxRange(lr)
        }

        // 3 — Inline styles
        applyInline(in: str, full: full)
    }

    private func applyBlockLine(lineContent: String, cr: NSRange) {
        // prefix를 완전히 숨김: 투명 + 극소 폰트로 공간 제거
        let hideAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 0.01)
        ]
        func hidePrefix(_ len: Int) {
            let p = min(len, cr.length)
            if p > 0 { backing.addAttributes(hideAttrs,
                                             range: NSRange(location: cr.location, length: p)) }
        }
        func heading(_ size: CGFloat, prefix: Int) {
            backing.addAttributes([.font: boldFont(size), .foregroundColor: headingClr,
                                   .paragraphStyle: basePara()], range: cr)
            let p = min(prefix, cr.length)
            if p > 0 {
                backing.addAttributes([
                    .foregroundColor: NSColor.clear,
                    .font: NSFont.systemFont(ofSize: 0.01)
                ], range: NSRange(location: cr.location, length: p))
            }
        }

        if      lineContent.hasPrefix("### ") { heading(fontSize + 3,  prefix: 4) }
        else if lineContent.hasPrefix("## ")  { heading(fontSize + 6,  prefix: 3) }
        else if lineContent.hasPrefix("# ")   { heading(fontSize + 10, prefix: 2) }
        else if lineContent == "---" || lineContent == "***" || lineContent == "___" {
            backing.addAttribute(.foregroundColor, value: dimClr, range: cr)
        }
        // 체크박스 checked: [x]
        else if lineContent.lowercased().hasPrefix("[x]") {
            let pLen = lineContent.count > 3 && lineContent.dropFirst(3).first == " " ? 4 : 3
            backing.addAttributes([
                .paragraphStyle: listParaStyle(),
                .listMarker: "☑",
                .foregroundColor: strikeClr,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ], range: cr)
            hidePrefix(pLen)
        }
        // 체크박스 unchecked: []
        else if lineContent.hasPrefix("[]") {
            let pLen = lineContent.count > 2 && lineContent.dropFirst(2).first == " " ? 3 : 2
            backing.addAttributes([
                .paragraphStyle: listParaStyle(),
                .listMarker: "☐"
            ], range: cr)
            hidePrefix(pLen)
        }
        // 불렛: - / *
        else if lineContent.hasPrefix("- ") || lineContent.hasPrefix("* ") {
            backing.addAttributes([
                .paragraphStyle: listParaStyle(),
                .listMarker: "•"
            ], range: cr)
            hidePrefix(2)
        }
        else {
            // 순서 있는 목록: N. text
            let tns = lineContent as NSString
            var n = 0
            while n < tns.length && tns.character(at: n) >= "0".utf16.first! && tns.character(at: n) <= "9".utf16.first! { n += 1 }
            if n > 0 && n + 1 < tns.length
               && tns.character(at: n) == ".".utf16.first!
               && tns.character(at: n + 1) == " ".utf16.first! {
                let numStr = String(lineContent.prefix(n))
                backing.addAttributes([
                    .paragraphStyle: listParaStyle(),
                    .listMarker: numStr + "."
                ], range: cr)
                hidePrefix(n + 2)
            }
        }
    }

    private func applyInline(in str: String, full: NSRange) {
        // Code `…`
        Self.codeRE.enumerateMatches(in: str, range: full) { [weak self] m, _, _ in
            guard let self, let m, m.range.length >= 2 else { return }
            let loc = m.range.location, len = m.range.length
            self.backing.addAttributes([.font: self.monoFont(), .backgroundColor: NSColor(Color.cardBg)], range: m.range)
            self.backing.addAttribute(.foregroundColor, value: self.dimClr, range: NSRange(location: loc, length: 1))
            self.backing.addAttribute(.foregroundColor, value: self.dimClr, range: NSRange(location: loc + len - 1, length: 1))
        }
        // Strikethrough ~~…~~
        Self.strikeRE.enumerateMatches(in: str, range: full) { [weak self] m, _, _ in
            guard let self, let m else { return }
            self.backing.addAttributes([.strikethroughStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: self.strikeClr], range: m.range)
        }
    }
}

private struct _GrowingTextViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let foregroundColor: Color
    let markdownStyling: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextView {
        let tv: NSTextView
        if markdownStyling {
            let storage = MarkdownTextStorage(fontSize: fontSize, lineSpacing: lineSpacing)
            let lm = MarkdownLayoutManager()
            storage.addLayoutManager(lm)
            let tc = NSTextContainer()
            tc.widthTracksTextView = true
            lm.addTextContainer(tc)
            tv = MarkdownTextView(frame: .zero, textContainer: tc)
        } else {
            tv = NSTextView()
        }
        tv.isEditable = true
        tv.isSelectable = true
        tv.isRichText = true
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.textContainerInset = NSSize(width: 0, height: 8)
        tv.delegate = context.coordinator
        context.coordinator.textView = tv
        if !markdownStyling {
            tv.typingAttributes = context.coordinator.textAttributes
        }
        return tv
    }

    func updateNSView(_ tv: NSTextView, context: Context) {
        context.coordinator.parent = self
        if tv.string != text && !tv.hasMarkedText() && !context.coordinator.isSyncingToSwiftUI {
            if markdownStyling, let storage = tv.textStorage as? MarkdownTextStorage {
                let sel = tv.selectedRange()
                storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
                if NSMaxRange(sel) <= (tv.string as NSString).length { tv.setSelectedRange(sel) }
            } else {
                tv.textStorage?.setAttributedString(
                    NSAttributedString(string: text, attributes: context.coordinator.textAttributes)
                )
            }
        }
        if markdownStyling {
            let para = NSMutableParagraphStyle(); para.lineSpacing = lineSpacing
            tv.typingAttributes = [.font: NSFont.systemFont(ofSize: fontSize),
                                   .foregroundColor: NSColor(white: 0.88, alpha: 1.0),
                                   .paragraphStyle: para]
        } else {
            tv.typingAttributes = context.coordinator.textAttributes
        }
        context.coordinator.recalcHeight()
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: _GrowingTextViewRepresentable
        weak var textView: NSTextView?
        var isSyncingToSwiftUI = false

        init(_ parent: _GrowingTextViewRepresentable) { self.parent = parent }

        var textAttributes: [NSAttributedString.Key: Any] {
            let para = NSMutableParagraphStyle()
            para.lineSpacing = parent.lineSpacing
            return [
                .font: NSFont.systemFont(ofSize: parent.fontSize),
                .foregroundColor: NSColor(parent.foregroundColor),
                .paragraphStyle: para
            ]
        }

        func recalcHeight() {
            guard let tv = textView,
                  let lm = tv.layoutManager,
                  let tc = tv.textContainer else { return }
            lm.ensureLayout(for: tc)
            let newH = lm.usedRect(for: tc).height + tv.textContainerInset.height * 2
            guard abs(parent.height - newH) > 1 else { return }
            DispatchQueue.main.async { [weak self] in self?.parent.height = newH }
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            // 한글/CJK IME 조합 중에는 스킵 (marked text = 조합 진행 중)
            if tv.hasMarkedText() { return }
            isSyncingToSwiftUI = true
            parent.text = tv.string
            isSyncingToSwiftUI = false
            recalcHeight()
        }
    }
}

// MARK: - Markdown Editor (inline markdown styling, no mode switch)
struct MarkdownEditor: View {
    @Binding var text: String
    var fontSize: CGFloat = 16
    var lineSpacing: CGFloat = 7

    var body: some View {
        GrowingTextEditor(
            text: $text,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            markdownStyling: true
        )
    }
}
#endif

// MARK: - Markdown Block
enum MarkdownBlock {
    case heading(Int, String)
    case bullet(String)
    case taskUnchecked(String)
    case taskChecked(String)
    case orderedItem(Int, String)
    case codeBlock(String)
    case divider
    case spacer
    case paragraph(String)
}

private func parseOrderedItem(_ s: String) -> (Int, String)? {
    var idx = s.startIndex
    var numStr = ""
    while idx < s.endIndex && s[idx].isNumber {
        numStr.append(s[idx])
        idx = s.index(after: idx)
    }
    guard !numStr.isEmpty,
          idx < s.endIndex, s[idx] == ".",
          let nextIdx = s.index(idx, offsetBy: 1, limitedBy: s.endIndex),
          nextIdx < s.endIndex, s[nextIdx] == " ",
          let num = Int(numStr) else { return nil }
    let rest = String(s[s.index(idx, offsetBy: 2)...]).trimmingCharacters(in: .whitespaces)
    return (num, rest)
}

private func parseBlocks(_ text: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    let lines = text.components(separatedBy: "\n")
    var i = 0

    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("```") {
            i += 1
            var codeLines: [String] = []
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
            i += 1
            continue
        }

        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            blocks.append(.divider)
        } else if trimmed.hasPrefix("### ") {
            blocks.append(.heading(3, String(trimmed.dropFirst(4))))
        } else if trimmed.hasPrefix("## ") {
            blocks.append(.heading(2, String(trimmed.dropFirst(3))))
        } else if trimmed.hasPrefix("# ") {
            blocks.append(.heading(1, String(trimmed.dropFirst(2))))
        } else if trimmed.hasPrefix("- [ ] ") {
            blocks.append(.taskUnchecked(String(trimmed.dropFirst(6))))
        } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            blocks.append(.taskChecked(String(trimmed.dropFirst(6))))
        } else if trimmed.hasPrefix("- ") {
            blocks.append(.bullet(String(trimmed.dropFirst(2))))
        } else if trimmed.hasPrefix("* ") {
            blocks.append(.bullet(String(trimmed.dropFirst(2))))
        } else if trimmed.isEmpty {
            blocks.append(.spacer)
        } else if let (num, itemText) = parseOrderedItem(trimmed) {
            blocks.append(.orderedItem(num, itemText))
        } else {
            blocks.append(.paragraph(trimmed))
        }

        i += 1
    }

    return blocks
}

// MARK: - Markdown View
struct MarkdownView: View {
    let text: String
    var fontSize: CGFloat = 16
    var lineSpacing: CGFloat = 7

    var blocks: [MarkdownBlock] { parseBlocks(text) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
                    .padding(.bottom, lineSpacing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let content):
            let size: CGFloat = level == 1 ? fontSize + 10 : (level == 2 ? fontSize + 6 : fontSize + 3)
            Text(content)
                .font(.system(size: size, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, level == 1 ? 8 : 4)

        case .bullet(let content):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•")
                    .font(.system(size: fontSize))
                    .foregroundColor(.textSecondary)
                Text(content)
                    .font(.system(size: fontSize))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(lineSpacing)
            }

        case .taskUnchecked(let content):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "square")
                    .font(.system(size: fontSize - 2))
                    .foregroundColor(.textSecondary)
                Text(content)
                    .font(.system(size: fontSize))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(lineSpacing)
            }

        case .taskChecked(let content):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: fontSize - 2))
                    .foregroundColor(.appPrimary)
                Text(content)
                    .font(.system(size: fontSize))
                    .foregroundColor(.textSecondary)
                    .strikethrough()
                    .lineSpacing(lineSpacing)
            }

        case .orderedItem(let num, let content):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(num).")
                    .font(.system(size: fontSize))
                    .foregroundColor(.textSecondary)
                    .frame(minWidth: 20, alignment: .trailing)
                Text(content)
                    .font(.system(size: fontSize))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(lineSpacing)
            }

        case .codeBlock(let code):
            Text(code)
                .font(.system(size: fontSize - 1, design: .monospaced))
                .foregroundColor(.textPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                        .fill(Color.cardBg)
                )

        case .divider:
            Divider()
                .padding(.vertical, 4)

        case .spacer:
            Color.clear.frame(height: 8)

        case .paragraph(let content):
            Text(content)
                .font(.system(size: fontSize))
                .foregroundColor(.textPrimary)
                .lineSpacing(lineSpacing)
        }
    }
}
