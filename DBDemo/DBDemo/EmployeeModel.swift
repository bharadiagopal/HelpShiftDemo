//
//  EmployeeModel.swift
//  DBDemo
//
//  Created by Gopal Bharadia on 29/06/16.
//  Copyright © 2016 Gopal Bharadia. All rights reserved.
//

import UIKit

class EmployeeModel: NSObject {

    // Memeber variables
    var employeeId : Int = 0
    var employeeName : String = ""
    var employeeAge : String = ""
    
    // MARK: -
    // MARK: Initialise Functions
    // MARK: -
    
    required override init() {
        super.init()
    }
    
    init(paramDictionary: NSDictionary) {
        
        super.init()
        
        if(!(paramDictionary.valueForKey("employeeId") as AnyObject? is NSNull) && paramDictionary.valueForKey("employeeId") != nil)
        {
            self.employeeId = paramDictionary.valueForKey("employeeId") as! Int
        }
        if(!(paramDictionary.valueForKey("employeeName") as AnyObject? is NSNull) && paramDictionary.valueForKey("employeeName") != nil)
        {
            self.employeeName = paramDictionary.valueForKey("employeeName") as! String
        }
        if(!(paramDictionary.valueForKey("employeeAge") as AnyObject? is NSNull) && paramDictionary.valueForKey("employeeAge") != nil)
        {
            self.employeeAge = paramDictionary.valueForKey("employeeAge") as! String
        }
        
    }
}
