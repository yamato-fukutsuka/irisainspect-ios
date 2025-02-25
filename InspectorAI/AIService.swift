import Foundation

class AIService {
    static let shared = AIService()
    
    
    private let apiKey = Secrets.apiKey
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    
    // ユーザーのメッセージと過去の会話履歴を渡して、AI からの返答メッセージを取得する関数
    func sendChat(messages: [[String: String]], completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // ChatGPT API のパラメータ（モデル、メッセージ履歴など）
        let parameters: [String: Any] = [
            "model": "gpt-4-turbo",  // 必要に応じて "gpt-4" に変更可能
            "messages": messages
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            completion(nil)
            return
        }
        
        // API を呼び出す
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API 呼び出しエラー: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            // レスポンス JSON をパースします
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion(nil)
                }
            } catch {
                print("JSON パースエラー: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}

