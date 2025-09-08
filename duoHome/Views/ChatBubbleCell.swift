//
//  ChatBubbleCell.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit

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
        
        // 确保没有分割线
        separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
        
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
            // 用户消息样式 - 使用浅粉色背景
            bubbleView.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0) // 浅粉色背景
            
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
            
            // 约束调整 - 用户消息：头像在右边，气泡在左边
            NSLayoutConstraint.deactivate(bubbleView.constraints.filter { 
                $0.firstAttribute == .leading || $0.firstAttribute == .trailing 
            })
            NSLayoutConstraint.deactivate(avatarImageView.constraints.filter { 
                $0.firstAttribute == .leading || $0.firstAttribute == .trailing 
            })
            NSLayoutConstraint.activate([
                // 头像在右边
                avatarImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                // 气泡在头像左边
                bubbleView.trailingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: -8),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 16)
            ])
        } else {
            // AI消息样式 - 左侧浅色气泡
            bubbleView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            
            // AI消息文字颜色
            messageLabel.textColor = .black
            
            // AI头像 - 使用可爱的星星图标
            avatarImageView.image = UIImage(systemName: "star.fill")
            avatarImageView.tintColor = UIColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0) // 浅粉色图标
            
            // 确保AI头像也是圆形
            avatarImageView.layer.cornerRadius = 18
            avatarImageView.clipsToBounds = true
            
            // 添加背景色使圆形更明显（可选）
            avatarImageView.backgroundColor = UIColor(red: 0.98, green: 0.95, blue: 0.9, alpha: 1.0) // 浅橘色背景
            
            // 约束调整 - AI消息：头像在左边，气泡在右边
            NSLayoutConstraint.deactivate(bubbleView.constraints.filter { 
                $0.firstAttribute == .leading || $0.firstAttribute == .trailing 
            })
            NSLayoutConstraint.deactivate(avatarImageView.constraints.filter { 
                $0.firstAttribute == .leading || $0.firstAttribute == .trailing 
            })
            NSLayoutConstraint.activate([
                // 头像在左边
                avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                // 气泡在头像右边
                bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
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
        bubbleView.backgroundColor = .clear
        avatarImageView.image = nil
        avatarImageView.backgroundColor = .clear
        avatarImageView.layer.borderWidth = 0
        avatarImageView.layer.borderColor = UIColor.clear.cgColor
        
        // 确保没有分割线
        separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
    }
}
