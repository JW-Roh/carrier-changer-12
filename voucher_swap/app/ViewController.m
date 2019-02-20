//
//  ViewController.m
//  voucher_swap
//
//  Created by Brandon Azad on 12/7/18.
//  Copyright © 2018 Brandon Azad. All rights reserved.
//

#import "ViewController.h"

//v3ntex
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, mach_vm_address_t data, mach_vm_size_t *outsize);

@interface ViewController () {
    BOOL is4Kdevice;
}

@end

@implementation ViewController

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

- (IBAction)go:(id)sender {
    Post *post = [[Post alloc] init];
    bool success = [self voucher_swap];
    if (success) {
	sleep(1);
        [post go];
        [self editPlist];
        [post reboot];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfuly changed carrier name to %@", self.carrierTextField.text] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (is4Kdevice) {
        [self dov3ntex];
        [post letsChange];
        [self editPlist];
        [post v3ntexApply];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfuly changed carrier name to %@ \n Reboot your device.", self.carrierTextField.text] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self failure];
    }
}

- (void)editPlist {
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
    } else if (is4Kdevice) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChanger12/"]) {
            [self dov3ntex];
            [post changeItAgain];
            [post v3ntexApply];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Successfully changed carrier name again. Reboot your device."] preferredStyle:UIAlertControllerStyleAlert];
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

- (void)dov3ntex {
    struct utsname ustruct = {};
    uname(&ustruct);
    printf("kern=%s\n",ustruct.version);
    
    mach_port_t tfp0 = v3ntex();
    if (tfp0) dumpSomeKernel(tfp0, kbase, NULL);
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)creditClicked:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Credits" message:[NSString stringWithFormat:@"voucher_swap by bazad\nfork by alticha\nCarrierChanger12 by PeterDev\nSpecial Thanks to Muirey, Luis E,\nWei-Jin Tzeng, Code4iOS,\n jailbreak365 and CoryKornowicz"] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
