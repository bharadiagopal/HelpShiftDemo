//
//  DatabaseManager.m
//  Finny
//
//  Created by Chandan Kumar on 01/11/2016.
//
//

#import "DatabaseManager.h"
#import "Config.h"
#import "unistd.h"

@interface DatabaseManager ()

@end

@implementation DatabaseManager
#pragma mark -
#pragma mark Creating Database if that not exists

#pragma mark Singleton Methods
static DatabaseManager *dbHandler = nil;

/*
 * Create singleton object of DatabaseManager
 */
+ (DatabaseManager *) sharedDatabaseManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbHandler = [[self alloc] init];
        
        //Set date formate for DATETIME coloumn
    });
    return dbHandler;
}

/*==================================================================
 METHOD FOR INITIALISING DATABASE MANAGER OBJECT
 ==================================================================*/
- (instancetype)init
{
    self = [super init];
    if (self) {
        _dateFormat = (NSDateFormatter*)[DatabaseManager storeableDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return self;
}

/*==================================================================
 METHOD FOR GET PATH OF DATABASE
 ==================================================================*/
-(NSString *) dataFilePath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
    
	return [documentsDirectory stringByAppendingPathComponent:kFYDatabaseName];
}

/*==================================================================
 METHOD FOR CHECK AND CREATE DATABASE
 ==================================================================*/
+(void) checkAndCreateDatabase{
	// check if the SQL database has already been saved to the users phone, if not then copy it over
	BOOL success;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	// Create a FileManager object, we will use this to check the status
	// of the database and to copy it over if required
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// Check if the database has already been created in the users filesystem
	success = [fileManager fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:kFYDatabaseName]];
	
	// If the database already exists then return without doing anything
	if(success)
    {
        if (kFYDebugLevel2)
            NSLog(@"%@",[documentsDirectory stringByAppendingPathComponent:kFYDatabaseName]);
        
		return;
    }
	else
		NSLog(@"Not Existed");
	
	// If not then proceed to copy the database from the application to the users filesystem
	
	// Get the path to the database in the application package
	NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kFYDatabaseName];
	
    if (kFYDebugLevel2){
        // Copy the database from the package to the users filesystem
        NSLog(@"databasePathFromApp %@",databasePathFromApp);
        NSLog(@"PATH %@",[documentsDirectory stringByAppendingPathComponent:kFYDatabaseName]);
    }
    
	[fileManager copyItemAtPath:databasePathFromApp toPath:[documentsDirectory stringByAppendingPathComponent:kFYDatabaseName] error:nil];
}

/*==================================================================
 METHOD FOR INSERTING DATA IN DATABASE
 ==================================================================*/
-(BOOL)executeQuery:(NSString *)query
{
	sqlite3_stmt *statement;
    
    int rc;

    char* errorMessage;
    
    sqlite3_exec(_db, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);

    if(sqlite3_open([[self dataFilePath] UTF8String], &_db) == SQLITE_OK)
	{
        rc = sqlite3_prepare_v2(_db, [query UTF8String], -1, &statement, NULL);
        rc = sqlite3_exec(_db, [query UTF8String], NULL, NULL, &errorMessage);
        
		if (rc == SQLITE_OK)
		{
            /* Call sqlite3_step() to run the virtual machine. Since the SQL being
             ** executed is not a SELECT statement, we assume no data will be returned.
             */
            rc      = sqlite3_step(statement);
            
            if (SQLITE_ERROR == rc) {
                if (kFYDebugError) {
                    NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_ERROR", rc, sqlite3_errmsg(_db));
                    NSLog(@"DB Query: %@", query);
                }
            }
            else if (SQLITE_MISUSE == rc) {
                // uh oh.
                if (kFYDebugError) {
                    NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_MISUSE", rc, sqlite3_errmsg(_db));
                    NSLog(@"DB Query: %@", query);
                }
            }
            else {
                // wtf?
                if (kFYDebugLevel2) {
                    NSLog(@"DB Query: %@", query);
                    NSLog(@"sqlite3_step (%d: %s)", rc, sqlite3_errmsg(_db));
                }
            }
		}
		else
		{
            if (SQLITE_MISUSE == rc) {
                // uh oh.
                if (kFYDebugError) {
                    NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_MISUSE", rc, sqlite3_errmsg(_db));
                    NSLog(@"QUERY Statement Not Compiled: %@", query);
                }
            }
		}
        sqlite3_finalize(statement);
		sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
		sqlite3_close(_db);
        
        return true;
	}
	else
	{
        if (errorMessage && kFYDebugError) {
            NSLog(@"Data not Opened");
            NSLog(@"Error inserting batch: %s", errorMessage);
        }
        
        sqlite3_free(errorMessage);
	}
    
     return (rc == SQLITE_OK);
}

