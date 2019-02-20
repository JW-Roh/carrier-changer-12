//
//  ConfirmViewController.m
//  voucher_swap
//
//  Created by Soongyu Kwon on 04/02/2019.
//  Copyright © 2019 PeterDev. All rights reserved.
//

#import "ConfirmViewController.h"

//v3ntex
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, mach_vm_address_t data, mach_vm_size_t *outsize);

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

//v3ntex
void DumpHex(const void* data, size_t size) {
    char ascii[17];
    size_t i, j;
    ascii[16] = '\0';
    for (i = 0; i < size; ++i) {
        printf("%02X ", ((unsigned char*)data)[i]);
        if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
            ascii[i % 16] = ((unsigned char*)data)[i];
        } else {
            ascii[i % 16] = '.';
        }
        if ((i+1) % 8 == 0 || i+1 == size) {
            printf(" ");
            if ((i+1) % 16 == 0) {
                printf("|  %s \n", ascii);
            } else if (i+1 == size) {
                ascii[(i+1) % 16] = '\0';
                if ((i+1) % 16 <= 8) {
                    printf(" ");
                }
                for (j = (i+1) % 16; j < 16; ++j) {
                    printf("   ");
                }
                printf("|  %s \n", ascii);
            }
        }
    }
}

//v3ntex
kern_return_t dumpSomeKernel(task_t tfp0, kptr_t kbase, void *data){
    kern_return_t err = 0;
    char buf[0x1000] = {};
    
    mach_vm_size_t rSize = 0;
    err = mach_vm_read_overwrite(tfp0, kbase, sizeof(buf), buf, &rSize);
    
    printf("some kernel:\n");
    DumpHex(buf, sizeof(buf));
    
    printf("lol\n");
    //exit(0); //we are no shenanigans!
    return err;
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
            [self dov3ntex];
            [post restoreBackup];
            [post v3ntexApply];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfully restored with backup. Reboot your device."] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
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

- (void)dov3ntex {
    struct utsname ustruct = {};
    uname(&ustruct);
    printf("kern=%s\n",ustruct.version);
    
    mach_port_t tfp0 = v3ntex();
    if (tfp0) dumpSomeKernel(tfp0, kbase, NULL);
}

@end
