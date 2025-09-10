//
//  TopHeaderView.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit

protocol TopHeaderViewDelegate: AnyObject {
    func historyButtonTapped()
}

class TopHeaderView: UIView {
    weak var delegate: TopHeaderViewDelegate?
    
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    private let historyButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // 背景视图
        backgroundView.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0) // 浅粉色背景
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        
        // 标题标签
        titleLabel.text = "朵朵专属AI"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white // 白色文字
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(titleLabel)
        
        // 历史记录按钮
        historyButton.setTitle("☰", for: .normal)
        historyButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        historyButton.setTitleColor(.white, for: .normal)
        historyButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        historyButton.layer.cornerRadius = 20
        historyButton.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(historyButton)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 背景视图约束
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 标题标签约束
            titleLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -15),
            
            // 历史记录按钮约束
            historyButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            historyButton.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            historyButton.widthAnchor.constraint(equalToConstant: 40),
            historyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func historyButtonTapped() {
        delegate?.historyButtonTapped()
    }
}
