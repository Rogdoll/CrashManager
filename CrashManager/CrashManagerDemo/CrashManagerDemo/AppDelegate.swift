//
//  AppDelegate.swift
//  CrashManagerDemo
//
//  Created by Pikachu on 2019/8/14.
//  Copyright © 2019 Rogdoll. All rights reserved.
//

import UIKit
import CrashManager

@UIApplicationMain final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        CrashManager.install { (infos) in
            print("install print:\n",infos.joined())
        }
        
        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
//        let str: String? = nil
//        let a = "a" + str!

        return true
    }
}

