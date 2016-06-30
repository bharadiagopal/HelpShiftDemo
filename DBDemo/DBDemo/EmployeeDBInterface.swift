//
//  EmployeeDBInterface.swift
//  DBDemo
//
//  Created by Gopal Bharadia on 29/06/16.
//  Copyright © 2016 Gopal Bharadia. All rights reserved.
//

import UIKit
import Foundation

let EMPLOYEE = EmployeeDBInterface.sharedStore

enum EmployeeDB
{
    case EmployeeValue
    
    func cleanSQL() -> String
    {
        switch self
        {
        case .EmployeeValue: return "delete from Employee_info;"
        }
    }
}

class EmployeeDBInterface: NSObject {

    let db:DatabaseManager
    
    /** @ Created by Pawan Saini on 03/16/2016. v1.0
     *
     * @ Function name: sharedStore
     *
     * @ description: Create singlton object of AwardDBInterface
     */
    
    
    class var sharedStore: EmployeeDBInterface {
        dispatch_once(&SingltonMutex.token) {
            SingltonMutex.instance = EmployeeDBInterface()
        }
        return SingltonMutex.instance!
    }
    struct SingltonMutex {
        static var instance: EmployeeDBInterface?
        static var token: dispatch_once_t = 0
    }
    
    override init() {
        
        db = DatabaseManager.sharedDatabaseManager()
    }
    
    /** @ Created by Pawan Saini on 03/16/2016. v1.0
     *
     * @ Function name: delete
     *
     * @ description: Delete Rewards information from database
     */
    func delete(type:EmployeeDB = EmployeeDB.EmployeeValue)
    {
        dispatch_async(AppDelegate.getSharedInstance().dbSequenceQueue!, { () -> Void in
            
            if (self.db.executeQuery(type.cleanSQL()))
            {
                if(kFYDebugLevel1){
                    print("\(type.cleanSQL()) .......... ok")
                }
            }else
            {
                if(kFYDebugLevel1){
                    print(self.db.lastErrorMessage())
                }
            }
        })
    }
    
    /** @ Created by Pawan Saini on 03/16/16. v1.0
     *
     * @ Function name: retrieve
     *
     * @ description: Retrieve reward information
     */
    func retrieve(completionHandler:(resultSet:AnyObject? )-> ())
    {
        //Subsequent execution of queries
        dispatch_async(AppDelegate.getSharedInstance().dbSequenceQueue!, { () -> Void in
            
            let employeeRetriveQuery : String = NSString.init(format: "select * from Employee_info") as String
            
            //Execute query
            let employeeDictionary : AnyObject? = self.db.retriveQuery(employeeRetriveQuery, isDictionary: false)
            
            completionHandler(resultSet: employeeDictionary)
        })
    }
    
    /** @ Created by Pawan Saini on 03/16/16. v1.0
     *
     * @ Function name: insert
     *
     * @ description: Insertion into table_reward
     */
    func insert(dictionary : NSDictionary)
    {
        //Subsequent execution of queries
        dispatch_async(AppDelegate.getSharedInstance().dbSequenceQueue!, { () -> Void in
            
            let employeeMasterQuery : String = NSString.init(format: "insert into Employee_info('emp_id','emp_name','emp_age') values (?,?,?)") as String
            
            //Execute query
            self.db.executeQuery(employeeMasterQuery, withArgumentsInArray:[dictionary.valueForKey("employeeId")!,dictionary.valueForKey("employeeName")!,dictionary.valueForKey("employeeAge")!])
        })
    }
    
}
