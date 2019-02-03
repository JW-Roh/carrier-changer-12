//
//  ViewController.h
//  voucher_swap
//
//  Created by Brandon Azad on 12/7/18.
//  Copyright © 2018 Brandon Azad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate>
- (IBAction)respringDevice:(id)sender;
- (IBAction)gotRevert:(id)sender;
- (IBAction)restoreBackup:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *carrierTextField;
@end
