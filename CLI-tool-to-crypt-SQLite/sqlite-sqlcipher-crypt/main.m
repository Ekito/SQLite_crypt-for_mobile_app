//
//  main.m
//  sqlite-sqlcipher-crypt
//
//  Created by Guillaume Cerquant on 18/03/14.
//  Copyright (c) 2014 ekito. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FMDatabase.h"


#define ConsoleLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


enum error_status_code {
    invalidUsage = 0,
    databaseDoesNotExistsAtPath,
    databaseFilePathCantBeADirectory,
    databaseCouldNotBeOpened,
    databaseCouldNotBeQueried,
    encryptionOperationFailed,
    cryptedDatabaseCouldNotBeOpened,
    cryptDatabaseIsStillPlain,
    cryptedDatabaseCouldNotBeQueried,
    moveEncryptedDatabseAndOwerwritePlainDatabseOperationFailed
    
};


@interface DatabaseCrypter : NSObject


/**
 * Will directly exist in case of an error
 * Status code value is defined in error_status_code enum
 */
+ (void) cryptDatabaseAtFilePath:(NSString *) databaseFilePath withSecretKey:(NSString *) secretKey;

@end


@interface DatabaseCrypter ()

@property (strong) NSString *databaseFilePath;
@property (strong) NSString *secretKey;
@property (strong) FMDatabase *fmDatabase;




@end




@implementation DatabaseCrypter


+ (void) cryptDatabaseAtFilePath:(NSString *) databaseFilePath withSecretKey:(NSString *) secretKey {
    DatabaseCrypter *databaseCrypter = [DatabaseCrypter new];
    
    databaseCrypter.databaseFilePath = databaseFilePath;
    databaseCrypter.secretKey = secretKey;
    
    [databaseCrypter doesDatabaseAtFilePathExists:databaseFilePath];
    [databaseCrypter openDatabaseAtFilePathAndCheckAQueryOperation:databaseFilePath];
    
    NSString *cryptedDatabaseTempFilePath = [databaseCrypter cryptDatabase];
    
    [databaseCrypter closePlainDatabaseConnection];

    [databaseCrypter verifyDatabaseIsNowCrypted:cryptedDatabaseTempFilePath];
    

    [databaseCrypter overwritePlainDatabaseWithEncryptedVersion:cryptedDatabaseTempFilePath];
    
    ConsoleLog(@"SUCCESS: Encryption succeeded.\nOriginal database file replaced with crypted version.");

}

- (void) doesDatabaseAtFilePathExists:(NSString *) databaseFilePath {
    BOOL isDirectory;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:databaseFilePath isDirectory:&isDirectory]) {
        ConsoleLog(@"Database file does not exists at %@\nPlease note: relative paths are not handled yet", databaseFilePath);
        exit(databaseDoesNotExistsAtPath);
    } else if (isDirectory) {
        ConsoleLog(@"Database at path '%@' should not be a directory", databaseFilePath);
        exit(databaseFilePathCantBeADirectory);
    }
}


- (void) closePlainDatabaseConnection {
    [self.fmDatabase close];
}

- (void) openDatabaseAtFilePathAndCheckAQueryOperation:(NSString *) databaseFilePath {
    
    self.fmDatabase = [FMDatabase databaseWithPath:databaseFilePath];
    
    if (! [self.fmDatabase open]) {
        ConsoleLog(@"Could not open the database at %@", databaseFilePath);
        self.fmDatabase = nil;
        exit(databaseCouldNotBeOpened);
    }
    
    if (! [self.fmDatabase goodConnection]) {
        ConsoleLog(@"Could not perform a query on the database ; maybe you are trying to encryt an already encryted database?\nAborting.");
        exit(databaseCouldNotBeQueried);
    }
}




- (NSString *)cryptDatabase
{
    NSString *temporaryFilePathForEncryptedDatabase = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    
//    ConsoleLog(@"Database temp file %@", temporaryFilePathForEncryptedDatabase);

    
    NSString *query = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS encrypted KEY '%@';",temporaryFilePathForEncryptedDatabase, self.secretKey];
    FMResultSet *resultsSet =  [self.fmDatabase executeQuery:query];

    if (! resultsSet) {
        ConsoleLog(@"Failed to encrypt database (ATTACH failed)");
        
        exit(encryptionOperationFailed);
    } else {
        while ([resultsSet next]) { }

    }

    resultsSet = [self.fmDatabase executeQuery:@"SELECT sqlcipher_export('encrypted');"];
    if (! resultsSet) {
        ConsoleLog(@"Failed to encrypt database (SELECT failed)");
        
        exit(encryptionOperationFailed);
    } else {
        while ([resultsSet next]) { }
        
    }

    resultsSet = [self.fmDatabase executeQuery:@"DETACH DATABASE encrypted;"];
    if (! resultsSet) {
        ConsoleLog(@"Failed to encrypt database (DETACH failed)");
        exit(encryptionOperationFailed);
    } else {
        while ([resultsSet next]) { }
    }

    ConsoleLog(@"Crypted");
    
    return temporaryFilePathForEncryptedDatabase;
}

- (void) verifyDatabaseIsNowCrypted:(NSString *) encryptedDatabaseFilePath {
    FMDatabase *encryptedDatabase = [FMDatabase databaseWithPath:encryptedDatabaseFilePath];
    
    if (! [encryptedDatabase open]) {
        ConsoleLog(@"Could not open the encrypted database at path %@", encryptedDatabaseFilePath);
        encryptedDatabase = nil;
        exit(cryptedDatabaseCouldNotBeOpened);
    }
    
    ConsoleLog(@"Testing encryption ; ignore 3 following errors  'DB Error', 'DB Query' et 'DB Path'");
    if ([encryptedDatabase goodConnection]) {
        ConsoleLog(@"Could perform a query on the database without passing in the key ; looks like the encryption was not performed?\nAborting.");
        exit(cryptDatabaseIsStillPlain);
    }
    // previous operation closed the database:
    encryptedDatabase = [FMDatabase databaseWithPath:encryptedDatabaseFilePath];

    [encryptedDatabase open];


     

    [encryptedDatabase setKey:self.secretKey];

    if (! [encryptedDatabase goodConnection]) {
        ConsoleLog(@"Could not perform a query on the database using the secret key ; something went wrong\nAborting.");
        exit(cryptedDatabaseCouldNotBeQueried);
    }
}


- (void) overwritePlainDatabaseWithEncryptedVersion:(NSString *) encryptedDatabaseFilePath {
    
    [NSFileManager defaultManager].delegate = self;
    NSError *error;
    
    if (! [[NSFileManager defaultManager] moveItemAtPath:encryptedDatabaseFilePath toPath:self.databaseFilePath error:& error]) {
        ConsoleLog(@"Overwriting plain database with encrypted version failed. Error: %@", error);
        
        exit(moveEncryptedDatabseAndOwerwritePlainDatabseOperationFailed);
    }
}


#pragma mark -
#pragma mark NSFileManager delegate
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteFileExistsError) {
        return YES;
    }

    return NO;
}


@end


int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        
        if (arguments.count != 3) {
            ConsoleLog(@"Help: ");
            exit(invalidUsage);
        }
        
        NSString *databaseFilePath = arguments[1];
        NSString *secretKey = arguments[2];
        
//        NSLog(@"File: %@\nSecret: %@\n", databaseFilePath, secretKey);
        
        [DatabaseCrypter cryptDatabaseAtFilePath:databaseFilePath withSecretKey:secretKey];
        
    }
    return 0;
}

