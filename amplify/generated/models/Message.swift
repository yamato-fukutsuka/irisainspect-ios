// swiftlint:disable all
import Amplify
import Foundation

public struct Message: Model {
  public let id: String
  public var content: String
  public var isFromUser: Bool
  public var projectID: String
  public var owner: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String,
      isFromUser: Bool,
      projectID: String,
      owner: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.isFromUser = isFromUser
      self.projectID = projectID
      self.owner = owner
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}