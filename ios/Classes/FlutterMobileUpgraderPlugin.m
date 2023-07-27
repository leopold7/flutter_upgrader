#import "FlutterMobileUpgraderPlugin.h"
#if __has_include(<flutter_mobile_upgrader/flutter_mobile_upgrader-Swift.h>)
#import <flutter_mobile_upgrader/flutter_mobile_upgrader-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_mobile_upgrader-Swift.h"
#endif

@implementation FlutterMobileUpgraderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMobileUpgraderPlugin registerWithRegistrar:registrar];
}
@end
