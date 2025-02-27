//
//  TextToSpeechService.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import Foundation
import AVFoundation

class TextToSpeechService: NSObject {
    // 单例模式，方便全局访问
    static let shared = TextToSpeechService()
    
    // 语音合成器
    private let synthesizer = AVSpeechSynthesizer()
    
    // 当前是否正在朗读
    private(set) var isSpeaking = false
    
    // 语音配置 - 默认设置为适合小朋友的参数
    private var voiceLanguage = "zh-CN"
    private var voiceIdentifier: String? = nil // 特定的声音标识符
    private var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.8 // 稍微慢一点的语速
    private var volume: Float = 0.9 // 稍微大一点的音量
    private var pitchMultiplier: Float = 1.3 // 提高音调，使声音更像小孩子
    
    // 累积的文本，用于完整朗读
    private var accumulatedText = ""
    
    // 待朗读的文本队列
    private var textQueue: [String] = []
    
    // 是否正在处理队列
    private var isProcessingQueue = false
    
    // 回调闭包类型
    typealias SpeechCompletionHandler = () -> Void
    
    // 完成回调
    private var completionHandler: SpeechCompletionHandler?
    
    // 私有初始化方法，防止外部创建实例
    private override init() {
        super.init()
        synthesizer.delegate = self
        
        // 初始化时设置为适合小朋友的声音
        setupChildFriendlyVoice()
    }
    
    // 设置适合小朋友的声音
    private func setupChildFriendlyVoice() {
        // 获取所有可用的声音
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // 尝试找到最适合的中文女声
        // 优先选择 Siri 的声音，因为它通常质量更好
        var bestVoice: AVSpeechSynthesisVoice? = nil
        
        for voice in voices {
            // 检查是否是中文声音
            if voice.language.starts(with: "zh-") {
                // 检查是否是女声（通常名称中包含 "female" 或特定的女性名字）
                let voiceName = voice.name.lowercased()
                if voiceName.contains("female") || voiceName.contains("siri") || voiceName.contains("tingting") {
                    bestVoice = voice
                    // 如果找到 Siri 的声音，优先使用
                    if voiceName.contains("siri") {
                        break
                    }
                }
            }
        }
        
        // 如果找到合适的声音，设置它的标识符
        if let bestVoice = bestVoice {
            voiceIdentifier = bestVoice.identifier
            print("已选择适合小朋友的声音: \(bestVoice.name)")
        } else {
            // 如果没有找到特定的声音，使用默认的中文声音
            print("未找到特定的女声，使用默认中文声音")
        }
    }
    
    // 配置语音参数
    func configure(language: String? = nil, rate: Float? = nil, volume: Float? = nil, pitch: Float? = nil) {
        if let language = language {
            voiceLanguage = language
        }
        
        if let rate = rate {
            speechRate = rate
        }
        
        if let volume = volume {
            self.volume = volume
        }
        
        if let pitch = pitch {
            pitchMultiplier = pitch
        }
    }
    
    // 重置累积文本
    func resetAccumulatedText() {
        accumulatedText = ""
        textQueue.removeAll()
        isProcessingQueue = false
        
        // 如果正在朗读，停止当前朗读
        if isSpeaking {
            stopSpeaking()
        }
    }
    
    // 配置语音合成请求
    private func configureUtterance(_ utterance: AVSpeechUtterance) {
        // 如果有特定的声音标识符，优先使用
        if let voiceIdentifier = voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
        }
        
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.pitchMultiplier = pitchMultiplier
        
        // 设置不朗读标点符号
        // 注意：这个属性在iOS 14及以上版本可用
        if #available(iOS 14.0, *) {
            // 0.0表示不朗读标点符号，1.0表示完全朗读标点符号
            utterance.prefersAssistiveTechnologySettings = false
            utterance.postUtteranceDelay = 0.0
            utterance.preUtteranceDelay = 0.0
        }
    }
    
    // 朗读文本（完整文本，会停止当前朗读）
    func speak(_ text: String, completion: SpeechCompletionHandler? = nil) {
        // 如果正在朗读，先停止
        if isSpeaking {
            stopSpeaking()
        }
        
        // 重置累积文本并设置新文本
        resetAccumulatedText()
        accumulatedText = text
        
        // 设置完成回调
        completionHandler = completion
        
        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: text)
        configureUtterance(utterance)
        
        // 开始朗读
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // 朗读新增的文本片段（用于流式输出）
    func speakAddition(_ newText: String) {
        // 添加新文本到累积文本
        accumulatedText += newText
        
        // 将新文本添加到队列
        if !newText.isEmpty {
            // 检查是否是完整的句子或短语
            // 这里我们简单地按标点符号分割，可以根据需要调整
            let sentences = splitIntoSentences(newText)
            textQueue.append(contentsOf: sentences)
        }
        
        // 如果当前没有处理队列，开始处理
        if !isProcessingQueue {
            processTextQueue()
        }
    }
    
    // 将文本分割成句子或短语
    private func splitIntoSentences(_ text: String) -> [String] {
        // 如果文本很短，直接返回
        if text.count <= 5 {
            return [text]
        }
        
        // 按标点符号分割
        let delimiters = ["。", "！", "？", ".", "!", "?", "\n"]
        var result: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            
            // 如果遇到分隔符，添加到结果并重置当前句子
            if delimiters.contains(String(char)) {
                result.append(currentSentence)
                currentSentence = ""
            }
        }
        
        // 添加最后一个句子（如果有）
        if !currentSentence.isEmpty {
            result.append(currentSentence)
        }
        
        return result
    }
    
    // 处理文本队列
    private func processTextQueue() {
        // 如果队列为空或者正在朗读，返回
        if textQueue.isEmpty || isSpeaking {
            isProcessingQueue = false
            return
        }
        
        isProcessingQueue = true
        
        // 获取队列中的下一个文本
        let nextText = textQueue.removeFirst()
        
        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: nextText)
        configureUtterance(utterance)
        
        // 开始朗读
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // 停止朗读
    func stopSpeaking() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    // 暂停朗读
    func pauseSpeaking() {
        if isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    // 继续朗读
    func continueSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    // 获取所有可用的声音
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }
    
    // 设置特定的声音
    func setVoice(identifier: String) {
        self.voiceIdentifier = identifier
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        
        // 处理队列中的下一个文本
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 如果队列不为空，处理下一个文本
            if !self.textQueue.isEmpty {
                self.processTextQueue()
            } else {
                // 队列为空，调用完成回调
                if let completionHandler = self.completionHandler {
                    completionHandler()
                    self.completionHandler = nil
                }
                self.isProcessingQueue = false
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isProcessingQueue = false
        completionHandler = nil
    }
} 