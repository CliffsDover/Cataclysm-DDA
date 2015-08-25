//
//  ViewController.m
//  Cataclysm-Dark-Days-Ahead
//
//  Created by MyStaub on 2015/8/25.
//  Copyright (c) 2015年 Dancing Bottle. All rights reserved.
//

#import "ViewController.h"
#include "SDL_main.h"


#ifdef __cplusplus
extern "C" {
#endif
    int main_cdda(int argc, char *argv[]/*, ViewController* viewController*/ );
    //int main(int argc, char *argv[] );
#ifdef __cplusplus
}
#endif

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString* bundlePath = [[[NSBundle mainBundle] bundlePath ] stringByAppendingString:@"/"];
    NSString* basePath = @"--basepath";
    NSString* userDir = @"--userdir";
    
    NSString* dataPath = [bundlePath stringByAppendingString:@"data/"];
    
    char bundlePathBuffer[256];
    char dataPathBuffer[256];
    char* param[7] = { 0 };
    
    memcpy( bundlePathBuffer, [ bundlePath cStringUsingEncoding:NSASCIIStringEncoding ], sizeof(char) * strlen( [ bundlePath cStringUsingEncoding:NSASCIIStringEncoding ] ) );
    memcpy( dataPathBuffer, [ dataPath cStringUsingEncoding:NSASCIIStringEncoding ], sizeof(char) * strlen( [ dataPath cStringUsingEncoding:NSASCIIStringEncoding ] ) );
    
    param[0] = "cataclysm";
    param[1] = "--basepath";
    param[2] = bundlePathBuffer;
    param[3] = "--userdir";
    param[4] = bundlePathBuffer;
    param[5] = "--datadir";
    param[6] = dataPathBuffer;
    
    
    main_cdda( 7, param/*, self*/ );
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
