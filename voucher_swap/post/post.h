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
- (void)letsChange;
- (void)changeItAgain;
- (void)restoreBackup;
- (void)v3ntexApply;

@end

#endif /* post_h */
