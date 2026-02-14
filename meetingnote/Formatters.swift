//
//  Formatters.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import Foundation

// MARK: - Date Formatter
extension DateFormatter {
    static let appDefault: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Markdown Strip (리스트 미리보기용)
extension String {
    /// 블록 수준 마크다운 prefix를 제거한 평문 반환 (목록 미리보기 전용)
    var strippedMarkdown: String {
        let lines = self.components(separatedBy: "\n")
        let stripped = lines.compactMap { line -> String? in
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("```") || t == "---" || t == "***" || t == "___" { return nil }
            if t.hasPrefix("### ") { return String(t.dropFirst(4)) }
            if t.hasPrefix("## ")  { return String(t.dropFirst(3)) }
            if t.hasPrefix("# ")   { return String(t.dropFirst(2)) }
            if t.lowercased().hasPrefix("[x] ") { return String(t.dropFirst(4)) }
            if t.hasPrefix("[] ")  { return String(t.dropFirst(3)) }
            if t.hasPrefix("[]")   { return String(t.dropFirst(2)) }
            if t.lowercased().hasPrefix("- [x] ") { return String(t.dropFirst(6)) }
            if t.hasPrefix("- [ ] ") { return String(t.dropFirst(6)) }
            if t.hasPrefix("- ")   { return String(t.dropFirst(2)) }
            if t.hasPrefix("* ")   { return String(t.dropFirst(2)) }
            // 순서 있는 목록: N. text
            let ns = t as NSString
            var n = 0
            while n < ns.length && ns.character(at: n) >= 48 && ns.character(at: n) <= 57 { n += 1 }
            if n > 0 && n + 1 < ns.length && ns.character(at: n) == 46 && ns.character(at: n + 1) == 32 {
                return String(t.dropFirst(n + 2))
            }
            return t
        }
        return stripped.joined(separator: " ")
    }
}

// MARK: - TimeInterval Formatting
extension TimeInterval {
    func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
