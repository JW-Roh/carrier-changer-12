#import <Foundation/Foundation.h>
#include "post.h"
#import "kernel_memory.h"
#import "kernel_slide.h"
#import "offsets.h"
#include <sys/sysctl.h>
#include <assert.h>
#include <mach/vm_region.h>
#include <mach-o/loader.h>
#include "platform.h"
#include "parameters.h"

@implementation Post

extern int reboot(int howto);

- (uint64_t)selfproc {
    return kernel_read64(current_task + OFFSET(task, bsd_info));
}

- (int)name_to_pid:(NSString *)name {
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            maxArgumentSize = 4096;
        }
    }
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
    struct kinfo_proc *info;
    size_t length;
    int count;
    sysctl(mib, 3, NULL, &length, NULL, 0);
    info = malloc(length);
    sysctl(mib, 3, info, &length, NULL, 0);
    count = (int)length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char *buffer = (char *)malloc(length);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            NSString *executable = [NSString stringWithCString:(buffer+sizeof(int)) encoding:NSUTF8StringEncoding];
            if ([[executable lastPathComponent] isEqual:name]) {
                return info[i].kp_proc.p_pid;
            }
        }
        free(buffer);
    }
    free(info);
    return 0;
}

- (void)root {
    uint64_t proc = [self selfproc];
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    kernel_write32(proc + off_p_uid, 0);
    kernel_write32(proc + off_p_ruid, 0);
    kernel_write32(proc + off_p_gid, 0);
    kernel_write32(proc + off_p_rgid, 0);
    kernel_write32(ucred + off_ucred_cr_uid, 0);
    kernel_write32(ucred + off_ucred_cr_ruid, 0);
    kernel_write32(ucred + off_ucred_cr_svuid, 0);
    kernel_write32(ucred + off_ucred_cr_ngroups, 1);
    kernel_write32(ucred + off_ucred_cr_groups, 0);
    kernel_write32(ucred + off_ucred_cr_rgid, 0);
    kernel_write32(ucred + off_ucred_cr_svgid, 0);
}

- (void)unsandbox {
    uint64_t proc = [self selfproc];
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    uint64_t cr_label = kernel_read64(ucred + off_ucred_cr_label);
    kernel_read64(cr_label + off_sandbox_slot);
    kernel_write64(cr_label + off_sandbox_slot, 0);
}

- (void)reboot {
    [self copyFolderToChange];
    [self removeFolderAtOverlay];
    [self copyFolderToOverlay];
    [self removeFolderAtMedia];
    kill([self name_to_pid:@"CommCenter"], SIGKILL);
    //reboot(0x400);
}

- (bool)respring {
    offs_init();
    printf("Getting root...\n");
    [self root];
    printf("UID: %i\n", getuid());
    printf("Unsandboxing...\n");
    [self unsandbox];
    printf("Unsandboxed: %i\n", (kernel_read64(kernel_read64(kernel_read64([self selfproc] + off_p_ucred) + off_ucred_cr_label) + off_sandbox_slot) == 0) ? 1 : 0);
    printf("Success!\n");
    kill([self name_to_pid:@"backboardd"], SIGKILL);
    return getuid() ? false : true;
}

- (void)letsChange {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/CarrierChanger12"] == YES) {
        printf("No need to make a backup.\n");
        [self removeChangeFolder];
        [self copyFolderToMedia];
        [self reboot];
    } else {
        FILE *backupCheck = fopen("/var/mobile/CarrierChanger12", "w");
        if (!backupCheck) {
            printf("Failed to make a backup checker\n");
        }else {
            printf("Successfully make a backup checker\n");
            [self makeBackup];
            [self removeChangeFolder];
            [self copyFolderToMedia];
            [self reboot];
        }
    }
}

- (void)changeItAgain {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/CarrierChanger12"] == YES) {
        [self copyChangeToMedia];
    }
}

- (void)restoreBackup {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChangerBackup/"]) {
        [self copyBackuptoMedia];
    }
}

- (void)makeBackup {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/Library/Carrier Bundles/Overlay/"];
    NSURL *newURL = [NSURL fileURLWithPath:@"/var/mobile/Media/CarrierChangerBackup/"];
    [[NSFileManager defaultManager] copyItemAtPath:oldURL toPath:newURL error:nil];
    printf("Successfully backed up\n");
}

