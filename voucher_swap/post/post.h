#ifndef post_h
#define post_h

#include <stdio.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface Post : NSObject

- (bool)go;
- (void)respring;
- (bool)revert;
- (bool)restore;

@end

#endif /* post_h */
