/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

// Thanks to Emanuele Vulcano, Kevin Ballard/Eridius, Ryandjohnson, Matt Brown, etc.

#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "UIDevice+Hardware.h"

@implementation UIDevice (Hardware)
/*
 Platforms
 
 iFPGA ->        ??

 iPhone1,1 ->    iPhone 1G, M68
 iPhone1,2 ->    iPhone 3G, N82
 iPhone2,1 ->    iPhone 3GS, N88
 iPhone3,1 ->    iPhone 4/AT&T, N89
 iPhone3,2 ->    iPhone 4/Other Carrier?, ??
 iPhone3,3 ->    iPhone 4/Verizon, TBD
 iPhone4,1 ->    (iPhone 4S/GSM), TBD
 iPhone4,2 ->    (iPhone 4S/CDMA), TBD
 iPhone4,3 ->    (iPhone 4S/???)
 iPhone5,1 ->    iPhone 5, lightning
 iPhone5,1 ->    iPhone 5, lightning
 iPhone5,1 ->    iPhone 5, lightning

 iPod1,1   ->    iPod touch 1G, N45
 iPod2,1   ->    iPod touch 2G, N72
 iPod2,2   ->    Unknown, ??
 iPod3,1   ->    iPod touch 3G, N18
 iPod4,1   ->    iPod touch 4G, N80
 iPod5,1   ->    iPod touch 5G, lightning
 
 // Thanks NSForge
 iPad1,1   ->    iPad 1G, WiFi and 3G, K48
 iPad2,1   ->    iPad 2G, WiFi, K93
 iPad2,2   ->    iPad 2G, GSM 3G, K94
 iPad2,3   ->    iPad 2G, CDMA 3G, K95
 iPad3,1   ->    (iPad 3G, WiFi)
 iPad3,2   ->    (iPad 3G, GSM)
 iPad3,3   ->    (iPad 3G, CDMA)
 iPad4,1   ->    (iPad 4G, WiFi), lightning
 iPad4,2   ->    (iPad 4G, GSM), lightning
 iPad4,3   ->    (iPad 4G, CDMA), lightning

 AppleTV2,1 ->   AppleTV 2, K66
 AppleTV3,1 ->   AppleTV 3, ??

 i386, x86_64 -> iPhone Simulator
*/

#pragma mark sysctlbyname utils
- (NSString *)getSysInfoByName:(char *)typeSpecifier
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);
    return results;
}

- (NSString *)platform
{
    return [self getSysInfoByName:"hw.machine"];
}

// Thanks, Tom Harrington (Atomicbird)
- (NSString *)hwmodel
{
    return [self getSysInfoByName:"hw.model"];
}

#pragma mark sysctl utils
- (NSUInteger)getSysInfo:(uint)typeSpecifier
{
    size_t size = sizeof(int);
    int results;
    int mib[2] = {CTL_HW, typeSpecifier};
    sysctl(mib, 2, &results, &size, NULL, 0);
    return (NSUInteger) results;
}

- (NSUInteger)cpuFrequency
{
    return [self getSysInfo:HW_CPU_FREQ];
}

- (NSUInteger)busFrequency
{
    return [self getSysInfo:HW_BUS_FREQ];
}

- (NSUInteger)cpuCount
{
    return [self getSysInfo:HW_NCPU];
}

- (NSUInteger)totalMemory
{
    return [self getSysInfo:HW_PHYSMEM];
}

- (NSUInteger)userMemory
{
    return [self getSysInfo:HW_USERMEM];
}

- (NSUInteger)maxSocketBufferSize
{
    return [self getSysInfo:KIPC_MAXSOCKBUF];
}

#pragma mark file system -- Thanks Joachim Bean!

/*
 extern NSString *NSFileSystemSize;
 extern NSString *NSFileSystemFreeSize;
 extern NSString *NSFileSystemNodes;
 extern NSString *NSFileSystemFreeNodes;
 extern NSString *NSFileSystemNumber;
*/