/*==================================================================
 METHOD FOR INSERTING DATA IN DATABASE WITH ARRAY ARGUMENTS
 ==================================================================*/
- (void)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeQuery:sql withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

/*==================================================================
 METHOD FOR INSERTING DATA IN DATABASE WITH DICTIONARY ARGUMENTS
 ==================================================================*/
- (void)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeQuery:sql withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

/*==================================================================
 METHOD FOR INSERTING DATA IN DATABASE WITH AVAILABLE ARGUMENTS LIST
 ==================================================================*/
-(void)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args
{
    char* errorMessage;
    sqlite3_exec(_db, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    
    if(sqlite3_open([[self dataFilePath] UTF8String], &_db) == SQLITE_OK)
    {
        sqlite3_stmt *statement;

        if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK)
        {
            id obj;
            int idx = 0;
            int queryCount = sqlite3_bind_parameter_count(statement); // pointed out by Keys
            
            // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
            if (dictionaryArgs)
            {
                for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
                    
                    // Prefix the key with a colon.
                    NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
                    
                    if (kFYDebugLevel2)
                        NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
                    
                    // Get the index for the parameter name.
                    int namedIdx = sqlite3_bind_parameter_index(statement, [parameterName UTF8String]);
                    
                    
                    if (namedIdx > 0) {
                        // Standard binding from here.
                        [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:statement];
                        // increment the binding count, so our check below works out
                        idx++;
                    }
                    else {
                        if (kFYDebugError)
                            NSLog(@"Could not find index for %@", dictionaryKey);
                    }
                }
            }
            else
            {
                while (idx < queryCount) {
                    
                    if (arrayArgs && idx < (int)[arrayArgs count])
                        obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
                    else if (args)
                        obj = va_arg(args, id);
                    else //We ran out of arguments
                        break;
                    
                    idx++;
                    
                    [self bindObject:obj toColumn:idx inStatement:statement];
                }
            }
            
            sqlite3_step(statement);
            
            if (idx != queryCount) {
                if (kFYDebugError)
                    NSLog(@"Error: the bind count is not correct for the # of variables (executeQuery)");
                
                sqlite3_finalize(statement);
                sqlite3_close(_db);
            }
        }
        else
        {
            if (kFYDebugError){
                NSLog(@"QUERY Statement Not Compiled: %@",sql);
                NSLog(@"could not prepare statemnt: %s\n", sqlite3_errmsg(_db) );
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
            }
        }
        sqlite3_finalize(statement);
        sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_close(_db);
    }
    else
    {
        if (kFYDebugError)
            NSLog(@"Data not Opened");
    }
}

