//
//  InputAreaView.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit

protocol InputAreaViewDelegate: AnyObject {
    func voiceButtonTapped()
    func textFieldShouldReturn(_ text: String) -> Bool
}

class InputAreaView: UIView {
    // UI组件
    let inputTextField = UITextField()
    let voiceButton = UIButton()
    
    // 代理
    weak var delegate: InputAreaViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .white
        
        // 添加阴影效果
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 3
        
        // 语音按钮 - 调大并放在上方居中
        let micConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        voiceButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: micConfig), for: .normal)
        voiceButton.tintColor = .white // 白色图标
        voiceButton.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0) // 浅粉色背景
        voiceButton.layer.cornerRadius = 35 // 增大圆角
        voiceButton.layer.shadowColor = UIColor.black.cgColor
        voiceButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        voiceButton.layer.shadowOpacity = 0.3
        voiceButton.layer.shadowRadius = 4
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(voiceButton)
        
        // 文本输入框 - 放在语音按钮下方
        inputTextField.placeholder = "请输入指令或点击上方麦克风"
        inputTextField.font = UIFont.systemFont(ofSize: 16)
        inputTextField.borderStyle = .roundedRect
        inputTextField.backgroundColor = .white
        inputTextField.layer.cornerRadius = 18
        inputTextField.clipsToBounds = true
        inputTextField.delegate = self
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputTextField)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 语音按钮约束 - 放在上方居中
            voiceButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            voiceButton.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            voiceButton.widthAnchor.constraint(equalToConstant: 60), // 增大按钮尺寸
            voiceButton.heightAnchor.constraint(equalToConstant: 60), // 增大按钮尺寸
            
            // 输入框约束 - 放在下方
            inputTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            inputTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            inputTextField.topAnchor.constraint(equalTo: voiceButton.bottomAnchor, constant: 12),
            inputTextField.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    @objc private func voiceButtonTapped() {
        delegate?.voiceButtonTapped()
    }
    
    func updateVoiceButtonImage(isRecording: Bool) {
        let micConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        let imageName = isRecording ? "mic.slash.fill" : "mic.fill"
        voiceButton.setImage(UIImage(systemName: imageName, withConfiguration: micConfig), for: .normal)
    }
    
    func clearTextField() {
        inputTextField.text = ""
    }
    
    func dismissKeyboard() {
        inputTextField.resignFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension InputAreaView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            let shouldReturn = delegate?.textFieldShouldReturn(text) ?? false
            if shouldReturn {
                // 发送消息后让输入框失去焦点，收起键盘
                textField.resignFirstResponder()
            }
            return shouldReturn
        }
        return false
    }
}
