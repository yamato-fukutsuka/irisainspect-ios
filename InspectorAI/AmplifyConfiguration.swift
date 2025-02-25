// AmplifyConfigurationManager.swift
import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSDataStorePlugin
import AWSS3StoragePlugin

struct AmplifyConfigurationManager {
    static func configureAmplify() {
        do {
            // Auth
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            // API (GraphQL)
            try Amplify.add(plugin: AWSAPIPlugin())
            // DataStore
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            // Storage
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            Amplify.Logging.logLevel = .debug
            try Amplify.configure()
            
            print("Amplify configured successfully.")
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
}

