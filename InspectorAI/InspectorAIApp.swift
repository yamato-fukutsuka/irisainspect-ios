//
//  InspectorAIApp.swift
//
import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSDataStorePlugin
import AWSS3StoragePlugin

@main
struct InspectorAIApp: App {
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
    
    private func configureAmplify() {
        do {
            // 認証プラグイン
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            // GraphQL APIプラグイン (必要なければ省略可)
            try Amplify.add(plugin: AWSAPIPlugin())
            // DataStoreプラグイン（Models登録）
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            // Storageプラグイン
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            Amplify.Logging.logLevel = .debug
            try Amplify.configure()
            print("Amplify configured successfully")
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
}

