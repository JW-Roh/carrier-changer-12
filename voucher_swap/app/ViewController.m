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
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"failed" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)go:(id)sender {
    Post *post = [[Post alloc] init];
    static int progress = 0;
    if (progress == 2) {
        [post respring];
        return;
    }
    if (progress == 1) {
	return;
    }
    progress++;
    bool success = [self voucher_swap];
    if (success) {
	sleep(1);
        [post go];
        [sender setTitle:@"respring" forState:UIControlStateNormal];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"success" message:[NSString stringWithFormat:@"Successfuly got root\nFiles saved at /var/mobile/Media/Overlay/\nkeep this app open and respring after modify the files."] preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self failure];
    }
    progress++;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)gotRevert:(id)sender {
    Post *post = [[Post alloc] init];
    static int progress = 0;
    if (progress == 2) {
        [post respring];
        return;
    }
    if (progress == 1) {
        return;
    }
    progress++;
    bool success = [self voucher_swap];
    if (success) {
        sleep(1);
        [post revert];
        [sender setTitle:@"respring" forState:UIControlStateNormal];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChanger12/"]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"success" message:[NSString stringWithFormat:@"Successfully changed Carrier Name again. click respring"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"failed" message:[NSString stringWithFormat:@"You have never changed carrier name before. press go instead of this. click respring"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self failure];
    }
    progress++;
}

- (IBAction)restoreBackup:(id)sender {
    Post *post = [[Post alloc] init];
    static int progress = 0;
    if (progress == 2) {
        [post respring];
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
        [sender setTitle:@"respring" forState:UIControlStateNormal];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChangerBackup/"]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"success" message:[NSString stringWithFormat:@"Successfully restored with backup. click respring"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"failed" message:[NSString stringWithFormat:@"Cannot find backup folder. click respring"] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self failure];
    }
    progress++;
}
@end