- (NSNumber *)totalDiskSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:NSFileSystemSize];
}

- (NSNumber *)freeDiskSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:NSFileSystemFreeSize];
}

#pragma mark platform type and name utils
- (NSUInteger)platformType
{
    NSString *platform = [self platform];

    // The ever mysterious iFPGA
    if ([platform isEqualToString:@"iFPGA"])        return UIDeviceIFPGA;
    
    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"])    return UIDevice1GiPhone;
    if ([platform isEqualToString:@"iPhone1,2"])    return UIDevice3GiPhone;
    if ([platform hasPrefix:@"iPhone2"])            return UIDevice3GSiPhone;
    if ([platform hasPrefix:@"iPhone3"])            return UIDevice4iPhone;
    if ([platform hasPrefix:@"iPhone4"])            return UIDevice4SiPhone;
    if ([platform isEqualToString:@"iPhone5,1"])    return UIDevice5iPhone;
    if ([platform isEqualToString:@"iPhone5,2"])    return UIDevice5iPhone;
    if ([platform isEqualToString:@"iPhone5,3"])    return UIDevice5CiPhone;
    if ([platform isEqualToString:@"iPhone5,4"])    return UIDevice5CiPhone;
    if ([platform isEqualToString:@"iPhone6,1"])    return UIDevice5SiPhone;
    if ([platform isEqualToString:@"iPhone6,2"])    return UIDevice5SiPhone;
    
    // iPod
    if ([platform hasPrefix:@"iPod1"])              return UIDevice1GiPod;
    if ([platform hasPrefix:@"iPod2"])              return UIDevice2GiPod;
    if ([platform hasPrefix:@"iPod3"])              return UIDevice3GiPod;
    if ([platform hasPrefix:@"iPod4"])              return UIDevice4GiPod;
    if ([platform hasPrefix:@"iPod5"])              return UIDevice5GiPod;
    
    // iPad
    if ([platform hasPrefix:@"iPad1"])              return UIDevice1GiPad;
    if ([platform hasPrefix:@"iPad2"])              return UIDevice2GiPad;
    if ([platform hasPrefix:@"iPad3"])              return UIDevice3GiPad;
    if ([platform hasPrefix:@"iPad4"])              return UIDevice4GiPad;
    
    // Apple TV
    if ([platform hasPrefix:@"AppleTV2"])           return UIDeviceAppleTV2;
    if ([platform hasPrefix:@"AppleTV3"])           return UIDeviceAppleTV3;
    
    if ([platform hasPrefix:@"iPhone"])             return UIDeviceUnknowniPhone;
    if ([platform hasPrefix:@"iPod"])               return UIDeviceUnknowniPod;
    if ([platform hasPrefix:@"iPad"])               return UIDeviceUnknowniPad;
    if ([platform hasPrefix:@"AppleTV"])            return UIDeviceUnknownAppleTV;
    
    // Simulator thanks Jordan Breeding
    if ([platform hasSuffix:@"86"] || [platform isEqual:@"x86_64"]) {
        BOOL smallerScreen = [[UIScreen mainScreen] bounds].size.width < 768;
        return smallerScreen ? UIDeviceSimulatoriPhone : UIDeviceSimulatoriPad;
    }

    return UIDeviceUnknown;
}

