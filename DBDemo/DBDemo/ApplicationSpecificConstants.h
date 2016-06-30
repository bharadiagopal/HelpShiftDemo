/*
 Localizable.strings
 SPEXPRESS
 
 Created by Chandan Kumar on 08/12/14.
 Copyright (c) 2014 Finny Inc. All rights reserved.
 */


#ifndef ApplicationSpecificConstants_h
#define ApplicationSpecificConstants_h

/**
 Constants:-
 
 This header file holds all configurable constants specific  to this application.
 
 */

////////////////////////////////////////SOME MACROS TO MAKE YOUR PROGRAMING LIFE EASIER/////////////////////////////////////////

/**
 return if no internet connection is available with and without error message
 */

#define RETURN_IF_NO_INTERNET_AVAILABLE_WITH_USER_WARNING if (![CommonFunctions getStatusForNetworkConnectionAndShowUnavailabilityMessage:YES]) return;
#define RETURN_IF_NO_INTERNET_AVAILABLE                   if (![CommonFunctions getStatusForNetworkConnectionAndShowUnavailabilityMessage:NO]) return;


/**
 get status of internet connection
 */
#define IS_INTERNET_AVAILABLE_WITH_USER_WARNING           [CommonFunctions performSelectorOnMainThread:@selector(getStatusForNetworkConnectionAndShowUnavailabilityMessage:) withObject:YES waitUntilDone:NO];
#define IS_INTERNET_AVAILABLE                             [CommonFunctions performSelectorOnMainThread:@selector(getStatusForNetworkConnectionAndShowUnavailabilityMessage:) withObject:NO waitUntilDone:NO];

#define SHOW_SERVER_NOT_RESPONDING_MESSAGE                [CommonFunctions performSelectorOnMainThread:@selector(showServerNotFoundError) withObject:nil waitUntilDone:NO];

//FREQUENTLY USED OBJECT AND KEYS

#define MIN_DUR 2

#define DFY_WEBSERVICE_HEADER_USER_ID_KEY       @"Userid"
#define DFY_WEBSERVICE_HEADER_TOKEN_KEY         @"Token"
#define DFY_WEBSERVICE_HEADER_LANGUAGE_KEY      @"Lang"
#define DFY_WEBSERVICE_HEADER_KEY               @"Header"

//FREQUENTLY USED HEADERS FOR WEB SERVICE


//FREQUENTLY USED WEBSERVICE KEY
#define DFY_WEBSERVICE_HUD_MESSAGE              @"HUDMessage"
#define DFY_WEBSERVICE_URL_KEY                  @"url"
#define DFY_WEBSERVICE_DATA_KEY                 @"values"
#define DFY_WEBSERVICE_SID                      @"sid"
#define DFY_WEBSERVICE_USER_ID_KEY              @"user_id"
#define DFY_WEBSERVICE_TYPE                     @"type"
#define DFY_WEBSERVICE_STATUSCODE               @"statusCode"

#define DFY_DB_SEQUENCE_QUEUE                    @"com.Myfinny.apps.ios.finny"

#endif
