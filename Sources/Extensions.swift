import Foundation

typealias AnyVoid = () -> Void

extension Data {
  var string: String? {
    String(data: self, encoding: .utf8)
  }
}

extension String {
  var data: Data? {
    data(using: .utf8)
  }
}
