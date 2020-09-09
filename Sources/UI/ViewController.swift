import UIKit

class ViewController: UIViewController {

  lazy var reach = Reachability.forInternetConnection()

  weak var uiHandler: (UiHandler & UiProvider)? {
    didSet {
      uiHandler?.reloadHandler = reloadTableView
    }
  }

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var mapViewWrapperHeight: NSLayoutConstraint!
  @IBOutlet var mapWrapperView: MapWrapperView!

  @IBOutlet weak var gpsButton: UIBarButtonItem!
  @IBOutlet weak var peersButton: UIBarButtonItem!
  @IBOutlet weak var wwanButton: UIBarButtonItem!

  func reloadTableView() {
    tableView.reloadData()

    let numberOfPeers = uiHandler?.numberOfPeers ?? 0

    peersButton.title = "\(numberOfPeers) Online"
  }

  private var locMan: LocationMan?
  private var isAnimating = false
  private var isGPSSharingOn = true {
    didSet {
      if isGPSSharingOn {
        locMan = LocationMan(mapWrapperView.update)
      } else {
        locMan = nil

        mapWrapperView.update(with: nil)
      }

      guard !isAnimating else { return }
      isAnimating = true

      let newHeight = isGPSSharingOn ? 250 : view.safeAreaInsets.top
      let topInset = newHeight - self.view.safeAreaInsets.top

      mapViewWrapperHeight.constant = newHeight

      UIView.animate(
        withDuration: 0.150,
        delay: 0,
        options: .curveEaseOut,
        animations: {
          self.view.layoutIfNeeded()

          self.tableView.contentInset.top = topInset
      },
        completion: { _ in
          self.isAnimating = false
      })

      gpsButton.title = isGPSSharingOn ? "GPS (on)" : "GPS (off)"
    }
  }
  
  @IBAction func gpsButtonDidTap(_ sender: UIBarButtonItem) {
    isGPSSharingOn.toggle()
  }

  @IBAction func peersButtonDidTap(_ sender: UIBarButtonItem) {
    reloadTableView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "🤍❤️🤍"

    tableView.dataSource = self
    tableView.delegate = self
    
    setupMapWrapperView()

    DispatchQueue.main.async { self.isGPSSharingOn = false }

    setupReachability()
  }

  private func setupMapWrapperView() {
    view.addSubview(mapWrapperView)
    mapWrapperView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    mapWrapperView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
  }

  private func setupReachability() {

    wwanButton.title = reach?.currentReachabilityString()

    reach?.reachableBlock = { reach in
      DispatchQueue.main.async { [weak self] in
        self?.wwanButton.title = reach?.currentReachabilityString()
      }
    }

    reach?.unreachableBlock = { _ in
      DispatchQueue.main.async { [weak self] in
        self?.wwanButton.title = "No Internet"
      }
    }

    reach?.startNotifier()
  }

  @IBAction func composeDidTap(_ sender: Any) {
    let alert = UIAlertController(title: "Broadcast", message: "Enter 140 chars messasge", preferredStyle: .alert)

    alert.addTextField { (tf) in
      tf.placeholder = "БЧБ"
    }

    alert.addAction(UIAlertAction(title: "Send", style: .destructive, handler: { [weak alert] _ in
      if let text = alert?.textFields?.first?.text {
        self.uiHandler?.broadcastMessage(text)
      }
    }))

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    present(alert, animated: true)
  }

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    uiHandler?.dataCount ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell

    if let uiHandler = uiHandler {

      let data = uiHandler.dataAt(indexPath)

      cell.t1?.text = data.msg

//      let name = uiHandler.isConflicting(data.simpleFrom) ? data.from : data.simpleFrom

      cell.t2?.text = data.simpleFrom + " / " + data.simpleDate
    }

    return cell
  }

}
