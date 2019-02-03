#ifndef post_h
#define post_h

#include <stdio.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface Post : NSObject

- (bool)go;
- (void)reboot;
- (bool)revert;
- (bool)restore;
- (bool)respring;

@end

#endif /* post_h */
