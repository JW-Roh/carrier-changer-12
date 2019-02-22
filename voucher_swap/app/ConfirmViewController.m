//
//  ConfirmViewController.m
//  voucher_swap
//
//  Created by Soongyu Kwon on 04/02/2019.
//  Copyright © 2019 PeterDev. All rights reserved.
//

#import "ConfirmViewController.h"

@interface ConfirmViewController () {
    BOOL is4Kdevice;
}

@end

@implementation ConfirmViewController

- (bool)voucher_swap {
    vm_size_t size = 0;
    host_page_size(mach_host_self(), &size);
    if (size < 16000) {
        printf("4K device\nExploit selected: v3ntex.\n");
        is4Kdevice = TRUE;
        return false;
    }
    voucher_swap();
    if (!MACH_PORT_VALID(kernel_task_port)) {
        printf("tfp0 is invalid?\n");
        is4Kdevice = FALSE;
        return false;
    }
    printf("16K device\nExploit selected: voucher_swap.\n");
    is4Kdevice = FALSE;
    return true;
}

- (void)failure {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error: exploit" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)v3ntexFailure {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error: exploit. Reboot and retry." message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)restoreBackup:(id)sender {
    Post *post = [[Post alloc] init];
    ViewController *vc = [[ViewController alloc] init];
    bool success = [self voucher_swap];
    if (success) {
        sleep(1);
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChangerBackup/"]) {
            [post restore];
            [post reboot];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfully restored with backup."] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed." message:[NSString stringWithFormat:@"Cannot find backup folder."] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if (is4Kdevice) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChangerBackup/"]) {
            [vc dov3ntex];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isSucceed"] == TRUE) {
                printf("v3ntex: success\n");
                [post restoreBackup];
                [post v3ntexApply];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfully restored with backup. Reboot your device."] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                printf("v3ntex: failed\n");
                [self v3ntexFailure];
            }
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed." message:[NSString stringWithFormat:@"Cannot find backup folder."] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self failure];
    }
}

- (IBAction)dismissView:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end
