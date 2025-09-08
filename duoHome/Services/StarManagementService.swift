import CoreData
import Foundation

class StarManagementService {
    static let shared = StarManagementService()
    
    private let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "duoHome")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("CoreData加载失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 星星管理方法
    func addStars(_ count: Int, forDate date: Date = Date(), notes: String? = nil) {
        let context = container.viewContext
        
        // 获取当天记录或创建新记录
        if let record = fetchRecord(for: date) {
            record.stars += Int16(count)
        } else {
            let newRecord = StarRecord(context: context)
            newRecord.date = date
            newRecord.stars = Int16(count)
            newRecord.notes = notes
        }
        
        saveContext()
    }
    
    func removeStars(_ count: Int, forDate date: Date = Date()) {
        let context = container.viewContext
        
        if let record = fetchRecord(for: date) {
            record.stars = max(0, record.stars - Int16(count))
            saveContext()
        }
    }
    
    func getStars(forDate date: Date = Date()) -> Int {
        guard let record = fetchRecord(for: date) else { return 0 }
        return Int(record.stars)
    }
    
    func getWeeklyReport() -> [(date: Date, stars: Int)] {
        let context = container.viewContext
        let calendar = Calendar.current
        
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let request = NSFetchRequest<StarRecord>(entityName: "StarRecord")
        request.predicate = NSPredicate(format: "date >= %@", startOfWeek as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let records = try context.fetch(request)
            records.forEach { record in
                print("星星记录 - 日期: \(record.date?.formatted() ?? "未知"), 数量: \(record.stars)")
            }
            return records.map { (date: $0.date ?? Date(), stars: Int($0.stars)) }
        } catch {
            print("获取周报失败: \(error)")
            return []
        }
    }
    
    func resetWeeklyStars() {
        let context = container.viewContext
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let request = NSFetchRequest<StarRecord>(entityName: "StarRecord")
        request.predicate = NSPredicate(format: "date >= %@", startOfWeek as NSDate)
        
        do {
            let records = try context.fetch(request)
            records.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("重置星星失败: \(error)")
        }
    }
    
    // MARK: - 辅助方法
    private func fetchRecord(for date: Date) -> StarRecord? {
        let context = container.viewContext
        let calendar = Calendar.current
        
        // 获取目标日期的开始和结束时间
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request = NSFetchRequest<StarRecord>(entityName: "StarRecord")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      startOfDay as NSDate,
                                      endOfDay as NSDate)
        
        do {
            let records = try context.fetch(request)
            return records.first
        } catch {
            print("获取记录失败: \(error)")
            return nil
        }
    }
    
    private func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("保存失败: \(error)")
            }
        }
    }
} 