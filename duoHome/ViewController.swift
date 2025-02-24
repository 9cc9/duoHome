//
//  ViewController.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {
    // 输入相关组件
    let inputTextField = UITextField()
    let voiceButton = UIButton()
    let resultLabel = UILabel()
    
    // 语音识别相关
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestSpeechAuthorization()
    }
    
    private func setupUI() {
        // ... 其他UI配置 ...
        
        // 文本输入框
        inputTextField.placeholder = "请输入指令或点击麦克风"
        inputTextField.borderStyle = .roundedRect
        inputTextField.delegate = self
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputTextField)
        
        // 语音按钮
        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(voiceButton)
        
        // 结果显示标签
        resultLabel.numberOfLines = 0
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            inputTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            inputTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            voiceButton.leadingAnchor.constraint(equalTo: inputTextField.trailingAnchor, constant: 10),
            voiceButton.centerYAnchor.constraint(equalTo: inputTextField.centerYAnchor),
            
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.topAnchor.constraint(equalTo: inputTextField.bottomAnchor, constant: 30),
            resultLabel.widthAnchor.constraint(equalTo: inputTextField.widthAnchor)
        ])
    }
    
    // 语音授权请求
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                self.voiceButton.isEnabled = authStatus == .authorized
            }
        }
    }
    
    // 语音按钮点击处理
    @objc private func voiceButtonTapped() {
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    // 开始录音
    private func startRecording() {
        do {
            // 先停止并重置引擎
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }
            
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                throw NSError(domain: "SpeechError", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法创建识别请求"])
            }
            
            let inputNode = audioEngine.inputNode
            
            // 确保移除旧tap
            inputNode.removeTap(onBus: 0)
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            guard recordingFormat.sampleRate > 0 else {
                throw NSError(domain: "AudioError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的音频格式"])
            }
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                DispatchQueue.main.async {
                    self?.recognitionRequest?.append(buffer)
                }
            }
            
            audioEngine.prepare()
            
            // 关键部分：创建识别任务
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                // 结果处理
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.inputTextField.text = text
                        self.processCommand(text)
                    }
                }
                
                // 错误/完成处理
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(message: "识别错误: \(error.localizedDescription)")
                    }
                    self.stopRecording()
                } else if result?.isFinal == true {
                    self.stopRecording()
                }
            }
            
            try audioEngine.start()
            voiceButton.setImage(UIImage(systemName: "mic.slash.fill"), for: .normal)
        } catch {
            showAlert(message: "录音启动失败：\(error.localizedDescription)")
        }
    }
    
    // 停止录音
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // 新增警告框方法
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "提示",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // 处理指令（文本和语音统一处理）
    private func processCommand(_ text: String) {
        resultLabel.text = "接收指令：\(text)"
        // 这里添加具体的指令处理逻辑
    }
}

// 文本输入处理
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            processCommand(text)
            textField.resignFirstResponder()
            return true
        }
        return false
    }
}

