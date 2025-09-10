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
    // UI组件
    private let topHeaderView = TopHeaderView()
    private let chatTableView = ChatTableView()
    private let inputAreaView = InputAreaView()
    
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
    private let localAI = LocalAIService(modelName: "deepseek-r1:32b")
    
    // 添加文字转语音服务
    private let textToSpeechService = TextToSpeechService.shared
    
    // 添加应用唤起服务
    private let appLaunchService = AppLaunchService.shared
    
    // 添加星星管理服务
    private let starService = StarManagementService.shared
    
    // 添加会话管理服务
    private let conversationService = ConversationService.shared
    
    // 添加历史记录侧边栏
    private let historySidebarView = HistorySidebarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
        setupKeyboardObservers()
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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 添加子视图
        [topHeaderView, chatTableView, inputAreaView, historySidebarView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // 设置侧边栏初始状态
        historySidebarView.isHidden = true
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 顶部标题视图约束
            topHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topHeaderView.heightAnchor.constraint(equalToConstant: 100),
            
            // 底部输入区域约束
            inputAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputAreaView.heightAnchor.constraint(equalToConstant: 120),
            
            // 聊天记录表格约束
            chatTableView.topAnchor.constraint(equalTo: topHeaderView.bottomAnchor),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatTableView.bottomAnchor.constraint(equalTo: inputAreaView.topAnchor),
            
            // 历史记录侧边栏约束
            historySidebarView.topAnchor.constraint(equalTo: view.topAnchor),
            historySidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historySidebarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historySidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupDelegates() {
        inputAreaView.delegate = self
        chatTableView.chatDelegate = self
        topHeaderView.delegate = self
        historySidebarView.delegate = self
    }
    
    // 设置键盘监听
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // 键盘将要显示
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: duration) {
            // 将输入容器向上移动键盘高度
            self.inputAreaView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            self.view.layoutIfNeeded()
        }
        
        // 滚动到最新消息
        if !chatTableView.chatMessages.isEmpty {
            let indexPath = IndexPath(row: chatTableView.chatMessages.count - 1, section: 0)
            chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // 键盘将要隐藏
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: duration) {
            // 恢复输入容器的原始位置
            self.inputAreaView.transform = .identity
            self.view.layoutIfNeeded()
        }
    }
    
    // 语音授权请求
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                self.inputAreaView.voiceButton.isEnabled = authStatus == .authorized
            }
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
                        self.inputAreaView.inputTextField.text = text
                        
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
            inputAreaView.updateVoiceButtonImage(isRecording: true)
        } catch {
            showAlert(message: "录音启动失败：\(error.localizedDescription)")
        }
    }
    
    // 停止录音
    private func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
            
            // 重置音频会话为播放模式
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("重置音频会话失败: \(error)")
            }
        }
        
        // 重置UI
        inputAreaView.updateVoiceButtonImage(isRecording: false)
        
        // 取消计时器
        pauseDetectionTimer?.invalidate()
        pauseDetectionTimer = nil
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
    
    private func processStarCommand(_ text: String) -> Bool {
        // 增加星星命令 - 固定增加1颗
        if text.contains("星星") && (text.contains("加") || text.contains("增加")) {
            do {
                print("⭐️ 增加星星操作 - 数量: 1")
                try starService.addStars(1)
                chatTableView.addOrUpdateAIMessage("已经帮你增加了1颗星星！")
                print("✅ 星星增加成功 - 当前总数: \(starService.getStars())")
                return true
            } catch {
                print("❌ 增加星星失败: \(error)")
                chatTableView.addOrUpdateAIMessage("抱歉，增加星星时出现错误")
                return true
            }
        }
        
        // 减少星星命令 - 固定减少1颗
        if text.contains("星星") && (text.contains("减") || text.contains("扣除")) {
            do {
                print("⭐️ 减少星星操作 - 数量: 1")
                try starService.removeStars(1)
                chatTableView.addOrUpdateAIMessage("已经减少了1颗星星。")
                print("✅ 星星减少成功 - 当前总数: \(starService.getStars())")
                return true
            } catch {
                print("❌ 减少星星失败: \(error)")
                chatTableView.addOrUpdateAIMessage("抱歉，减少星星时出现错误")
                return true
            }
        }
        
        // 查询星星数量
        if text.contains("星星") && (text.contains("查看") || text.contains("多少")) {
            print("📊 查询星星数量")
            let todayStars = starService.getStars()
            let weeklyReport = starService.getWeeklyReport()
            let totalStars = weeklyReport.reduce(0) { $0 + $1.stars }
            
            // 创建星星表格
            var message = "本周星星统计表 ⭐️\n"
            message += "┌──────┬──────┐\n"
            message += "│ 日期 │ 星星 │\n"
            message += "├──────┼──────┤\n"
            
            // 星期几的中文表示
            let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
            
            // 添加每天的数据
            for day in weeklyReport {
                let calendar = Calendar.current
                // 获取星期几（1代表周日，2代表周一，依此类推）
                let weekdayNum = calendar.component(.weekday, from: day.date)
                // 转换为中国习惯的星期几（0代表周日，1代表周一）
                let adjustedWeekday = (weekdayNum + 5) % 7
                let weekday = "周" + weekdays[adjustedWeekday]
                
                let stars = String(day.stars)
                message += "│ \(weekday)   │  \(stars)   │\n"
            }
            
            message += "└──────┴──────┘\n"
            message += "\n总计：\(totalStars)颗星星 ✨"
            
            print("📈 查询结果 - 今日星星: \(todayStars), 本周总数: \(totalStars)")
            chatTableView.addOrUpdateAIMessage(message)
            return true
        }
        
        return false
    }
    
    private func processCommand(_ text: String) {
        // 清空输入框并收起键盘
        inputAreaView.clearTextField()
        inputAreaView.dismissKeyboard()
        
        // 添加用户消息到聊天记录
        chatTableView.addMessage(sender: "user", message: text)
        
        // 上传用户消息到云服务器
        uploadUserMessage(text)
        
        // 先处理星星相关的命令
        if processStarCommand(text) {
            return
        }
        
        // 检查是否需要唤起应用
        if let appLaunchResult = appLaunchService.checkAndLaunchApp(for: text) {
            // 如果成功识别并尝试启动应用
            chatTableView.addOrUpdateAIMessage(appLaunchResult.responseMessage)
            
            // 如果成功启动应用，不需要继续发送到AI服务
            if appLaunchResult.appLaunched {
                return
            }
        }
        
        // 确保音频会话设置为播放模式
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话为播放模式失败: \(error)")
        }
        
        // 发送到AI服务并获取回复
        print("🚀 开始发送消息到本地AI服务...")
        aiService.sendMessageStream(
            prompt: text,
            onReceive: { [weak self] chunk in
                guard let self = self else { return }
                
                print("📥 收到AI响应片段: \(chunk)")
                
                // 添加或更新AI消息
                self.chatTableView.addOrUpdateAIMessage(chunk)
                
                // 上传AI消息到云服务器（只上传完整响应）
                // 这里暂时不处理，等完整响应后再上传
                
                // 使用文字转语音服务朗读新增内容
                TextToSpeechService.shared.speakAddition(chunk)
            },
            onComplete: { [weak self] fullResponse, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ AI服务连接错误: \(error.localizedDescription)")
                    print("❌ 错误详情: \(error)")
                    
                    // 向用户显示更友好的错误信息
                    let errorMessage = "无法连接到AI服务，请检查：\n1. AI服务是否已启动\n2. 端口11434是否正确\n3. 本地网络连接是否正常"
                    self.showAlert(message: errorMessage)
                    
                    // 在聊天界面显示错误信息
                    self.chatTableView.addOrUpdateAIMessage("抱歉，我现在无法回应，请检查AI服务是否正常运行。")
                    return
                }
                
                print("✅ AI响应完成")
                if let response = fullResponse {
                    print("📝 完整响应内容: \(response)")
                    
                    // 上传完整的AI响应到云服务器
                    self.uploadAIMessage(response)
                }
            }
        )
    }
    
    // MARK: - 会话上传方法
    private func uploadUserMessage(_ message: String) {
        // 检查是否已有会话，如果没有则创建新会话
        if conversationService.getCurrentConversationId() == nil {
            // 创建新会话，使用消息的前20个字符作为标题
            let title = String(message.prefix(20))
            conversationService.createConversation(title: title, firstMessage: message) { [weak self] result in
                switch result {
                case .success(let conversationId):
                    print("✅ [ViewController] 新会话创建成功，ID: \(conversationId)")
                case .failure(let error):
                    print("❌ [ViewController] 创建会话失败: \(error.localizedDescription)")
                }
            }
        } else {
            // 已有会话，直接添加用户消息
            conversationService.addUserMessage(message) { [weak self] result in
                switch result {
                case .success:
                    print("✅ [ViewController] 用户消息上传成功")
                case .failure(let error):
                    print("❌ [ViewController] 用户消息上传失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func uploadAIMessage(_ message: String) {
        conversationService.addAIMessage(message) { [weak self] result in
            switch result {
            case .success:
                print("✅ [ViewController] AI消息上传成功")
            case .failure(let error):
                print("❌ [ViewController] AI消息上传失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 历史记录相关方法
    private func showHistorySidebar() {
        // 获取历史记录数据
        conversationService.fetchConversationList { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let conversations):
                    self?.historySidebarView.updateConversations(conversations)
                    self?.historySidebarView.showSidebar()
                case .failure(let error):
                    print("❌ [ViewController] 获取历史记录失败: \(error.localizedDescription)")
                    self?.showAlert(message: "获取历史记录失败，请稍后重试")
                }
            }
        }
    }
}

// MARK: - InputAreaViewDelegate
extension ViewController: InputAreaViewDelegate {
    func voiceButtonTapped() {
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func textFieldShouldReturn(_ text: String) -> Bool {
        processCommand(text)
        return true
    }
}

// MARK: - ChatTableViewDelegate
extension ViewController: ChatTableViewDelegate {
    func chatTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 可以在这里添加点击聊天气泡的处理逻辑
    }
}

// MARK: - TopHeaderViewDelegate
extension ViewController: TopHeaderViewDelegate {
    func historyButtonTapped() {
        showHistorySidebar()
    }
}

// MARK: - HistorySidebarViewDelegate
extension ViewController: HistorySidebarViewDelegate {
    func historySidebarDidSelectConversation(_ conversation: ConversationItem) {
        // 切换到选中的对话
        print("📝 [ViewController] 切换到对话: \(conversation.title) (ID: \(conversation.id))")
        
        // 清空当前聊天记录
        chatTableView.clearMessages()
        
        // 设置当前会话ID
        conversationService.resetConversation()
        
        // 这里可以添加加载特定对话历史记录的逻辑
        // 目前先显示一个提示消息
        chatTableView.addOrUpdateAIMessage("已切换到对话：\(conversation.title)")
    }
    
    func historySidebarDidClose() {
        // 侧边栏关闭时的处理
        print("📝 [ViewController] 历史记录侧边栏已关闭")
    }
}