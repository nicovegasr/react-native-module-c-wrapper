#import "CaesarModuleProvider.h"

#import <ReactCommon/CallInvoker.h>
#import <ReactCommon/TurboModule.h>

#import "CaesarTurboModule.h"

@implementation CaesarModuleProvider

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::CaesarTurboModule>(params.jsInvoker);
}

@end