#pragma mark Execute updates
- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeUpdate:sql error:nil withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql error:(NSError**)outErr withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args
{    
    int rc                   = 0x00;
    
    char* errorMessage;
    sqlite3_exec(_db, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);

    if(sqlite3_open([[self dataFilePath] UTF8String], &_db) == SQLITE_OK)
    {
        sqlite3_stmt *statement;
        
        rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &statement, NULL);
        
        if (rc == SQLITE_OK)
        {
            id obj;
            int idx = 0;
            int queryCount = sqlite3_bind_parameter_count(statement); // pointed out by Keys
            
            // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
            if (dictionaryArgs)
            {
                for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
                    
                    // Prefix the key with a colon.
                    NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
                    
                    if (kFYDebugLevel2)
                        NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
                    
                    // Get the index for the parameter name.
                    int namedIdx = sqlite3_bind_parameter_index(statement, [parameterName UTF8String]);
                    
                    if (namedIdx > 0) {
                        // Standard binding from here.
                        [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:statement];
                        // increment the binding count, so our check below works out
                        idx++;
                    }
                    else {
                        if (kFYDebugError)
                            NSLog(@"Could not find index for %@", dictionaryKey);
                    }
                }
            }
            else
            {
                while (idx < queryCount) {
                    
                    if (arrayArgs && idx < (int)[arrayArgs count])
                        obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
                    else if (args)
                        obj = va_arg(args, id);
                    else //We ran out of arguments
                        break;
                    
                    idx++;
                    
                    [self bindObject:obj toColumn:idx inStatement:statement];
                }
            }
            
            sqlite3_step(statement);
            
            if (idx != queryCount) {
                if (kFYDebugError)
                    NSLog(@"Error: the bind count (%d) is not correct for the # of variables in the query (%d) (%@) (executeUpdate)", idx, queryCount, sql);
                sqlite3_finalize(statement);
                sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
                sqlite3_close(_db);
                
                return NO;
            }
        }
        else
        {
            if (kFYDebugError){
                NSLog(@"QUERY Statement Not Compiled: %@",sql);
                NSLog(@"could not prepare statemnt: %s\n", sqlite3_errmsg(_db) );
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
            }
        }
        
        if (rc == SQLITE_OK) {
            // all is well, let's return.
            if (kFYDebugLevel2) {
                NSLog(@"DB Query: %@", sql);
            }
        }
        else {
            
            /* Call sqlite3_step() to run the virtual machine. Since the SQL being
             ** executed is not a SELECT statement, we assume no data will be returned.
             */
            rc      = sqlite3_step(statement);
            
            if (SQLITE_ERROR == rc) {
                if (kFYDebugError) {
                    NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_ERROR", rc, sqlite3_errmsg(_db));
                    NSLog(@"DB Query: %@", sql);
                }
            }
            else if (SQLITE_MISUSE == rc) {
                // uh oh.
                if (kFYDebugError) {
                    NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_MISUSE", rc, sqlite3_errmsg(_db));
                    NSLog(@"DB Query: %@", sql);
                }
            }
            else {
                // wtf?
                if (kFYDebugError) {
                    NSLog(@"Unknown error calling sqlite3_step (%d: %s) eu", rc, sqlite3_errmsg(_db));
                    NSLog(@"DB Query: %@", sql);
                }
            }
        }
        
        /* Finalize the virtual machine. This releases all memory and other
         ** resources allocated by the sqlite3_prepare() call above.
         */
        int closeErrorCode = sqlite3_finalize(statement);
        sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_close(_db);
        
        if (closeErrorCode != SQLITE_OK) {
            if (kFYDebugError) {
                NSLog(@"Unknown error finalizing or resetting statement (%d: %s)", closeErrorCode, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
        
        return (rc == SQLITE_DONE || rc == SQLITE_OK);
    }
    else
    {
        if (kFYDebugError)
            NSLog(@"Data not Opened");
    }
    
    return false;
}


-(id)retriveQuery:(NSString *)query withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs
{
    id objectValue = nil;
    
    char* errorMessage;
    sqlite3_exec(_db, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    
    if(sqlite3_open([[self dataFilePath] UTF8String], &_db) == SQLITE_OK)
    {
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(_db, [query UTF8String], -1, &statement, NULL) == SQLITE_OK)
        {
            id obj;
            int idx = 0;
            int queryCount = sqlite3_bind_parameter_count(statement); // pointed out by Keys
            
            // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
            if (dictionaryArgs)
            {
                for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
                    
                    // Prefix the key with a colon.
                    NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
                    
                    if (kFYDebugLevel2)
                        NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
                    
                    // Get the index for the parameter name.
                    int namedIdx = sqlite3_bind_parameter_index(statement, [parameterName UTF8String]);
                    
                    
                    if (namedIdx > 0) {
                        // Standard binding from here.
                        [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:statement];
                        // increment the binding count, so our check below works out
                        idx++;
                    }
                    else {
                        if (kFYDebugError)
                            NSLog(@"Could not find index for %@", dictionaryKey);
                    }
                }
            }
            else
            {
                while (idx < queryCount) {
                    
                    if (arrayArgs && idx < (int)[arrayArgs count])
                        obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
                    else //We ran out of arguments
                        break;
                    
                    idx++;
                    
                    [self bindObject:obj toColumn:idx inStatement:statement];
                }
            }
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                int columnIdx = 0;
                
                objectValue = [self objectForColumnIndex:columnIdx inStatement:statement];
            }
            
            if (idx != queryCount) {
                if (kFYDebugError)
                    NSLog(@"Error: the bind count is not correct for the # of variables (executeQuery)");
                
                sqlite3_finalize(statement);
                sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
                sqlite3_close(_db);
            }
        }
        else
        {
            if (kFYDebugError){
                NSLog(@"QUERY Statement Not Compiled: %@",query);
                NSLog(@"could not prepare statemnt: %s\n", sqlite3_errmsg(_db) );
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
            }
        }
        sqlite3_finalize(statement);
        sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_close(_db);
    }
    else
    {
        if (kFYDebugError)
            NSLog(@"Data not Opened");
    }

    /*
    NSString *fixedQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    id objectValue = nil;
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(_db, [fixedQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            int columnIdx = 0;

            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(statement, columnIdx)];
            objectValue = [self objectForColumnIndex:columnIdx inStatement:statement];
        }
        
        sqlite3_finalize(statement);
    }
    
    return objectValue;
     */
    
    return objectValue;
}

