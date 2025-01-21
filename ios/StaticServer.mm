#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(StaticServer, NSObject)

RCT_EXTERN_METHOD(start: (NSString *)port root: (NSString *)root localOnly: (BOOL)localOnly keepAlive: (BOOL)keepAlive resolver: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(stop)
RCT_EXTERN_METHOD(origin:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(isRunning:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

@end
