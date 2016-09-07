//
//  ViewController.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/19/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let api = Api()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        api.getUserInfo("plokmijn") { result in
            do {
                let _ = try result.unwrap()
                self.view.backgroundColor = UIColor.redColor()
            } catch let error as NSError {
                debugPrint("Get user error: \(error.localizedDescription)")
            }
        }
    }
}
