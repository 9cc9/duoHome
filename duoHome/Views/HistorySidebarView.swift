//
//  HistorySidebarView.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import UIKit

protocol HistorySidebarViewDelegate: AnyObject {
    func historySidebarDidSelectConversation(_ conversation: ConversationItem)
    func historySidebarDidClose()
}

class HistorySidebarView: UIView {
    
    weak var delegate: HistorySidebarViewDelegate?
    
    // UI组件
    private let containerView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView()
    
    // 数据源
    private var conversations: [ConversationItem] = []
    
    // 侧边栏宽度
    private let sidebarWidth: CGFloat = 280
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // 设置容器视图
        containerView.backgroundColor = UIColor.systemGray6
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // 设置头部视图
        setupHeaderView()
        
        // 设置表格视图
        setupTableView()
        
        // 设置约束
        setupConstraints()
        
        // 添加点击手势关闭侧边栏
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = UIColor.systemGray6
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        
        // 标题标签
        titleLabel.text = "历史记录"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // 关闭按钮
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        closeButton.setTitleColor(.label, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)
    }
    
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 容器视图约束
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: sidebarWidth),
            
            // 头部视图约束
            headerView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // 标题标签约束
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            // 关闭按钮约束
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // 表格视图约束
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - 公共方法
    func updateConversations(_ conversations: [ConversationItem]) {
        self.conversations = conversations
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func showSidebar() {
        isHidden = false
        containerView.transform = CGAffineTransform(translationX: -sidebarWidth, y: 0)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.containerView.transform = .identity
        }
    }
    
    func hideSidebar(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.containerView.transform = CGAffineTransform(translationX: -self.sidebarWidth, y: 0)
        } completion: { _ in
            self.isHidden = true
            completion?()
        }
    }
    
    // MARK: - 按钮事件
    @objc private func closeButtonTapped() {
        hideSidebar {
            self.delegate?.historySidebarDidClose()
        }
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if !containerView.frame.contains(location) {
            closeButtonTapped()
        }
    }
    
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension HistorySidebarView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        let conversation = conversations[indexPath.row]
        cell.configure(with: conversation)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        delegate?.historySidebarDidSelectConversation(conversation)
        hideSidebar {
            self.delegate?.historySidebarDidClose()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - 对话记录单元格
class ConversationCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let separatorView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // 标题标签
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // 时间标签
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        // 分隔线
        separatorView.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(with conversation: ConversationItem) {
        titleLabel.text = conversation.title.isEmpty ? "无标题对话" : conversation.title
        
        // 格式化时间
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: conversation.gmtCreate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            timeLabel.text = displayFormatter.string(from: date)
        } else {
            timeLabel.text = "未知时间"
        }
    }
}
