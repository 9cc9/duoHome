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
        print("开始流式请求，提示词: \(prompt)")
        
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
        
        // 创建URL
        guard let url = URL(string: apiURL) else {
            onComplete(nil, NSError(domain: "AIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "无效的URL"]))
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            print("请求体已准备: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        } catch {
            print("请求体序列化失败: \(error)")
            onComplete(nil, error)
            return
        }
        
        // 创建自定义的流式处理委托
        let streamDelegate = StreamDelegate(onReceive: onReceive, onComplete: onComplete)
        
        // 创建会话并设置委托
        let session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: .main)
        
        // 创建数据任务
        let task = session.dataTask(with: request)
        
        // 保存任务引用到委托中，以便可以在需要时取消
        streamDelegate.task = task
        
        // 开始任务
        task.resume()
        print("流式请求已发送")
    }
    
    // 自定义URLSessionDataDelegate来处理流式数据
    private class StreamDelegate: NSObject, URLSessionDataDelegate {
        private let onReceive: (String) -> Void
        private let onComplete: (String?, Error?) -> Void
        private var fullResponse = ""
        private var buffer = Data()
        private var chunkCount = 0
        
        // 保存任务引用，以便可以在需要时取消
        var task: URLSessionDataTask?
        
        init(onReceive: @escaping (String) -> Void, onComplete: @escaping (String?, Error?) -> Void) {
            self.onReceive = onReceive
            self.onComplete = onComplete
            super.init()
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            print("收到数据片段，大小: \(data.count) 字节")
            buffer.append(data)
            
            // 尝试按行处理缓冲区
            processBuffer()
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                print("流式请求出错: \(error)")
                DispatchQueue.main.async {
                    self.onComplete(nil, error)
                }
                return
            }
            
            // 处理剩余的缓冲区
            processBuffer(isComplete: true)
            
            let finalResponse = self.fullResponse
            print("流式传输完成，共接收\(chunkCount)个内容块，总长度: \(finalResponse.count)")
            DispatchQueue.main.async {
                self.onComplete(finalResponse, nil)
            }
        }
        
        private func processBuffer(isComplete: Bool = false) {
            // 将缓冲区转换为字符串
            guard let bufferString = String(data: buffer, encoding: .utf8) else {
                return
            }
            
            print("处理缓冲区: \(bufferString)")
            
            // 按行分割
            let lines = bufferString.components(separatedBy: "\n")
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = line.dropFirst(6) // 移除 "data: " 前缀
                    print("处理数据行: \(jsonString)")
                    
                    if jsonString == "[DONE]" {
                        print("收到流式传输结束标记")
                        continue
                    }
                    
                    do {
                        if let jsonData = jsonString.data(using: .utf8),
                           let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let delta = firstChoice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            
                            chunkCount += 1
                            self.fullResponse += content
                            print("解析到第\(chunkCount)个内容块: \(content)")
                            
                            DispatchQueue.main.async {
                                self.onReceive(content)
                            }
                        } else {
                            print("无法从JSON中提取内容，完整JSON: \(jsonString)")
                        }
                    } catch {
                        print("解析流式数据出错: \(error)，数据: \(jsonString)")
                    }
                }
            }
            
            // 更新缓冲区，只保留最后一行（如果不是完成状态）
            if !isComplete && !lines.isEmpty {
                if let lastLine = lines.last, let lastLineData = lastLine.data(using: .utf8) {
                    buffer = lastLineData
                } else {
                    buffer = Data()
                }
            } else {
                buffer = Data()
            }
        }
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