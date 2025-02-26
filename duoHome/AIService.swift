//
//  AIService.swift
//  duoHome
//
//  Created by 贝贝 on 2025/2/24.
//

import Foundation

class AIService {
    // 阿里云大模型API地址（OpenAI兼容模式）
    private let apiURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    // 您的API密钥
    private let apiKey: String
    
    // 初始化方法
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // 定义回调类型
    typealias CompletionHandler = (String?, Error?) -> Void
    typealias StreamHandler = (String) -> Void
    
    // 发送消息到AI并获取回复（非流式）
    func sendMessage(prompt: String, completion: @escaping CompletionHandler) {
        // 创建请求体
        let requestBody: [String: Any] = [
            "model": "qwen-max", // 使用阿里云的模型
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 800
        ]
        
        // 发送请求
        sendRequest(requestBody: requestBody, isStreaming: false) { data, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有返回数据"]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content, nil)
                } else {
                    completion(nil, NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "解析响应失败"]))
                }
            } catch {
                completion(nil, error)
            }
        }
    }
    
    // 发送消息到AI并获取流式回复
    func sendMessageStream(prompt: String, onReceive: @escaping StreamHandler, onComplete: @escaping CompletionHandler) {
        // 创建请求体
        let requestBody: [String: Any] = [
            "model": "qwen-max", // 使用阿里云的模型
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 800,
            "stream": true // 启用流式输出
        ]
        
        // 创建URL会话任务
        guard let url = URL(string: apiURL) else {
            onComplete(nil, NSError(domain: "AIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            onComplete(nil, error)
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    onComplete(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    onComplete(nil, NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有返回数据"]))
                }
                return
            }
            
            // 处理流式响应
            let responseString = String(data: data, encoding: .utf8) ?? ""
            let lines = responseString.components(separatedBy: "\n")
            
            var fullResponse = ""
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = line.dropFirst(6) // 移除 "data: " 前缀
                    if jsonString == "[DONE]" {
                        break
                    }
                    
                    do {
                        if let jsonData = jsonString.data(using: .utf8),
                           let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let delta = firstChoice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            
                            fullResponse += content
                            
                            DispatchQueue.main.async {
                                onReceive(content)
                            }
                        }
                    } catch {
                        print("解析流式数据出错: \(error)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                onComplete(fullResponse, nil)
            }
        }
        
        task.resume()
    }
    
    // 发送请求的通用方法
    private func sendRequest(requestBody: [String: Any], isStreaming: Bool, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: apiURL) else {
            completion(nil, NSError(domain: "AIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(nil, error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            completion(data, nil)
        }
        
        task.resume()
    }
} 