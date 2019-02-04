//
//  ConfirmViewController.m
//  voucher_swap
//
//  Created by Soongyu Kwon on 04/02/2019.
//  Copyright © 2019 Brandon Azad. All rights reserved.
//

#import "ConfirmViewController.h"

@interface ConfirmViewController ()

@end

@implementation ConfirmViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)restoreBackup:(id)sender {
    Post *post = [[Post alloc] init];
    static int progress = 0;
    if (progress == 2) {
        [post reboot];
        return;
    }
    if (progress == 1) {
        return;
    }
    progress++;
    bool success = [self voucher_swap];
    if (success) {
        sleep(1);
        [post restore];
        [sender setTitle:@"Reboot" forState:UIControlStateNormal];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChangerBackup/"]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"success" message:[NSString stringWithFormat:@"Successfully restored with backup. click reboot"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"failed" message:[NSString stringWithFormat:@"Cannot find backup folder. click reboot"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self failure];
    }
    progress++;
}

@end