/*==================================================================
 METHOD FOR Fetching DATA FROM DATABASE
 ==================================================================*/
-(id)retriveQuery:(NSString *)query isDictionary:(BOOL)isDict
{
    char* errorMessage;
    sqlite3_exec(_db, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    if(sqlite3_open([[self dataFilePath] UTF8String], &_db) == SQLITE_OK)
    {
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(_db, [query UTF8String], -1, &statement, nil)==SQLITE_OK)
        {
            NSMutableArray *array = [[NSMutableArray alloc] init];
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSUInteger num_cols = (NSUInteger)sqlite3_data_count(statement);
                
                if (num_cols > 0) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:num_cols];
                    
                    int columnCount = sqlite3_column_count(statement);
                    
                    int columnIdx = 0;
                    for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
                        
                        NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(statement, columnIdx)];
                        id objectValue = [self objectForColumnIndex:columnIdx inStatement:statement];
                        [dict setObject:objectValue forKey:columnName];
                    }
                                        
                    if (isDict)
                    {
                        sqlite3_finalize(statement);
                        sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
                        sqlite3_close(_db);
                        
                        return dict;
                    }
                    else
                        [array addObject:dict];
                    
                }
                else {
                    NSLog(@"Warning: There seem to be no columns in this set.");
                }
            }
            
            sqlite3_finalize(statement);
            sqlite3_exec(_db, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
            sqlite3_close(_db);
            
            return array;
        }
    }
    
    return nil;
}

/*==================================================================
 METHOD FOR Fetching OBJECT FROM DATABASE
 ==================================================================*/
- (id)objectForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt {
    int columnType = sqlite3_column_type(pStmt, columnIdx);
    
    id returnValue = nil;
    
    if (columnType == SQLITE_INTEGER) {
        returnValue = [NSNumber numberWithLongLong:[self longLongIntForColumnIndex:columnIdx inStatement:pStmt]];
    }
    else if (columnType == SQLITE_FLOAT) {
        returnValue = [NSNumber numberWithDouble:[self doubleForColumnIndex:columnIdx inStatement:pStmt]];
    }
    else if (columnType == SQLITE_BLOB) {
        returnValue = [self dataForColumnIndex:columnIdx inStatement:pStmt];
    }
    else {
        //default to a string for everything else
        returnValue = [self stringForColumnIndex:columnIdx inStatement:pStmt];
    }
    
    if (returnValue == nil) {
        returnValue = [NSNull null];
    }
    
    return returnValue;
}

