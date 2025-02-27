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
    
    // 聊天记录显示区域
    let chatTableView = UITableView()
    var chatMessages: [(sender: String, message: String)] = []
    
    // 添加顶部背景视图作为属性
    let topBackgroundView = UIView()
    
    // 语音识别相关
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // 添加停顿检测计时器
    private var pauseDetectionTimer: Timer?
    private let pauseThreshold: TimeInterval = 2.0
    private var lastTranscription: String = ""
    
    // 添加AI服务
    private let aiService = AIService(apiKey: "sk-6267c004c2ac41d69c098628660f41d0")

    // 添加文字转语音服务
    private let textToSpeechService = TextToSpeechService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestSpeechAuthorization()
        
        // 配置文字转语音服务
        TextToSpeechService.shared.configure(
            language: "zh-CN",
            rate: AVSpeechUtteranceDefaultSpeechRate * 0.9, // 稍微慢一点的语速
            volume: 1.0,
            pitch: 1.0
        )
        
        // 设置背景色
        view.backgroundColor = .white
        
        // 顶部背景视图
        topBackgroundView.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // 橘色背景
        topBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBackgroundView)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 添加顶部背景视图 - 不需要重新创建，使用类属性
        topBackgroundView.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // 橘色背景
        topBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBackgroundView)
        
        // 添加标题标签
        let titleLabel = UILabel()
        titleLabel.text = "朵朵专属AI"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white // 白色文字
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBackgroundView.addSubview(titleLabel)
        
        // 添加小图标
        let logoImageView = UIImageView(image: UIImage(systemName: "brain.head.profile"))
        logoImageView.tintColor = .white
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        topBackgroundView.addSubview(logoImageView)
        
        // 聊天记录表格
        chatTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatCell")
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.separatorStyle = .none
        chatTableView.backgroundColor = .systemBackground
        chatTableView.translatesAutoresizingMaskIntoConstraints = false
        // 添加表格背景图案
        let patternImage = UIImage(systemName: "bubble.left.and.bubble.right.fill")?.withTintColor(.systemGray6, renderingMode: .alwaysOriginal)
        chatTableView.backgroundView = UIImageView(image: patternImage)
        chatTableView.backgroundView?.contentMode = .scaleAspectFit
        chatTableView.backgroundView?.alpha = 0.1
        view.addSubview(chatTableView)
        
        // 底部输入区域容器
        let inputContainerView = UIView()
        inputContainerView.backgroundColor = .systemGray6
        // 添加阴影效果
        inputContainerView.layer.shadowColor = UIColor.black.cgColor
        inputContainerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        inputContainerView.layer.shadowOpacity = 0.1
        inputContainerView.layer.shadowRadius = 3
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainerView)
        
        // 文本输入框
        inputTextField.placeholder = "请输入指令或点击麦克风"
        inputTextField.font = UIFont.systemFont(ofSize: 16)
        inputTextField.borderStyle = .roundedRect
        inputTextField.backgroundColor = .white
        inputTextField.layer.cornerRadius = 18
        inputTextField.clipsToBounds = true
        inputTextField.delegate = self
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(inputTextField)
        
        // 语音按钮
        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        voiceButton.tintColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // 橘色图标
        voiceButton.backgroundColor = .white
        voiceButton.layer.cornerRadius = 20
        voiceButton.layer.shadowColor = UIColor.black.cgColor
        voiceButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        voiceButton.layer.shadowOpacity = 0.2
        voiceButton.layer.shadowRadius = 2
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(voiceButton)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 顶部背景视图约束
            topBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            topBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBackgroundView.heightAnchor.constraint(equalToConstant: 100),
            
            // 标题标签约束
            titleLabel.centerXAnchor.constraint(equalTo: topBackgroundView.centerXAnchor, constant: 15),
            titleLabel.bottomAnchor.constraint(equalTo: topBackgroundView.bottomAnchor, constant: -15),
            
            // 图标约束
            logoImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -10),
            logoImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 30),
            logoImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // 底部输入区域约束
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 70),
            
            // 输入框约束
            inputTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: voiceButton.leadingAnchor, constant: -12),
            inputTextField.heightAnchor.constraint(equalToConstant: 36),
            
            // 语音按钮约束
            voiceButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            voiceButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 40),
            voiceButton.heightAnchor.constraint(equalToConstant: 40),
            
            // 聊天记录表格约束
            chatTableView.topAnchor.constraint(equalTo: topBackgroundView.bottomAnchor),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatTableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
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
            
            // 添加标志变量，防止重复处理
            var hasProcessedFinalResult = false
            
            // 关键部分：创建识别任务
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                // 结果处理
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.inputTextField.text = text
                        
                        // 重置停顿计时器
                        self.resetPauseDetectionTimer()
                        
                        // 保存当前转录文本
                        self.lastTranscription = text
                    }
                }
                
                // 错误/完成处理
                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(message: "识别错误: \(error.localizedDescription)")
                    }
                    self.stopRecording()
                } else if result?.isFinal == true && !hasProcessedFinalResult {
                    // 标记为已处理，防止重复
                    hasProcessedFinalResult = true
                    
                    // 在语音识别完成后处理指令
                    if let finalText = result?.bestTranscription.formattedString, !finalText.isEmpty {
                        DispatchQueue.main.async {
                            self.processCommand(finalText)
                        }
                    }
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
        
        // 取消停顿检测计时器
        pauseDetectionTimer?.invalidate()
        pauseDetectionTimer = nil
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // 重置停顿检测计时器
    private func resetPauseDetectionTimer() {
        // 取消现有计时器
        pauseDetectionTimer?.invalidate()
        
        // 创建新计时器
        pauseDetectionTimer = Timer.scheduledTimer(withTimeInterval: pauseThreshold, repeats: false) { [weak self] _ in
            guard let self = self, self.audioEngine.isRunning, !self.lastTranscription.isEmpty else { return }
            
            // 停顿超过阈值，处理当前识别的文本
            DispatchQueue.main.async {
                // 停止录音会触发recognitionTask的完成回调，所以这里不需要再调用processCommand
                self.stopRecording()
            }
        }
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
        // 清空输入框
        inputTextField.text = ""
        
        // 添加用户消息到聊天记录
        addMessage(sender: "user", message: text)
        
        // 添加一个空的AI回复消息（将在流式接收时更新）
        let aiMessageIndex = addMessage(sender: "ai", message: "正在思考...")
        
        // 重置文字转语音服务的累积文本
        TextToSpeechService.shared.resetAccumulatedText()
        
        // 使用流式输出调用AI服务
        aiService.sendMessageStream(prompt: text, 
            onReceive: { [weak self] partialResponse in
                guard let self = self else { return }

                // 更新AI回复消息
                DispatchQueue.main.async {

                    // 第一次收到响应时，清除"正在思考..."
                    if self.chatMessages[aiMessageIndex].message == "正在思考..." {
                        self.chatMessages[aiMessageIndex].message = partialResponse
                    } else {
                        // 累积AI回复内容
                        self.chatMessages[aiMessageIndex].message += partialResponse
                    }
                    
                    // 朗读新增的部分响应
                    print("3============ \(partialResponse)")

                    TextToSpeechService.shared.speakAddition(partialResponse)
                    
                    // 更新表格中的单元格
                    self.updateAIMessageCell(at: aiMessageIndex)
                }
            }, 
            onComplete: { [weak self] fullResponse, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.chatMessages[aiMessageIndex].message = "回复出错: \(error.localizedDescription)"
                        self.updateAIMessageCell(at: aiMessageIndex)
                        self.showAlert(message: "AI响应错误: \(error.localizedDescription)")
                        
                        // 停止任何正在进行的朗读
                        TextToSpeechService.shared.stopSpeaking()
                    }
                    return
                }
                
                print("AI响应完成")
            }
        )
    }
    
    // 添加消息到聊天记录并返回索引
    private func addMessage(sender: String, message: String) -> Int {
        chatMessages.append((sender: sender, message: message))
        let indexPath = IndexPath(row: chatMessages.count - 1, section: 0)
        chatTableView.insertRows(at: [indexPath], with: .automatic)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        return chatMessages.count - 1
    }
    
    // 更新AI消息单元格
    private func updateAIMessageCell(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        
        // 先更新数据源中的消息
        let currentMessage = chatMessages[index].message
        
        // 打印调试信息
        print("更新AI消息: \(currentMessage)")
        
        // 更新表格视图
        chatTableView.beginUpdates()
        
        if let cell = chatTableView.cellForRow(at: indexPath) as? ChatBubbleCell {
            cell.messageLabel.text = currentMessage
            // 强制布局更新
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        chatTableView.endUpdates()
        
        // 确保滚动到最新消息
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
}

// 聊天气泡单元格
class ChatBubbleCell: UITableViewCell {
    let bubbleView = UIView()
    let messageLabel = UILabel()
    let avatarImageView = UIImageView()
    
    var isUserMessage: Bool = false {
        didSet {
            setupBubbleStyle()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // 头像图片视图
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarImageView)
        
        // 气泡视图
        bubbleView.layer.cornerRadius = 18
        bubbleView.clipsToBounds = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        // 消息标签 - 确保在最上层
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.backgroundColor = .clear // 确保背景透明
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel) // 直接添加到contentView而不是bubbleView
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 消息标签约束 - 相对于气泡视图定位
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),
            
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),
            avatarImageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])
    }
    
    private func setupBubbleStyle() {
        if isUserMessage {
            // 用户消息样式 - 使用橘色背景
            bubbleView.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
            
            // 确保文字颜色对比度高
            messageLabel.textColor = .white
            
            // 用户头像 - 使用自定义图片
            avatarImageView.image = UIImage(named: "UserAvatar")
            
            // 确保头像是圆形 - 在layoutSubviews中设置圆角
            avatarImageView.layer.cornerRadius = 18 // 直径的一半
            avatarImageView.clipsToBounds = true
            
            // 添加边框使圆形更明显（可选）
            avatarImageView.layer.borderWidth = 1.0
            avatarImageView.layer.borderColor = UIColor.white.cgColor
            
            // 约束调整
            NSLayoutConstraint.deactivate(bubbleView.constraints.filter { 
                $0.firstAttribute == .leading || $0.firstAttribute == .trailing 
            })
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                avatarImageView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -8),
                avatarImageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16)
            ])
        } else {
            // AI消息样式 - 左侧浅色气泡
            bubbleView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            
            // AI消息文字颜色
            messageLabel.textColor = .black
            
            // AI头像
            avatarImageView.image = UIImage(systemName: "brain.head.profile")
            avatarImageView.tintColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // 橘色图标
            
            // 确保AI头像也是圆形
            avatarImageView.layer.cornerRadius = 18
            avatarImageView.clipsToBounds = true
            
            // 添加背景色使圆形更明显（可选）
            avatarImageView.backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.9, alpha: 1.0) // 浅橘色背景
            
            // 约束调整
            NSLayoutConstraint.deactivate(bubbleView.constraints.filter { 
                $0.firstAttribute == .leading || $0.firstAttribute == .trailing 
            })
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                avatarImageView.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 8),
                avatarImageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
            ])
        }
        
        // 强制更新布局
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // 添加layoutSubviews方法确保圆角正确应用
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 确保头像是圆形 - 在实际布局后设置圆角
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
    }
    
    func configure(with message: String, isUser: Bool) {
        // 打印调试信息
        print("配置单元格: \(message), 用户消息: \(isUser)")
        
        messageLabel.text = message
        isUserMessage = isUser
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = ""
    }
}

// 表格视图代理和数据源
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatBubbleCell
        let message = chatMessages[indexPath.row]
        cell.configure(with: message.message, isUser: message.sender == "user")
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
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

