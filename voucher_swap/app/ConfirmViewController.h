//
//  ConfirmViewController.h
//  voucher_swap
//
//  Created by Soongyu Kwon on 04/02/2019.
//  Copyright © 2019 PeterDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "kernel_slide.h"
#import "voucher_swap.h"
#import "kernel_memory.h"
#import <mach/mach.h>

#include "ViewController.h"
#include "../post/post.h"
#include <sys/utsname.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConfirmViewController : UIViewController
- (IBAction)restoreBackup:(id)sender;
- (IBAction)dismissView:(id)sender;

@end

NS_ASSUME_NONNULL_END
