//
//  TopHeaderView.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit

class TopHeaderView: UIView {
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    
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
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 背景视图约束
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 标题标签约束
            titleLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -15)
        ])
    }
}
