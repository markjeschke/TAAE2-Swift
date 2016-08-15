//
//  AppDelegate.swift
//  TAAE2
//
//  Created by Mark Jeschke on 7/17/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var audio: AEAudioController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.audio = AEAudioController();
        do {
            try self.audio!.start();
        } catch {
            NSNotificationCenter.defaultCenter().postNotificationName("alertController", object: self, userInfo:["error":"Audio engine is unavailable."])
        }
        return true
    }

    func applicationWillTerminate(application: UIApplication) {
      audio!.stop()
    }


}

