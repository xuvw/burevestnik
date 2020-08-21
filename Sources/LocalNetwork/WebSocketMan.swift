import Foundation

protocol NetInvoker {
  func invoke(cmd: Command, args: Arguments)
}

enum Command: String, Codable {
  case getTime,
       foundPeer,
       lostPeer,
       sendToPeer,
       didReceiveFromPeer
}

struct Arguments: Codable {
  let peerID: String?, data: String?, TS: TimeInterval?

  var date: Date? {
    TS.flatMap(Date.init(timeIntervalSince1970:))
  }
}

class WebSocketConn {

  struct Request: Codable {
    let Cmd: Command, Args: Arguments
  }

  struct Response: Codable {
    enum Result: String, Codable {
      case ok
    }

    var result: Result = .ok
    let time: TimeInterval?
  }

  weak var api: APICallbacks! {
    didSet {
      connect()
    }
  }

  private let wssURL: URL
  private var wsTask: URLSessionWebSocketTask?

  init(wss: URL) {
    self.wssURL = wss
  }

  func connect() {
    wsTask?.cancel(with: .normalClosure, reason: nil)

    wsTask = URLSession.shared.webSocketTask(with: wssURL)
    wsTask?.resume()

    receieve()
  }

  func receieve() {

    wsTask?.receive { [weak self] (result) in
      switch result {
      case .failure(let err):
        debugPrint(err)

      case .success(let message):

        switch message {
        case .string(let text):
          debugPrint("Received string: \(text)")

          guard let data = text.data, let request = try? JSONDecoder().decode(Request.self, from: data) else { return }

          self?.invoke(cmd: request.Cmd, args: request.Args)

        default:
          assertionFailure()
        }

        self?.receieve()
      }
    }
  }

  func sendToWs(_ data: Codable) {

    func _send(_ str: String) {
      wsTask?.send(.string(str)) { (err) in
        if let err = err {
          debugPrint(err)
        }
      }
    }

    if let rq = (data as? Request), let json = try? JSONEncoder().encode(rq).string {
      _send(json)

    } else if let rp = (data as? Response), let json = try? JSONEncoder().encode(rp).string {
      _send(json)
    }
  }

}


extension WebSocketConn {

  func invoke(cmd: Command, args: Arguments) {

    switch cmd {

    // funcs

    case .getTime:
      self.tick()

    case .sendToPeer:
      guard let peerID = args.peerID, let data = args.data?.data else { return }

      self.sendToPeer(peerID: peerID, data: data)

    //      sessionSend(to: peerID, data: data)

    // callbacks

    case .foundPeer:
      guard let peerID = args.peerID, let date = args.date else { return }

      api.foundPeer(peerID: peerID, date: date)

    case .lostPeer:
      guard let peerID = args.peerID, let date = args.date else { return }

      api.foundPeer(peerID: peerID, date: date)

    case .didReceiveFromPeer:
      guard let peerID = args.peerID, let data = args.data?.data else { return }

      api.didReceiveFromPeer(peerID: peerID, data: data)

    }
  }

}

extension WebSocketConn: APIFuncs {

  func tick() {
    sendToWs(Response(time: Date().timeIntervalSince1970))
  }

  func sendToPeer(peerID: String, data: Data) {
    sendToWs(Request(Cmd: .sendToPeer,
                     Args: .init(peerID: peerID,
                                 data: data.string,
                                 TS: nil)))
  }

}
