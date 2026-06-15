#import "CaesarRn.h"

// Header autogenerado por Xcode a partir de los `@objc public` del shim Swift
// (CaesarRnSwiftBridge.swift). El nombre depende del módulo y del linkage de
// CocoaPods: framework con use_frameworks! usa <CaesarRn/CaesarRn-Swift.h>;
// static lib (default) usa "CaesarRn-Swift.h".
#if __has_include(<CaesarRn/CaesarRn-Swift.h>)
#import <CaesarRn/CaesarRn-Swift.h>
#else
#import "CaesarRn-Swift.h"
#endif

@implementation CaesarRn

- (NSString *)cipher:(NSString *)text shift:(double)shift {
    return [CaesarRnSwiftBridge cipher:text shift:(int32_t)shift];
}

- (NSString *)decipher:(NSString *)text shift:(double)shift {
    return [CaesarRnSwiftBridge decipher:text shift:(int32_t)shift];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeCaesarRnSpecJSI>(params);
}

+ (NSString *)moduleName
{
  return @"CaesarRn";
}

@end
