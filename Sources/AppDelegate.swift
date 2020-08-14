//
//  AppDelegate.swift
//  burevestnik
//
//  Created by Marat Saytakov on 12.08.2020.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  private var apiMan: APIMan!

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    window?.tintColor = .systemRed

    let mesh = MeshController()
    let nc = window?.rootViewController as? UINavigationController
    let vc = nc?.topViewController as? ViewController
    vc?.uiHandler = mesh

    let wssURL = URL(string: "wss://yandex.ru")!
    let local = WebSocketConn(wss: wssURL)
    let _ = BtMan()

    apiMan = APIMan(meshController: mesh, localNetwork: local)
    mesh.api = apiMan
    local.api = apiMan

    return true
  }

}