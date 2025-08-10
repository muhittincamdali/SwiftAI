import Foundation
import NaturalLanguage
import CoreML

public class TextProcessor {
    
    // MARK: - Properties
    
    private let languageRecognizer = NLLanguageRecognizer()
    private let tokenizer = NLTokenizer(unit: .word)
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .nameTypeOrLexicalClass])
    
    // MARK: - Text Analysis
    
    public func analyzeText(_ text: String) async throws -> TextAnalysisResult {
        let startTime = Date()
        
        // Perform comprehensive text analysis
        let language = try await detectLanguage(text)
        let sentiment = try await analyzeSentiment(text)
        let entities = try await extractEntities(text)
        let keywords = try await extractKeywords(text)
        let summary = try await generateSummary(text)
        let complexity = try await analyzeComplexity(text)
        let topics = try await extractTopics(text)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return TextAnalysisResult(
            language: language,
            sentiment: sentiment,
            entities: entities,
            keywords: keywords,
            summary: summary,
            complexity: complexity,
            topics: topics,
            processingTime: processingTime,
            wordCount: text.split(separator: " ").count,
            characterCount: text.count,
            sentenceCount: text.split(separator: ".").count
        )
    }
    
    // MARK: - Language Detection
    
    public func detectLanguage(_ text: String) async throws -> LanguageInfo {
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        
        guard let language = languageRecognizer.dominantLanguage else {
            throw TextProcessingError.languageDetectionFailed
        }
        
        let confidence = languageRecognizer.languageHypotheses(withMaximum: 1)[language] ?? 0.0
        
        return LanguageInfo(
            code: language.rawValue,
            name: language.localizedString(for: language.rawValue),
            confidence: confidence,
            isReliable: confidence > 0.8
        )
    }
    
    // MARK: - Sentiment Analysis
    
    public func analyzeSentiment(_ text: String) async throws -> SentimentAnalysisResult {
        let words = text.lowercased().split(separator: " ")
        
        // Positive and negative word dictionaries
        let positiveWords = Set([
            "good", "great", "excellent", "amazing", "wonderful", "love", "happy",
            "fantastic", "brilliant", "outstanding", "perfect", "beautiful", "awesome",
            "incredible", "marvelous", "splendid", "superb", "terrific", "magnificent"
        ])
        
        let negativeWords = Set([
            "bad", "terrible", "awful", "hate", "sad", "angry", "disappointed",
            "horrible", "dreadful", "miserable", "terrible", "awful", "horrendous",
            "atrocious", "abysmal", "appalling", "dismal", "lousy", "pathetic"
        ])
        
        let positiveCount = words.filter { positiveWords.contains(String($0)) }.count
        let negativeCount = words.filter { negativeWords.contains(String($0)) }.count
        let totalWords = words.count
        
        let positiveScore = totalWords > 0 ? Double(positiveCount) / Double(totalWords) : 0.0
        let negativeScore = totalWords > 0 ? Double(negativeCount) / Double(totalWords) : 0.0
        let neutralScore = 1.0 - positiveScore - negativeScore
        
        let dominantSentiment: SentimentType
        let confidence: Double
        
        if positiveScore > negativeScore && positiveScore > neutralScore {
            dominantSentiment = .positive
            confidence = positiveScore
        } else if negativeScore > positiveScore && negativeScore > neutralScore {
            dominantSentiment = .negative
            confidence = negativeScore
        } else {
            dominantSentiment = .neutral
            confidence = neutralScore
        }
        
        return SentimentAnalysisResult(
            type: dominantSentiment,
            positiveScore: positiveScore,
            negativeScore: negativeScore,
            neutralScore: neutralScore,
            confidence: confidence,
            keywords: Array(positiveWords.union(negativeWords).intersection(Set(words.map(String.init))))
        )
    }
    
    // MARK: - Entity Extraction
    
    public func extractEntities(_ text: String) async throws -> [Entity] {
        tagger.string = text
        var entities: [Entity] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let entityText = String(text[tokenRange])
                let entityType = mapNLTagToEntityType(tag)
                
                let entity = Entity(
                    text: entityText,
                    type: entityType,
                    range: tokenRange,
                    confidence: 0.9
                )
                entities.append(entity)
            }
            return true
        }
        
        return entities
    }
    
    // MARK: - Keyword Extraction
    
    public func extractKeywords(_ text: String) async throws -> [Keyword] {
        let words = text.lowercased().split(separator: " ")
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"])
        
        let filteredWords = words.filter { word in
            let wordStr = String(word)
            return !stopWords.contains(wordStr) && wordStr.count > 2
        }
        
        var wordFrequency: [String: Int] = [:]
        for word in filteredWords {
            wordFrequency[String(word), default: 0] += 1
        }
        
        let sortedKeywords = wordFrequency.sorted { $0.value > $1.value }
        let topKeywords = Array(sortedKeywords.prefix(10))
        
        return topKeywords.map { word, frequency in
            Keyword(
                text: word,
                frequency: frequency,
                importance: Double(frequency) / Double(filteredWords.count)
            )
        }
    }
    
    // MARK: - Summary Generation
    
    public func generateSummary(_ text: String) async throws -> String {
        let sentences = text.split(separator: ".").map(String.init)
        let words = text.split(separator: " ").map(String.init)
        
        // Simple extractive summarization
        var sentenceScores: [(String, Double)] = []
        
        for sentence in sentences {
            let sentenceWords = sentence.split(separator: " ").map(String.init)
            let score = calculateSentenceScore(sentenceWords, allWords: words)
            sentenceScores.append((sentence, score))
        }
        
        let sortedSentences = sentenceScores.sorted { $0.1 > $0.1 }
        let summarySentences = Array(sortedSentences.prefix(3))
        
        return summarySentences.map { $0.0 }.joined(separator: ". ") + "."
    }
    
    // MARK: - Complexity Analysis
    
    public func analyzeComplexity(_ text: String) async throws -> ComplexityAnalysis {
        let words = text.split(separator: " ").map(String.init)
        let sentences = text.split(separator: ".").map(String.init)
        
        let averageWordLength = words.reduce(0) { $0 + $1.count } / max(words.count, 1)
        let averageSentenceLength = words.count / max(sentences.count, 1)
        
        let longWords = words.filter { $0.count > 6 }.count
        let longWordRatio = Double(longWords) / Double(max(words.count, 1))
        
        let complexityScore = calculateComplexityScore(
            averageWordLength: averageWordLength,
            averageSentenceLength: averageSentenceLength,
            longWordRatio: longWordRatio
        )
        
        let level = determineComplexityLevel(complexityScore)
        
        return ComplexityAnalysis(
            score: complexityScore,
            level: level,
            averageWordLength: averageWordLength,
            averageSentenceLength: averageSentenceLength,
            longWordRatio: longWordRatio,
            readabilityIndex: calculateReadabilityIndex(words: words, sentences: sentences)
        )
    }
    
    // MARK: - Topic Extraction
    
    public func extractTopics(_ text: String) async throws -> [Topic] {
        let words = text.lowercased().split(separator: " ").map(String.init)
        
        // Topic categories based on common words
        let topicCategories: [String: Set<String>] = [
            "Technology": ["ai", "machine", "learning", "algorithm", "data", "computer", "software", "code", "programming"],
            "Business": ["company", "business", "market", "profit", "revenue", "strategy", "management", "leadership"],
            "Science": ["research", "study", "experiment", "theory", "hypothesis", "analysis", "evidence", "discovery"],
            "Health": ["health", "medical", "treatment", "patient", "disease", "medicine", "doctor", "hospital"],
            "Education": ["education", "learning", "teaching", "student", "school", "university", "course", "study"]
        ]
        
        var topicScores: [String: Double] = [:]
        
        for (topic, keywords) in topicCategories {
            let matches = words.filter { keywords.contains($0) }.count
            let score = Double(matches) / Double(max(words.count, 1))
            if score > 0.01 { // Only include topics with meaningful presence
                topicScores[topic] = score
            }
        }
        
        let sortedTopics = topicScores.sorted { $0.value > $0.value }
        
        return sortedTopics.map { topic, score in
            Topic(
                name: topic,
                confidence: score,
                keywords: Array(topicCategories[topic] ?? [])
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapNLTagToEntityType(_ tag: NLTag) -> EntityType {
        switch tag {
        case .personalName:
            return .person
        case .placeName:
            return .location
        case .organizationName:
            return .organization
        case .number:
            return .number
        case .date:
            return .date
        default:
            return .other
        }
    }
    
    private func calculateSentenceScore(_ sentenceWords: [String], allWords: [String]) -> Double {
        let wordFrequency = Dictionary(grouping: allWords, by: { $0 }).mapValues { $0.count }
        let sentenceScore = sentenceWords.reduce(0.0) { score, word in
            score + Double(wordFrequency[word] ?? 0)
        }
        return sentenceScore / Double(max(sentenceWords.count, 1))
    }
    
    private func calculateComplexityScore(averageWordLength: Int, averageSentenceLength: Int, longWordRatio: Double) -> Double {
        let wordLengthScore = min(Double(averageWordLength) / 10.0, 1.0)
        let sentenceLengthScore = min(Double(averageSentenceLength) / 30.0, 1.0)
        let longWordScore = longWordRatio
        
        return (wordLengthScore + sentenceLengthScore + longWordScore) / 3.0
    }
    
    private func determineComplexityLevel(_ score: Double) -> ComplexityLevel {
        switch score {
        case 0.0..<0.3:
            return .easy
        case 0.3..<0.6:
            return .moderate
        case 0.6..<0.8:
            return .difficult
        default:
            return .expert
        }
    }
    
    private func calculateReadabilityIndex(words: [String], sentences: [String]) -> Double {
        let syllables = words.reduce(0) { $0 + countSyllables($1) }
        let wordsCount = words.count
        let sentencesCount = sentences.count
        
        guard wordsCount > 0 && sentencesCount > 0 else { return 0.0 }
        
        // Flesch Reading Ease formula
        let fleschScore = 206.835 - (1.015 * Double(wordsCount) / Double(sentencesCount)) - (84.6 * Double(syllables) / Double(wordsCount))
        
        return max(0.0, min(100.0, fleschScore))
    }
    
    private func countSyllables(_ word: String) -> Int {
        let vowels = Set("aeiouy")
        var count = 0
        var previousWasVowel = false
        
        for char in word.lowercased() {
            let isVowel = vowels.contains(char)
            if isVowel && !previousWasVowel {
                count += 1
            }
            previousWasVowel = isVowel
        }
        
        return max(1, count)
    }
}

// MARK: - Models

public struct TextAnalysisResult {
    let language: LanguageInfo
    let sentiment: SentimentAnalysisResult
    let entities: [Entity]
    let keywords: [Keyword]
    let summary: String
    let complexity: ComplexityAnalysis
    let topics: [Topic]
    let processingTime: TimeInterval
    let wordCount: Int
    let characterCount: Int
    let sentenceCount: Int
}

public struct LanguageInfo {
    let code: String
    let name: String
    let confidence: Double
    let isReliable: Bool
}

public struct SentimentAnalysisResult {
    let type: SentimentType
    let positiveScore: Double
    let negativeScore: Double
    let neutralScore: Double
    let confidence: Double
    let keywords: [String]
}

public enum SentimentType {
    case positive
    case negative
    case neutral
    case mixed
}

public struct Entity {
    let text: String
    let type: EntityType
    let range: Range<String.Index>
    let confidence: Double
}

public enum EntityType {
    case person
    case location
    case organization
    case number
    case date
    case other
}

public struct Keyword {
    let text: String
    let frequency: Int
    let importance: Double
}

public struct ComplexityAnalysis {
    let score: Double
    let level: ComplexityLevel
    let averageWordLength: Int
    let averageSentenceLength: Int
    let longWordRatio: Double
    let readabilityIndex: Double
}

public enum ComplexityLevel {
    case easy
    case moderate
    case difficult
    case expert
}

public struct Topic {
    let name: String
    let confidence: Double
    let keywords: [String]
}

// MARK: - Errors

public enum TextProcessingError: Error, LocalizedError {
    case languageDetectionFailed
    case sentimentAnalysisFailed
    case entityExtractionFailed
    case keywordExtractionFailed
    case summaryGenerationFailed
    case complexityAnalysisFailed
    case topicExtractionFailed
    
    public var errorDescription: String? {
        switch self {
        case .languageDetectionFailed:
            return "Failed to detect language from text"
        case .sentimentAnalysisFailed:
            return "Failed to analyze sentiment"
        case .entityExtractionFailed:
            return "Failed to extract entities"
        case .keywordExtractionFailed:
            return "Failed to extract keywords"
        case .summaryGenerationFailed:
            return "Failed to generate summary"
        case .complexityAnalysisFailed:
            return "Failed to analyze complexity"
        case .topicExtractionFailed:
            return "Failed to extract topics"
        }
    }
}
