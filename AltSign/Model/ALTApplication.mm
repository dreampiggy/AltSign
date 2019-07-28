//
//  ALTApplication.m
//  AltSign
//
//  Created by Riley Testut on 6/24/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

#import "ALTApplication.h"

#include "ldid.hpp"

@implementation ALTApplication
@synthesize entitlements = _entitlements;

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (self)
    {
        NSBundle *bundle = [NSBundle bundleWithURL:fileURL];
        if (bundle == nil)
        {
            return nil;
        }
        
        // Load info dictionary directly from disk, since NSBundle caches values
        // that might not reflect the updated values on disk (such as bundle identifier).
        NSURL *infoPlistURL = [bundle.bundleURL URLByAppendingPathComponent:@"Info.plist"];
        NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfURL:infoPlistURL];
        if (infoDictionary == nil)
        {
            return nil;
        }
        
        NSString *name = infoDictionary[(NSString *)kCFBundleNameKey];
        NSString *bundleIdentifier = infoDictionary[(NSString *)kCFBundleIdentifierKey];
        NSString *minimumVersionString = infoDictionary[@"MinimumOSVersion"];
        
        if (name == nil || bundleIdentifier == nil || minimumVersionString == nil)
        {
            return nil;
        }
        
        NSArray *versionComponents = [minimumVersionString componentsSeparatedByString:@"."];
        
        NSInteger majorVersion = [versionComponents.firstObject integerValue];
        NSInteger minorVersion = (versionComponents.count > 1) ? [versionComponents[1] integerValue] : 0;
        NSInteger patchVersion = (versionComponents.count > 2) ? [versionComponents[2] integerValue] : 0;
        
        NSOperatingSystemVersion minimumVersion;
        minimumVersion.majorVersion = majorVersion;
        minimumVersion.minorVersion = minorVersion;
        minimumVersion.patchVersion = patchVersion;
        
        _fileURL = [fileURL copy];
        _name = [name copy];
        _bundleIdentifier = [bundleIdentifier copy];
        _minimumiOSVersion = minimumVersion;
    }
    
    return self;
}

- (NSDictionary<ALTEntitlement,id> *)entitlements
{
    if (_entitlements == nil)
    {
        NSDictionary<NSString *, id> *appEntitlements = @{};
        
        std::string rawEntitlements = ldid::Entitlements(self.fileURL.fileSystemRepresentation);
        if (rawEntitlements.size() != 0)
        {
            NSData *entitlementsData = [NSData dataWithBytes:rawEntitlements.c_str() length:rawEntitlements.size()];
            
            NSError *error = nil;
            NSDictionary *entitlements = [NSPropertyListSerialization propertyListWithData:entitlementsData options:0 format:nil error:&error];
            
            if (entitlements != nil)
            {
                appEntitlements = entitlements;
            }
            else
            {
                NSLog(@"Error parsing entitlements: %@", error);
            }
        }
        
        _entitlements = appEntitlements;
    }
    
    return _entitlements;
}
}

@end
