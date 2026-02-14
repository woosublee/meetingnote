//
//  LLMProcessor.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import Foundation
import FoundationModels

@MainActor
@Observable
final class LLMProcessor {
    var isAvailable: Bool {
        return model.availability == .available
    }

    var availabilityStatus: String {
        switch model.availability {
        case .available:
            return "사용 가능"
        case .unavailable(.deviceNotEligible):
            return "이 기기는 Apple Intelligence를 지원하지 않습니다"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "설정 > Apple Intelligence에서 기능을 활성화해주세요"
        case .unavailable(.modelNotReady):
            return "AI 모델 다운로드 중입니다. 잠시 후 다시 시도해주세요."
        case .unavailable:
            return "AI 모델을 사용할 수 없습니다"
        @unknown default:
            return "알 수 없는 상태"
        }
    }

    private let model = SystemLanguageModel.default

    private let insufficientTextMessage = "원본 텍스트 내용이 부족합니다"

    // MARK: - 요약

    func summarize(text: String) async throws -> String {
        guard isAvailable else { throw LLMError.modelUnavailable }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return insufficientTextMessage
        }

        let instructions = """
        You are a professional meeting summarizer.
        Read the provided Korean meeting transcript and extract the key content clearly and concisely.
        Convert colloquial speech into natural written Korean, and remove redundant content.
        Always write your output in Korean using markdown format.
        Base your summary strictly on the provided transcript. Do not add information that is not in the text.
        """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
        Summarize the following Korean meeting transcript. Write the output in Korean.

        [Transcript]
        \(text)

        Use this format:

        ## 핵심 요약
        (2~4 sentences summarizing the entire content)

        ## 주요 논의 사항
        - (key points by topic)

        ## 결정된 사항
        - (only clearly decided items)
        """

        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: - 회의록

    func formatAsMeetingMinutes(text: String) async throws -> String {
        guard isAvailable else { throw LLMError.modelUnavailable }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return insufficientTextMessage
        }

        let instructions = """
        You are a professional meeting minutes writer.
        Convert the provided Korean meeting transcript into formal meeting minutes.
        Transform colloquial speech into formal written Korean and structure the content logically.
        Always write your output in Korean using markdown format.
        Only include information that appears in the transcript. Omit sections you cannot fill from the text.
        """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
        Convert the following Korean meeting transcript into formal meeting minutes. Write in Korean.

        [Transcript]
        \(text)

        Use this format (omit sections that cannot be filled from the transcript):

        # 회의록

        ## 일시
        (if determinable from transcript, otherwise omit)

        ## 참석자
        (only names mentioned in the transcript)

        ## 안건
        (main topics discussed)

        ## 논의 내용
        (structured by topic)

        ## 결정 사항
        (clearly decided items only)

        ## 후속 조치
        (agreed next steps or tasks)
        """

        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: - 커스텀 프롬프트

    func processWithCustomPrompt(text: String, prompt: String) async throws -> String {
        guard isAvailable else { throw LLMError.modelUnavailable }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return insufficientTextMessage
        }

        // 사용자가 입력한 프롬프트를 instructions(시스템 프롬프트)로 직접 전달
        let session = LanguageModelSession(instructions: prompt)

        let fullPrompt = """
        [Meeting Transcript]
        \(text)
        """

        let response = try await session.respond(to: fullPrompt)
        return response.content
    }

    // MARK: - 액션 아이템 추출

    @Generable(description: "Action items extracted from the meeting")
    struct ActionItems {
        @Guide(description: "List of specific actionable tasks starting with a verb, written in Korean.", .count(1...20))
        var tasks: [String]

        @Guide(description: "Person or team responsible for each task. Use '미정' if unknown. Must match tasks order.")
        var assignees: [String]

        @Guide(description: "Due date for each task in YYYY-MM-DD format if mentioned, otherwise '미정'. Must match tasks order.")
        var dueDates: [String]
    }

    func extractActionItems(text: String) async throws -> ActionItems {
        guard isAvailable else { throw LLMError.modelUnavailable }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ActionItems(tasks: ["원본 텍스트 내용이 부족합니다"], assignees: ["미정"], dueDates: ["미정"])
        }

        let instructions = """
        You are an expert at extracting actionable items from meeting transcripts.
        Extract only specific and actionable tasks from the provided Korean transcript.
        Ignore vague statements. If no responsible person is mentioned, use '미정'.
        Write task descriptions in Korean.
        """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
        Extract all action items from the following Korean meeting transcript.

        [Transcript]
        \(text)

        For each action item identify:
        - What needs to be done (specific action, in Korean)
        - Who is responsible (person or team name)
        - When it is due (date if mentioned)
        """

        let response = try await session.respond(to: prompt, generating: ActionItems.self)
        return response.content
    }
}

// MARK: - 에러 타입

enum LLMError: LocalizedError {
    case modelUnavailable
    case processingFailed
    case insufficientText

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence를 사용할 수 없습니다."
        case .processingFailed:
            return "텍스트 처리에 실패했습니다."
        case .insufficientText:
            return "원본 텍스트 내용이 부족합니다."
        }
    }
}
