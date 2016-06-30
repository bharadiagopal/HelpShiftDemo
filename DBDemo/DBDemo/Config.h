//
//  Config.h
//  MapDemo
//
//  Created by Chandan Kumar on 08/12/14.
//  Copyright (c) 2014 Finny Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



//--------- Via core Location framework -----
//extern CLLocationManager *locationManager;
//extern CLLocation                   *currentLocation;

FOUNDATION_EXPORT BOOL const kFYDebugLevel1; // Show debug level NSLOG
FOUNDATION_EXPORT BOOL const kFYDebugLevel2; // Show debug level NSLOG
FOUNDATION_EXPORT BOOL const kFYDebugLevel3; // Show debug level NSLOG
FOUNDATION_EXPORT BOOL const kFYDebugError;  // Show erros NSLOG

//configuration section...
extern NSString   *kFYSiteURL;

extern NSString *kFYDatabaseName;

extern float keyBoardHeight;
