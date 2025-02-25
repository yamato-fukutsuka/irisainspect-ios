import SwiftUI
import Amplify
import Combine

// Temporal.DateTime から Date への変換（Amplify の Temporal 型を使っている場合）
extension Temporal.DateTime {
    var foundationDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self.iso8601String) ?? Date()
    }
}

// Message を Equatable に準拠させる（onChange に必要）
extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ChatView

struct ChatView: View {
    let project: Project
    
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    
    var body: some View {
        VStack {
            // メッセージ一覧を ScrollViewReader と LazyVStack で実装
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages, id: \.id) { msg in
                            MessageRow(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: messages) { _ in
                    // 新しいメッセージ追加時に自動で一番下へスクロール
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 入力欄
            HStack {
                TextField("メッセージを入力", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24))
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            
            // AR 撮影画面リンク（必要に応じて）
            NavigationLink(destination: ARInspectionView(project: project)) {
                Text("AR 撮影")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            // 報告書生成ボタン
            Button("報告書生成") {
                generateAndUploadReport()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationBarTitle("チャット - \(project.name)", displayMode: .inline)
        .onAppear {
            observeMessages()
        }
    }
    
    // MARK: - メッセージ送信 (async/await)
    private func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let newMessage = Message(content: trimmed,
                                 isFromUser: true,
                                 projectID: project.id)
        
        do {
            try await Amplify.DataStore.save(newMessage)
            // 入力欄クリア（メインスレッドで更新）
            DispatchQueue.main.async {
                inputText = ""
            }
        } catch {
            print("メッセージ送信失敗: \(error)")
        }
    }
    
    // MARK: - メッセージ取得 (observeQuery)
    private func observeMessages() {
        let predicate = Message.keys.projectID.eq(project.id)
        _ = Amplify.DataStore.observeQuery(for: Message.self, where: predicate, listener: { result in
            switch result {
            case .success(let snapshot):
                DispatchQueue.main.async {
                    // createdAt の昇順にソート（古い順→新しい順）
                    self.messages = snapshot.items.sorted {
                        ($0.createdAt?.foundationDate ?? Date.distantPast) < ($1.createdAt?.foundationDate ?? Date.distantPast)
                    }
                }
            case .failure(let error):
                print("observeQuery error: \(error)")
            }
        })

    }
    
    // MARK: - 報告書生成
    private func generateAndUploadReport() {
        let reportGenerator = ReportGenerator()
        guard let pdfData = reportGenerator.generateReport(analysisResult: "解析結果をここに差し込む") else {
            print("報告書生成失敗")
            return
        }
        
        let filename = "InspectionReport_\(UUID().uuidString).pdf"
        S3Uploader.shared.uploadReport(pdfData: pdfData, fileName: filename) { url, error in
            if let error = error {
                print("アップロードエラー: \(error)")
            } else if let url = url {
                print("報告書URL: \(url.absoluteString)")
            }
        }
    }
}

