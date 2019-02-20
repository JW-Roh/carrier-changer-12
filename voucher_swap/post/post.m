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
#include "log.h"

@implementation Post

extern int reboot(int howto);

static uint64_t SANDBOX = 0;

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

- (bool)isRoot {
    return !getuid() && !getgid();
}

- (bool)isMobile {
    return getuid() == 501 && getgid() == 501;
}

- (void)setUID:(uid_t)uid {
    [self setUID:uid forProc:[self selfproc]];
}

- (void)setUID:(uid_t)uid forProc:(uint64_t)proc {
    if (getuid() == uid) return;
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    kernel_write32(proc + off_p_uid, uid);
    kernel_write32(proc + off_p_ruid, uid);
    kernel_write32(ucred + off_ucred_cr_uid, uid);
    kernel_write32(ucred + off_ucred_cr_ruid, uid);
    kernel_write32(ucred + off_ucred_cr_svuid, uid);
    INFO("Overwritten UID to %i for proc 0x%llx", uid, proc);
}

- (void)setGID:(gid_t)gid {
    [self setGID:gid forProc:[self selfproc]];
}

- (void)setGID:(gid_t)gid forProc:(uint64_t)proc {
    if (getgid() == gid) return;
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    kernel_write32(proc + off_p_gid, gid);
    kernel_write32(proc + off_p_rgid, gid);
    kernel_write32(ucred + off_ucred_cr_rgid, gid);
    kernel_write32(ucred + off_ucred_cr_svgid, gid);
    INFO("Overwritten GID to %i for proc 0x%llx", gid, proc);
}

- (void)setUIDAndGID:(int)both {
    [self setUIDAndGID:both forProc:[self selfproc]];
}

- (void)setUIDAndGID:(int)both forProc:(uint64_t)proc {
    [self setUID:both forProc:proc];
    [self setGID:both forProc:proc];
}

- (void)root {
    [self setUIDAndGID:0];
}

- (void)mobile {
    [self setUIDAndGID:501];
}

// Sandbox //

- (bool)isSandboxed {
    if (!MACH_PORT_VALID(kernel_task_port)) {
        [[NSFileManager defaultManager] createFileAtPath:@"/var/TESTF" contents:nil attributes:nil];
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/TESTF"]) return true;
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/TESTF" error:nil];
        return false;
    }
    return kernel_read64(kernel_read64(kernel_read64([self selfproc] + off_p_ucred) + off_ucred_cr_label) + off_sandbox_slot) != 0;
}

- (bool)isSandboxed:(uint64_t)proc {
    return kernel_read64(kernel_read64(kernel_read64(proc + off_p_ucred) + off_ucred_cr_label) + off_sandbox_slot) != 0;
}

- (void)sandbox {
    [self sandbox:[self selfproc]];
}

- (void)sandbox:(uint64_t)proc {
    INFO("Sandboxed proc 0x%llx", proc);
    if ([self isSandboxed]) return;
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    uint64_t cr_label = kernel_read64(ucred + off_ucred_cr_label);
    kernel_write64(cr_label + off_sandbox_slot, SANDBOX);
    SANDBOX = 0;
}

- (void)unsandbox {
    [self unsandbox:[self selfproc]];
}

- (void)unsandbox:(uint64_t)proc {
    INFO("Unsandboxed proc 0x%llx", proc);
    if (![self isSandboxed]) return;
    uint64_t ucred = kernel_read64(proc + off_p_ucred);
    uint64_t cr_label = kernel_read64(ucred + off_ucred_cr_label);
    if (SANDBOX == 0) SANDBOX = kernel_read64(cr_label + off_sandbox_slot);
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

- (void)letsChange {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/CarrierChanger12"] == YES) {
        printf("Old file\n");
        [self removeChangeFolder];
        [self copyFolderToMedia];
        [self switchToNew];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/.CarrierChanger12"] == YES) {
        [self removeChangeFolder];
        [self copyFolderToMedia];
    } else {
        FILE *backupCheck = fopen("/var/mobile/.CarrierChanger12", "w");
        if (!backupCheck) {
            printf("Failed to make a backup checker\n");
        }else {
            printf("Successfully make a backup checker\n");
            [self makeBackup];
            [self removeChangeFolder];
            [self copyFolderToMedia];
        }
    }
}

- (void)switchToNew {
    NSURL *oldURL = [NSURL fileURLWithPath:@"/var/mobile/CarrierChanger12"];
    [[NSFileManager defaultManager] removeItemAtPath:oldURL error:nil];
    FILE *backupCheck = fopen("/var/mobile/.CarrierChanger12", "w");
    if (!backupCheck) {
        printf("Failed to make a backup checker\n");
    }else {
        printf("Successfully make a backup checker\n");
    }
}

- (void)changeItAgain {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/CarrierChanger12/"] == YES) {
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
