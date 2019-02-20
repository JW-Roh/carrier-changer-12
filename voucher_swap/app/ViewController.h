//
//  ViewController.h
//  voucher_swap
//
//  Created by Brandon Azad on 12/7/18.
//  Copyright © 2018 Brandon Azad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "kernel_slide.h"
#import "voucher_swap.h"
#import "kernel_memory.h"
#import <mach/mach.h>

#include "../post/post.h"
#include <sys/utsname.h>

#include "../v3ntex/offsets.h"
#include "../v3ntex/exploit.h"


@interface ViewController : UIViewController <UITextFieldDelegate>
- (IBAction)gotRevert:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *carrierTextField;
- (IBAction)creditClicked:(id)sender;

@end
