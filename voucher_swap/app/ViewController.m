//
//  ViewController.m
//  voucher_swap
//
//  Created by Brandon Azad on 12/7/18.
//  Copyright © 2018 Brandon Azad. All rights reserved.
//

#import "ViewController.h"
#import "kernel_slide.h"
#import "voucher_swap.h"
#import "kernel_memory.h"
#import <mach/mach.h>
#include "post.h"
#include <sys/utsname.h>

@interface ViewController ()

@end

@implementation ViewController

- (bool)voucher_swap {
    vm_size_t size = 0;
    host_page_size(mach_host_self(), &size);
    if (size < 16000) {
        printf("non-16K devices are not currently supported.\n");
        return false;
    }
    voucher_swap();
    if (!MACH_PORT_VALID(kernel_task_port)) {
        printf("tfp0 is invalid?\n");
        return false;
    }
    return true;
}

- (void)failure {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error: exploit" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)go:(id)sender {
    Post *post = [[Post alloc] init];
    bool success = [self voucher_swap];
    if (success) {
	sleep(1);
        [post go];
        NSString *folderPath = @"/var/mobile/Media/Overlay/";
        NSString *carrierText = self.carrierTextField.text;
        NSArray *plistNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
        
        for (NSString *plistName in plistNames) {
            
            if (![plistName.pathExtension isEqualToString:@"plist"]) {
                continue;
            }
            
            NSString *plistFullPath = [folderPath stringByAppendingPathComponent:plistName];
            
            NSMutableDictionary* plistDict = [[NSDictionary dictionaryWithContentsOfFile:plistFullPath] mutableCopy];
            NSMutableArray<NSDictionary*>* images = [plistDict[@"StatusBarImages"] mutableCopy];
            for (int i = 0; i < images.count; i++)
            {
                NSMutableDictionary* sbImage = [images[i] mutableCopy];
                [sbImage setValue:carrierText forKey:@"StatusBarCarrierName"];
                images[i] = [sbImage copy];
            }
            plistDict[@"StatusBarImages"] = [images copy];
            [plistDict setValue:carrierText forKey:@"OverrideOperatorWiFiName"];
            [plistDict writeToFile:plistFullPath atomically:YES];
        }
        
        [post reboot];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfuly changed carrier name to %@", self.carrierTextField.text] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else {
        [self failure];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.carrierTextField.delegate = self;
}

- (IBAction)gotRevert:(id)sender {
    Post *post = [[Post alloc] init];
    bool success = [self voucher_swap];
    if (success) {
        sleep(1);
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChanger12/"]) {
            [post revert];
            [post reboot];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfully changed carrier name again."] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed." message:[NSString stringWithFormat:@"You have never changed carrier name before. press Apply instead of this."] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self failure];
    }
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)creditClicked:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Credits" message:[NSString stringWithFormat:@"voucher_swap by bazad\nfork by alticha\nCarrierChanger12 by PeterDev\nSpecial Thanks to Muirey, Luis E,\nWei-Jin Tzeng and Code4iOS"] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
