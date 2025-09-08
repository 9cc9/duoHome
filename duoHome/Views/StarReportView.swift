import UIKit

class StarReportView: UIView {
    private let tableView = UITableView()
    private let headerView = UIView()
    private let totalStarsLabel = UILabel()
    private var weeklyReport: [(date: Date, stars: Int)] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 设置表头
        headerView.backgroundColor = .systemBackground
        
        totalStarsLabel.font = .systemFont(ofSize: 24, weight: .bold)
        totalStarsLabel.textAlignment = .center
        headerView.addSubview(totalStarsLabel)
        
        // 设置表格
        tableView.register(StarRecordCell.self, forCellReuseIdentifier: "StarCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = headerView
        addSubview(tableView)
        
        // 布局约束
        totalStarsLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            totalStarsLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            totalStarsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            totalStarsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            totalStarsLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func updateReport() {
        weeklyReport = StarManagementService.shared.getWeeklyReport()
        let totalStars = weeklyReport.reduce(0) { $0 + $1.stars }
        totalStarsLabel.text = "本周总共获得 ⭐️ \(totalStars) 颗"
        tableView.reloadData()
    }
}

// MARK: - UITableView DataSource & Delegate
extension StarReportView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weeklyReport.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StarCell", for: indexPath) as! StarRecordCell
        let record = weeklyReport[indexPath.row]
        cell.configure(date: record.date, stars: record.stars)
        return cell
    }
}

// MARK: - Star Record Cell
class StarRecordCell: UITableViewCell {
    private let dateLabel = UILabel()
    private let starsLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        dateLabel.font = .systemFont(ofSize: 16)
        starsLabel.font = .systemFont(ofSize: 16)
        
        contentView.addSubview(dateLabel)
        contentView.addSubview(starsLabel)
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        starsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            starsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            starsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(date: Date, stars: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        dateLabel.text = formatter.string(from: date)
        starsLabel.text = String(repeating: "⭐️", count: stars)
    }
} 