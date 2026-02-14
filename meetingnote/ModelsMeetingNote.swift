//
//  MeetingNote.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class MeetingNote {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    // 녹음 파일 경로
    var audioFileURL: URL?
    
    // 전사된 원본 텍스트
    var transcribedText: String
    
    // 사용자가 편집한 마크다운 텍스트
    var editedMarkdown: String
    
    // LLM으로 후가공된 텍스트 (legacy)
    var processedText: String?

    // AI 결과물 (항목별)
    var summaryText: String?
    var minutesText: String?
    var actionItemsText: String?

    // 커스텀 AI 결과물 목록 (커스텀1, 커스텀2, ...)
    var customResults: [String]
    var customResultNames: [String]

    // 녹음 시간 (초 단위)
    var duration: TimeInterval

    // 태그
    var tags: [String]

    var hasAIContent: Bool {
        summaryText != nil || minutesText != nil || actionItemsText != nil || !customResults.isEmpty || processedText != nil
    }

    init(
        title: String,
        audioFileURL: URL? = nil,
        transcribedText: String = "",
        editedMarkdown: String = "",
        processedText: String? = nil,
        duration: TimeInterval = 0,
        tags: [String] = [],
        customResults: [String] = [],
        customResultNames: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.audioFileURL = audioFileURL
        self.transcribedText = transcribedText
        self.editedMarkdown = editedMarkdown
        self.processedText = processedText
        self.duration = duration
        self.tags = tags
        self.customResults = customResults
        self.customResultNames = customResultNames
    }
}
