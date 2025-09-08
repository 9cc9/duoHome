//
//  ChatTableView.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit

protocol ChatTableViewDelegate: AnyObject {
    func chatTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
}

class ChatTableView: UITableView {
    // 数据源
    var chatMessages: [(sender: String, message: String)] = []
    
    // 代理
    weak var chatDelegate: ChatTableViewDelegate?
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTableView()
    }
    
    private func setupTableView() {
        register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatCell")
        delegate = self
        dataSource = self
        
        // 完全移除分割线
        separatorStyle = .none
        separatorColor = .clear
        separatorEffect = nil
        
        // 设置背景色
        backgroundColor = .systemBackground
        
        // 确保没有分割线
        if #available(iOS 15.0, *) {
            sectionHeaderTopPadding = 0
        }
        
        // 移除默认的分割线
        tableFooterView = UIView()
        
        // 添加表格背景图案
        let patternImage = UIImage(systemName: "bubble.left.and.bubble.right.fill")?.withTintColor(.systemGray6, renderingMode: .alwaysOriginal)
        backgroundView = UIImageView(image: patternImage)
        backgroundView?.contentMode = .scaleAspectFit
        backgroundView?.alpha = 0.1
    }
    
    // MARK: - 公共方法
    func addMessage(sender: String, message: String) {
        chatMessages.append((sender: sender, message: message))
        let indexPath = IndexPath(row: chatMessages.count - 1, section: 0)
        insertRows(at: [indexPath], with: .automatic)
        scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func updateAIMessageCell(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        
        beginUpdates()
        
        if let cell = cellForRow(at: indexPath) as? ChatBubbleCell {
            cell.messageLabel.text = chatMessages[index].message
            // 强制布局更新
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }
        
        endUpdates()
        
        // 确保滚动到最新消息
        scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    func addOrUpdateAIMessage(_ chunk: String) {
        DispatchQueue.main.async {
            // 检查是否已经有AI消息
            if let lastMessageIndex = self.chatMessages.indices.last,
               self.chatMessages[lastMessageIndex].sender == "ai" {
                // 更新现有AI消息
                self.chatMessages[lastMessageIndex].message += chunk
                self.updateAIMessageCell(at: lastMessageIndex)
            } else {
                // 添加新的AI消息
                self.addMessage(sender: "ai", message: chunk)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatBubbleCell
        let message = chatMessages[indexPath.row]
        cell.configure(with: message.message, isUser: message.sender == "user")
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chatDelegate?.chatTableView(tableView, didSelectRowAt: indexPath)
    }
    
    // 强制移除分割线
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
    }
}
