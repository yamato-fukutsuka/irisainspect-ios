// swiftlint:disable all
import Amplify
import Foundation

public struct ChatLog: Model {
  public let id: String
  public var projectId: String
  public var messages: String
  public var timestamp: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      projectId: String,
      messages: String,
      timestamp: Temporal.DateTime) {
    self.init(id: id,
      projectId: projectId,
      messages: messages,
      timestamp: timestamp,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      projectId: String,
      messages: String,
      timestamp: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.projectId = projectId
      self.messages = messages
      self.timestamp = timestamp
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}