// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "bf41e8b29cafc9b13ea2d3f4854daa39"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Project.self)
    ModelRegistry.register(modelType: Message.self)
  }
}