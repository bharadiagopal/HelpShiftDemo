//
//  ViewController.swift
//  DBDemo
//
//  Created by Gopal Bharadia on 29/06/16.
//  Copyright © 2016 Gopal Bharadia. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let empDataDictionary : NSMutableDictionary = [
            "employeeId": 12345,
            "employeeName": "Gopal",
            "employeeAge": 30
        ]
        EMPLOYEE.insert(empDataDictionary)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

