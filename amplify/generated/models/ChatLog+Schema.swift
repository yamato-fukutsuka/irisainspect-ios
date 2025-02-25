// swiftlint:disable all
import Amplify
import Foundation

extension ChatLog {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case projectId
    case messages
    case timestamp
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let chatLog = ChatLog.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "ChatLogs"
    model.syncPluralName = "ChatLogs"
    
    model.attributes(
      .primaryKey(fields: [chatLog.id])
    )
    
    model.fields(
      .field(chatLog.id, is: .required, ofType: .string),
      .field(chatLog.projectId, is: .required, ofType: .string),
      .field(chatLog.messages, is: .required, ofType: .string),
      .field(chatLog.timestamp, is: .required, ofType: .dateTime),
      .field(chatLog.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(chatLog.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ChatLog: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}