- (NSString *)platformString
{
    switch ([self platformType])
    {
        case UIDevice1GiPhone:          return IPHONE_1G_NAMESTRING;
        case UIDevice3GiPhone:          return IPHONE_3G_NAMESTRING;
        case UIDevice3GSiPhone:         return IPHONE_3GS_NAMESTRING;
        case UIDevice4iPhone:           return IPHONE_4_NAMESTRING;
        case UIDevice4SiPhone:          return IPHONE_4S_NAMESTRING;
        case UIDevice5iPhone:           return IPHONE_5_NAMESTRING;
        case UIDevice5CiPhone:          return IPHONE_5C_NAMESTRING;
        case UIDevice5SiPhone:          return IPHONE_5S_NAMESTRING;
        case UIDeviceUnknowniPhone:     return IPHONE_UNKNOWN_NAMESTRING;
        
        case UIDevice1GiPod:            return IPOD_1G_NAMESTRING;
        case UIDevice2GiPod:            return IPOD_2G_NAMESTRING;
        case UIDevice3GiPod:            return IPOD_3G_NAMESTRING;
        case UIDevice4GiPod:            return IPOD_4G_NAMESTRING;
        case UIDevice5GiPod:            return IPOD_5G_NAMESTRING;
        case UIDeviceUnknowniPod:       return IPOD_UNKNOWN_NAMESTRING;
            
        case UIDevice1GiPad:            return IPAD_1G_NAMESTRING;
        case UIDevice2GiPad:            return IPAD_2G_NAMESTRING;
        case UIDevice3GiPad:            return IPAD_3G_NAMESTRING;
        case UIDevice4GiPad:            return IPAD_4G_NAMESTRING;
        case UIDeviceUnknowniPad:       return IPAD_UNKNOWN_NAMESTRING;
            
        case UIDeviceAppleTV2:          return APPLETV_2G_NAMESTRING;
        case UIDeviceAppleTV3:          return APPLETV_3G_NAMESTRING;
        case UIDeviceAppleTV4:          return APPLETV_4G_NAMESTRING;
        case UIDeviceUnknownAppleTV:    return APPLETV_UNKNOWN_NAMESTRING;
            
        case UIDeviceSimulator:         return SIMULATOR_NAMESTRING;
        case UIDeviceSimulatoriPhone:   return SIMULATOR_IPHONE_NAMESTRING;
        case UIDeviceSimulatoriPad:     return SIMULATOR_IPAD_NAMESTRING;
        case UIDeviceSimulatorAppleTV:  return SIMULATOR_APPLETV_NAMESTRING;
            
        case UIDeviceIFPGA:             return IFPGA_NAMESTRING;
            
        default:                        return IOS_FAMILY_UNKNOWN_DEVICE;
    }
}

- (BOOL)hasRetinaDisplay
{
    return ([UIScreen mainScreen].scale == 2.0f);
}

- (UIDeviceFamily)deviceFamily
{
    NSString *platform = [self platform];
    if ([platform hasPrefix:@"iPhone"]) return UIDeviceFamilyiPhone;
    if ([platform hasPrefix:@"iPod"]) return UIDeviceFamilyiPod;
    if ([platform hasPrefix:@"iPad"]) return UIDeviceFamilyiPad;
    if ([platform hasPrefix:@"AppleTV"]) return UIDeviceFamilyAppleTV;
    
    return UIDeviceFamilyUnknown;
}

- (BOOL)isiPhone4OrOlder
{
    static BOOL flag = YES;
    static BOOL isiPhone4OrOlder = NO;

    if (flag) {
        flag = NO;

        BOOL isIphone = [self deviceFamily] == UIDeviceFamilyiPhone;
        NSPredicate *iphoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"iPhone[0-3].*"];
        BOOL isThreeOrOld = [iphoneTest evaluateWithObject:[self platform]];
        isiPhone4OrOlder = isIphone && isThreeOrOld;
    }
    return isiPhone4OrOlder;
}

- (BOOL)isOriginaliPad
{
    static BOOL flag = YES;
    static BOOL isiPadOneOrOlder = NO;
    
    if (flag) {
        flag = NO;
        
        BOOL isIpad = [self deviceFamily] == UIDeviceFamilyiPad;
        NSPredicate *ipadTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"iPad[0-1].*"];
        BOOL isOneOrOld = [ipadTest evaluateWithObject:[self platform]];
        isiPadOneOrOlder = isIpad && isOneOrOld;
    }
    return isiPadOneOrOlder;
}

