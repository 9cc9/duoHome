//
//  ConversationService.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import Foundation

// MARK: - 数据模型
struct CreateConversationRequest: Codable {
    let title: String
    let llmModel: String
}

struct AddChatRequest: Codable {
    let content: String
    let conversationId: Int
    let type: String
    let role: String
}

struct ConversationResponse: Codable {
    let success: Bool
    let resultCode: String
    let data: ConversationData
    let values: [String]
}

struct ConversationData: Codable {
    let id: Int
    let title: String
    let llmModel: String
    let ext: [String: String]
    let chatList: [String]
    let gmtCreate: String?
    let gmtModified: String?
}

struct AddChatResponse: Codable {
    let success: Bool
    let resultCode: String
    let data: ChatData?
    let values: [ChatData]
}

struct ChatData: Codable {
    let id: Int?
    let content: String?
    let conversationId: Int?
    let type: String?
    let role: String?
    let gmtCreate: String?
    let gmtModified: String?
}

// MARK: - 错误类型
enum ConversationError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有接收到数据"
        case .invalidResponse:
            return "无效的响应格式"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        }
    }
}

// MARK: - ConversationService
class ConversationService {
    static let shared = ConversationService()
    
    private let baseURL = "http://127.0.0.1:8081"
    private var currentConversationId: Int?
    
    private init() {}
    
    // MARK: - 创建新会话
    func createConversation(title: String, firstMessage: String, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/conversations/add.json") else {
            completion(.failure(ConversationError.invalidURL))
            return
        }
        
        let request = CreateConversationRequest(
            title: title,
            llmModel: "defaultModel"
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        urlRequest.setValue("zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7", forHTTPHeaderField: "accept-language")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(ConversationError.decodingError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(ConversationError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ConversationError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ConversationResponse.self, from: data)
                print("✅ [ConversationService] 解析响应成功: \(response)")
                
                if response.success && response.resultCode == "SUCCESS" {
                    let conversationId = response.data.id
                    print("🎉 [ConversationService] 会话创建成功，ID: \(conversationId)")
                    self?.currentConversationId = conversationId
                    
                } else {
                    print("❌ [ConversationService] 服务器返回错误: \(response.resultCode)")
                    completion(.failure(ConversationError.invalidResponse))
                }
            } catch {
                print("❌ [ConversationService] 解析响应失败: \(error)")
                print("❌ [ConversationService] 解析错误详情: \(error.localizedDescription)")
                completion(.failure(ConversationError.decodingError(error)))
            }
        }.resume()
    }
    
    // MARK: - 添加聊天消息
    func addChatMessage(content: String, role: String, conversationId: Int? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        let targetConversationId = conversationId ?? currentConversationId
        
        guard let conversationId = targetConversationId else {
            print("❌ [ConversationService] 没有可用的会话ID")
            completion(.failure(ConversationError.invalidResponse))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/conversations/addChat.json") else {
            completion(.failure(ConversationError.invalidURL))
            return
        }
        
        let request = AddChatRequest(
            content: content,
            conversationId: conversationId,
            type: "TEXT",
            role: role
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("*/*", forHTTPHeaderField: "accept")
        urlRequest.setValue("zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7", forHTTPHeaderField: "accept-language")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(ConversationError.decodingError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(ConversationError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ConversationError.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(AddChatResponse.self, from: data)
                print("✅ [ConversationService] 添加聊天消息响应: \(response)")
                
                if response.success && response.resultCode == "SUCCESS" {
                    print("✅ [ConversationService] 聊天消息添加成功")
                    
                    // 打印添加的聊天记录详情
                    if let chatData = response.values.first {
                        print("📝 [ConversationService] 添加的聊天记录: ID=\(chatData.id ?? -1), 角色=\(chatData.role ?? "未知"), 内容=\(chatData.content ?? "无内容")")
                    }
                    
                    completion(.success(()))
                } else {
                    print("❌ [ConversationService] 服务器返回错误: \(response.resultCode)")
                    completion(.failure(ConversationError.invalidResponse))
                }
            } catch {
                print("❌ [ConversationService] 解析添加聊天消息响应失败: \(error)")
                completion(.failure(ConversationError.decodingError(error)))
            }
        }.resume()
    }
    
    // MARK: - 获取当前会话ID
    func getCurrentConversationId() -> Int? {
        return currentConversationId
    }
    
    // MARK: - 重置会话
    func resetConversation() {
        currentConversationId = nil
        print("🔄 [ConversationService] 会话已重置")
    }
    
    // MARK: - 便捷方法：添加用户消息
    func addUserMessage(_ content: String, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        addChatMessage(content: content, role: "user", completion: completion)
    }
    
    // MARK: - 便捷方法：添加AI消息
    func addAIMessage(_ content: String, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        addChatMessage(content: content, role: "assistant", completion: completion)
    }
}