- (void)copyFolderToMedia {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/Library/Carrier Bundles/Overlay/"];
    NSURL *newURL = [NSURL fileURLWithPath:@"/var/mobile/Media/Overlay/"];
    [[NSFileManager defaultManager] copyItemAtPath:oldURL toPath:newURL error:nil];
    printf("Successfully moved a folder\n");
}

- (void)removeFolderAtMedia {
    NSURL *removeThis = [NSURL fileURLWithPath:@"/var/mobile/Media/Overlay/"];
    [[NSFileManager defaultManager] removeItemAtPath:removeThis error:nil];
    printf("Successfully removed a folder\n");
}

- (void)copyFolderToOverlay {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/Media/Overlay/"];
    NSURL *newURL = [NSURL fileURLWithPath:@"/var/mobile/Library/Carrier Bundles/Overlay/"];
    [[NSFileManager defaultManager] copyItemAtPath:oldURL toPath:newURL error:nil];
    printf("Successfully moved a folder\n");
}

- (void)removeFolderAtOverlay {
    NSURL *removeThis = [NSURL fileURLWithPath:@"/var/mobile/Library/Carrier Bundles/Overlay/"];
    [[NSFileManager defaultManager] removeItemAtPath:removeThis error:nil];
    printf("Successfully removed a folder\n");
}

- (void)removeChangeFolder {
    NSURL *removeThis = [NSURL fileURLWithPath:@"/var/mobile/Media/CarrierChanger12/"];
    [[NSFileManager defaultManager] removeItemAtPath:removeThis error:nil];
    printf("Successfully removed a folder\n");
}

- (void)copyFolderToChange {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/Media/Overlay/"];
    NSURL *newURL = [NSURL fileURLWithPath:@"/var/mobile/Media/CarrierChanger12/"];
    [[NSFileManager defaultManager] copyItemAtPath:oldURL toPath:newURL error:nil];
    printf("Successfully moved a folder\n");
}

- (void)copyChangeToMedia {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/Media/CarrierChanger12/"];
    NSURL *newURL = [NSURL fileURLWithPath:@"/var/mobile/Media/Overlay/"];
    [[NSFileManager defaultManager] copyItemAtPath:oldURL toPath:newURL error:nil];
    printf("Successfully moved a folder\n");
}

- (void)copyBackuptoMedia {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/Media/CarrierChangerBackup/"];
    NSURL *newURL = [NSURL fileURLWithPath:@"/var/mobile/Media/Overlay/"];
    [[NSFileManager defaultManager] copyItemAtPath:oldURL toPath:newURL error:nil];
    printf("Successfully moved a folder\n");
}

- (bool)go {
    offs_init();
    printf("Getting root...\n");
    [self root];
    printf("UID: %i\n", getuid());
    printf("Unsandboxing...\n");
    [self unsandbox];
    printf("Unsandboxed: %i\n", (kernel_read64(kernel_read64(kernel_read64([self selfproc] + off_p_ucred) + off_ucred_cr_label) + off_sandbox_slot) == 0) ? 1 : 0);
    printf("Success!\n");
    [self letsChange];
    return getuid() ? false : true;
}

- (bool)revert {
    offs_init();
    printf("Getting root...\n");
    [self root];
    printf("UID: %i\n", getuid());
    printf("Unsandboxing...\n");
    [self unsandbox];
    printf("Unsandboxed: %i\n", (kernel_read64(kernel_read64(kernel_read64([self selfproc] + off_p_ucred) + off_ucred_cr_label) + off_sandbox_slot) == 0) ? 1 : 0);
    printf("Success!\n");
    [self changeItAgain];
    return getuid() ? false : true;
}

- (bool)restore {
    offs_init();
    printf("Getting root...\n");
    [self root];
    printf("UID: %i\n", getuid());
    printf("Unsandboxing...\n");
    [self unsandbox];
    printf("Unsandboxed: %i\n", (kernel_read64(kernel_read64(kernel_read64([self selfproc] + off_p_ucred) + off_ucred_cr_label) + off_sandbox_slot) == 0) ? 1 : 0);
    printf("Success!\n");
    [self restoreBackup];
    return getuid() ? false : true;
}

@end
