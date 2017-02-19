//
//  main.m
//  no-app
//
//  Created by Jan-Eric Duden on 19/02/2017.
//  Copyright © 2017 Jan-Eric Duden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include <JavaScriptCore/JavaScriptCore.h>
#include <NativeScript/NativeScript.h>
#include <TNSExceptionHandler.h>

#if DEBUG
#include <TNSDebugging.h>
#endif

int main(int argc, char * argv[]) {
    @autoreleasepool {
        extern char startOfMetadataSection __asm(
                                                 "section$start$__DATA$__TNSMetadata");
        [TNSRuntime initializeMetadata:&startOfMetadataSection];
        
        NSString *applicationPath;
        if (getenv("TNSApplicationPath")) {
            applicationPath = @(getenv("TNSApplicationPath"));
        } else {
            applicationPath = [NSBundle mainBundle].bundlePath;
        }
        
        TNSRuntime *runtime = [[TNSRuntime alloc] initWithApplicationPath:applicationPath];
        [runtime scheduleInRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSRunLoopCommonModes];
        
#if DEBUG
        [TNSRuntimeInspector setLogsToSystemConsole:YES];
        
        char* fake_argv[]={"","--nativescript-debug-start"};
        TNSEnableRemoteInspector(2, fake_argv, runtime);
#endif
        
        TNSInstallExceptionHandler();
        
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), (uint64_t)(0.3 * NSEC_PER_SEC), (uint64_t)(0.1 * NSEC_PER_SEC));
        
        dispatch_source_set_event_handler(timer, ^{
            if( inspector != nil ) {
                dispatch_source_cancel(timer);
                
                [runtime executeModule:@"./"];
                JSValueRef exception;
                JSStringRef code = JSStringCreateWithUTF8CString("debugger;console.log(\"Hello inline\");");
                JSEvaluateScript(runtime.globalContext,code, NULL, NULL, 0, &exception);
            }
            else {
                NSLog(@"Waiting for debugger..");
            }
        });
        dispatch_resume(timer);
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