- (BOOL)isiPadThreeOrOlder
{
    static BOOL flag = YES;
    static BOOL isiPadThreeOrOlder = NO;
    
    if (flag) {
        flag = NO;
        
        BOOL isIpad = [self deviceFamily] == UIDeviceFamilyiPad;
        NSPredicate *ipadTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"iPad[0-3].*"];
        BOOL isThreeOrOlder = [ipadTest evaluateWithObject:[self platform]];
        isiPadThreeOrOlder = isIpad && isThreeOrOlder;
    }
    return isiPadThreeOrOlder;
}

- (BOOL)isiPhone4SOrOlder
{
    static BOOL flag = YES;
    static BOOL isiPhone4SOrOlder = NO;
    
    if (flag) {
        flag = NO;
        
        BOOL isiPhone = [self deviceFamily] == UIDeviceFamilyiPhone;
        NSPredicate *iphoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"iPhone[0-4].*"];
        BOOL is4SOrOlder = [iphoneTest evaluateWithObject:[self platform]];
        isiPhone4SOrOlder = isiPhone && is4SOrOlder;
    }
    return isiPhone4SOrOlder;
}

- (BOOL)isiPod4OrOlder
{
    static BOOL flag = YES;
    static BOOL isiPod4OrOlder = NO;
    
    if (flag) {
        flag = NO;
        
        BOOL isIpod = [self deviceFamily] == UIDeviceFamilyiPod;
        NSPredicate *ipodTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"iPod[0-4].*"];
        BOOL is4OrOlder = [ipodTest evaluateWithObject:[self platform]];
        isiPod4OrOlder = isIpod && is4OrOlder;
    }
    return isiPod4OrOlder;
}

- (BOOL)isDockableTelepresenceDevice
{
    static BOOL flag = YES;
    static BOOL isDockableTelepresenceDevice = NO;

    if (flag) {
        flag = NO;
        
        BOOL isiPod = [self deviceFamily] == UIDeviceFamilyiPod;
        BOOL isiPhone = [self deviceFamily] == UIDeviceFamilyiPhone;
        isDockableTelepresenceDevice = (isiPod && [self hasLightningConnector]) || (isiPhone && ![self isiPhone4OrOlder]);
    }
    return isDockableTelepresenceDevice;
}

- (BOOL)isTelepresenceController
{
    static BOOL flag = YES;
    static BOOL isTelepresenceController = NO;

    if (flag) {
        flag = NO;
        
        BOOL isiPad = [self deviceFamily] == UIDeviceFamilyiPad;
        isTelepresenceController = [self isDockableTelepresenceDevice] || (isiPad && ![self isOriginaliPad]);
    }

    return isTelepresenceController;
}

- (BOOL)isFastDevice
{
    static BOOL flag = YES;
    static BOOL usesRetina = NO;

    if (flag) {
        flag = NO;
        BOOL isRetinaiPad = (([self deviceFamily] == UIDeviceFamilyiPad) && [self hasRetinaDisplay]);
        BOOL isTelepresencePhoneOrPod = [self isDockableTelepresenceDevice];
        usesRetina = isRetinaiPad || isTelepresencePhoneOrPod;
    }
    return usesRetina;
}

- (BOOL)hasLightningConnector
{
    static BOOL flag = YES;
    static BOOL hasLightningConnector = NO;
    
    if (flag) {
        flag = NO;
        BOOL isiPod = [self deviceFamily] == UIDeviceFamilyiPod;
        BOOL isiPhone = [self deviceFamily] == UIDeviceFamilyiPhone;
        BOOL isiPad = [self deviceFamily] == UIDeviceFamilyiPad;
        hasLightningConnector = (isiPad && ![self isiPadThreeOrOlder]) || (isiPhone && ![self isiPhone4SOrOlder]) || (isiPod && ![self isiPod4OrOlder]);
    }
    return hasLightningConnector;
}

@end