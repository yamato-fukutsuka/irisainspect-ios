//
//  S3Uploader.swift
//
import Foundation
import Amplify

class S3Uploader {
    static let shared = S3Uploader()
    private init() {}
    
    func uploadReport(pdfData: Data, fileName: String, completion: @escaping (URL?, Error?) -> Void) {
        let key = "reports/\(fileName)"
        Task {
            do {
                let uploadTask = Amplify.Storage.uploadData(
                    key: key,
                    data: pdfData,
                    options: .init(accessLevel: .private, contentType: "application/pdf")
                )
                // uploadTask.value を await して最終結果を取得する
                let uploadedKey = try await uploadTask.value
                print("アップロード成功。キー: \(uploadedKey)")
            } catch {
                print("アップロード失敗: \(error.localizedDescription)")
            }
        }

    }
}

