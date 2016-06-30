//
//  AppDelegate.swift
//  DBDemo
//
//  Created by Gopal Bharadia on 29/06/16.
//  Copyright © 2016 Gopal Bharadia. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var dbSequenceQueue:dispatch_queue_t? //Sequential dispatch queue


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //Create dispatch queue that application submits blocks for subsequent execution.
        dbSequenceQueue = dispatch_queue_create(DFY_DB_SEQUENCE_QUEUE, nil)
        
        //Check and create Database file
        DatabaseManager.checkAndCreateDatabase()
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK:-
    // MARK:  Other Helping Functions
    // MARK:-
    
    /**Created by Chandan Kumar on 10/26/2015 v1.0
     *
     * Function name: getSharedInstance
     *
     * @description: create singalton of AppDelegate object
     */
    class func getSharedInstance() -> AppDelegate
    {
        return UIApplication.sharedApplication().delegate as! AppDelegate // create a singalton object.
    }


}