- (BOOL)boolForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt{
    return ([self intForColumnIndex:columnIdx inStatement:pStmt] != 0);
}
- (int)intForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt{
    return sqlite3_column_int(pStmt, columnIdx);
}
/*==================================================================
 METHOD FOR Fetching Long Long Int FROM DATABASE
 ==================================================================*/
- (long long int)longLongIntForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt {
    return sqlite3_column_int64(pStmt, columnIdx);
}
/*==================================================================
 METHOD FOR Fetching Double FROM DATABASE
 ==================================================================*/
- (double)doubleForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt{
    return sqlite3_column_double(pStmt, columnIdx);
}

/*==================================================================
 METHOD FOR Fetching NSData FROM DATABASE
 ==================================================================*/
- (NSData*)dataForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt {
    
    if (sqlite3_column_type(pStmt, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *dataBuffer = sqlite3_column_blob(pStmt, columnIdx);
    int dataSize = sqlite3_column_bytes(pStmt, columnIdx);
    
    if (dataBuffer == NULL) {
        return nil;
    }
    
    return [NSData dataWithBytes:(const void *)dataBuffer length:(NSUInteger)dataSize];
}

/*==================================================================
 METHOD FOR Fetching NSString FROM DATABASE
 ==================================================================*/
- (NSString*)stringForColumnIndex:(int)columnIdx inStatement:(sqlite3_stmt*)pStmt {
    
    if (sqlite3_column_type(pStmt, columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *c = (const char *)sqlite3_column_text(pStmt, columnIdx);
    
    if (!c) {
        // null row.
        return nil;
    }
    
    return [NSString stringWithUTF8String:c];
}


#pragma mark Date routines

+ (NSDateFormatter *)storeableDateFormat:(NSString *)format {
    
    NSDateFormatter *result = [[NSDateFormatter alloc] init];
    result.dateFormat = format;
    result.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    result.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    return result;
}

- (BOOL)hasDateFormatter {
    return _dateFormat != nil;
}

- (void)setDateFormat:(NSDateFormatter *)format {
    _dateFormat = format;
}

- (NSDate *)dateFromString:(NSString *)s {
    return [_dateFormat dateFromString:s];
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [_dateFormat stringFromDate:date];
}

#pragma mark SQL manipulation

- (void)bindObject:(id)obj toColumn:(int)idx inStatement:(sqlite3_stmt*)pStmt {
    
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        sqlite3_bind_null(pStmt, idx);
    }
    
    // FIXME - someday check the return codes on these binds.
    else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            // it's an empty NSData object, aka [NSData data].
            // Don't pass a NULL pointer, or sqlite will bind a SQL null instead of a blob.
            bytes = "";
        }
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_TRANSIENT);
    }
    else if ([obj isKindOfClass:[NSDate class]]) {
        if (self.hasDateFormatter)
            sqlite3_bind_text(pStmt, idx, [[self stringFromDate:obj] UTF8String], -1, SQLITE_TRANSIENT);
        else
            sqlite3_bind_double(pStmt, idx, [obj timeIntervalSince1970]);
    }
    else if ([obj isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([obj objCType], @encode(char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj charValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        }
        else if (strcmp([obj objCType], @encode(short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        }
        else if (strcmp([obj objCType], @encode(int)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj intValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedIntValue]);
        }
        else if (strcmp([obj objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongValue]);
        }
        else if (strcmp([obj objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongLongValue]);
        }
        else if (strcmp([obj objCType], @encode(float)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        }
        else if (strcmp([obj objCType], @encode(double)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        }
        else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(pStmt, idx, ([obj boolValue] ? 1 : 0));
        }
        else {
            sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_TRANSIENT);
        }
    }
    else {
        sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_TRANSIENT);
    }
}

- (void)extractSQL:(NSString *)sql argumentsList:(va_list)args intoString:(NSMutableString *)cleanedSQL arguments:(NSMutableArray *)arguments {
    
    NSUInteger length = [sql length];
    unichar last = '\0';
    for (NSUInteger i = 0; i < length; ++i) {
        id arg = nil;
        unichar current = [sql characterAtIndex:i];
        unichar add = current;
        if (last == '%') {
            switch (current) {
                case '@':
                    arg = va_arg(args, id);
                    break;
                case 'c':
                    // warning: second argument to 'va_arg' is of promotable type 'char'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                    arg = [NSString stringWithFormat:@"%c", va_arg(args, int)];
                    break;
                case 's':
                    arg = [NSString stringWithUTF8String:va_arg(args, char*)];
                    break;
                case 'd':
                case 'D':
                case 'i':
                    arg = [NSNumber numberWithInt:va_arg(args, int)];
                    break;
                case 'u':
                case 'U':
                    arg = [NSNumber numberWithUnsignedInt:va_arg(args, unsigned int)];
                    break;
                case 'h':
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        //  warning: second argument to 'va_arg' is of promotable type 'short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        arg = [NSNumber numberWithShort:(short)(va_arg(args, int))];
                    }
                    else if (i < length && [sql characterAtIndex:i] == 'u') {
                        // warning: second argument to 'va_arg' is of promotable type 'unsigned short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        arg = [NSNumber numberWithUnsignedShort:(unsigned short)(va_arg(args, uint))];
                    }
                    else {
                        i--;
                    }
                    break;
                case 'q':
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        arg = [NSNumber numberWithLongLong:va_arg(args, long long)];
                    }
                    else if (i < length && [sql characterAtIndex:i] == 'u') {
                        arg = [NSNumber numberWithUnsignedLongLong:va_arg(args, unsigned long long)];
                    }
                    else {
                        i--;
                    }
                    break;
                case 'f':
                    arg = [NSNumber numberWithDouble:va_arg(args, double)];
                    break;
                case 'g':
                    // warning: second argument to 'va_arg' is of promotable type 'float'; this va_arg has undefined behavior because arguments will be promoted to 'double'
                    arg = [NSNumber numberWithFloat:(float)(va_arg(args, double))];
                    break;
                case 'l':
                    i++;
                    if (i < length) {
                        unichar next = [sql characterAtIndex:i];
                        if (next == 'l') {
                            i++;
                            if (i < length && [sql characterAtIndex:i] == 'd') {
                                //%lld
                                arg = [NSNumber numberWithLongLong:va_arg(args, long long)];
                            }
                            else if (i < length && [sql characterAtIndex:i] == 'u') {
                                //%llu
                                arg = [NSNumber numberWithUnsignedLongLong:va_arg(args, unsigned long long)];
                            }
                            else {
                                i--;
                            }
                        }
                        else if (next == 'd') {
                            //%ld
                            arg = [NSNumber numberWithLong:va_arg(args, long)];
                        }
                        else if (next == 'u') {
                            //%lu
                            arg = [NSNumber numberWithUnsignedLong:va_arg(args, unsigned long)];
                        }
                        else {
                            i--;
                        }
                    }
                    else {
                        i--;
                    }
                    break;
                default:
                    // something else that we can't interpret. just pass it on through like normal
                    break;
            }
        }
        else if (current == '%') {
            // percent sign; skip this character
            add = '\0';
        }
        
        if (arg != nil) {
            [cleanedSQL appendString:@"?"];
            [arguments addObject:arg];
        }
        else if (add == (unichar)'@' && last == (unichar) '%') {
            [cleanedSQL appendFormat:@"NULL"];
        }
        else if (add != '\0') {
            [cleanedSQL appendFormat:@"%C", add];
        }
        last = current;
    }
}

#pragma mark Error routines

- (NSString*)lastErrorMessage {
    return [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
}

- (BOOL)hadError {
    int lastErrCode = [self lastErrorCode];
    
    return (lastErrCode > SQLITE_OK && lastErrCode < SQLITE_ROW);
}

- (int)lastErrorCode {
    return sqlite3_errcode(_db);
}

- (NSError*)errorWithMessage:(NSString*)message {
    NSDictionary* errorMessage = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"Finnyapp" code:sqlite3_errcode(_db) userInfo:errorMessage];
}

- (NSError*)lastError {
    return [self errorWithMessage:[self lastErrorMessage]];
}

@end
