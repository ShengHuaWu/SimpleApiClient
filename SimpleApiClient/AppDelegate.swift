//
//  AppDelegate.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/19/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let api = Api()
//        api.getUserInfo("1qaz9ijn") { result in            
//            do {
//                let user = try result.unwrap()
//                debugPrint(user)
//            } catch {
//                debugPrint(error)
//            }
//        }
        
        let user = User(userId: "1qaz9ijn", name: "joe lin", email: "joe.lin@gmail.com", description: "i am immortal joe.")
        api.updateUserInfo(user) { result in
            do {
                let user = try result.unwrap()
                debugPrint(user)
            } catch {
                debugPrint(error)
            }
        }
        
        return true
    }
}

