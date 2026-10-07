#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_prot.h>
#import <mach/vm_map.h>
#import <libkern/OSCacheControl.h>
#import <sys/mman.h>

// Hàm ghi bộ nhớ ARM64 an toàn
void WriteMem(uint64_t address, const void *bytes, size_t size) {
    mach_port_t task = mach_task_self();
    vm_address_t targetPage = (vm_address_t)address & ~(vm_page_size - 1);
    vm_prot_t oldProt = 0;
    
    vm_protect(task, targetPage, vm_page_size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    memcpy((void *)address, bytes, size);
    vm_protect(task, targetPage, vm_page_size, false, oldProt);
    sys_icache_invalidate((void *)address, size);
}

static uint64_t unitySlide = 0;
static uint64_t anortSlide = 0;

// Khởi chạy ngầm Fix Crack & Antiban khi load tweak
__attribute__((constructor)) void initPatches() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; i++) {
            const char *name = _dyld_get_image_name(i);
            if (strstr(name, "UnityFramework")) {
                unitySlide = _dyld_get_image_vmaddr_slide(i);
            } else if (strstr(name, "anort")) {
                anortSlide = _dyld_get_image_vmaddr_slide(i);
            }
        }

        // 1. Fix Crack (Luôn bật)
        if (anortSlide > 0) {
            Byte patchFixCrack[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
            WriteMem(anortSlide + 0x31C4C, patchFixCrack, sizeof(patchFixCrack));
            WriteMem(anortSlide + 0x4591C, patchFixCrack, sizeof(patchFixCrack));
        }

        // 2. Antiban (Luôn bật)
        if (unitySlide > 0) {
            Byte patchAB1[] = {0xC0, 0x03, 0x5F, 0xD6};
            Byte patchAB2[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
            Byte patchAB4[] = {0xC0, 0x03, 0x5F, 0xD6, 0x1F, 0x20, 0x03, 0xD5, 0x1F, 0x20, 0x03, 0xD5};
            
            WriteMem(unitySlide + 0x6339604, patchAB1, sizeof(patchAB1));
            WriteMem(unitySlide + 0x706DBA4, patchAB2, sizeof(patchAB2));
            WriteMem(unitySlide + 0x706DF5C, patchAB2, sizeof(patchAB2));
            WriteMem(unitySlide + 0x706E6BC, patchAB4, sizeof(patchAB4));
        }
        
        // Hiển thị thông báo khi Menu đã sẵn sàng
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"PUBG Hack Menu" message:@"Fix Crack & Antiban Active!" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// Xử lý bật/tắt các chức năng
void ToggleFeature(int featureID, BOOL enable) {
    if (unitySlide == 0) return;
    
    switch (featureID) {
        case 1: { // Map Hack
            if (enable) {
                Byte patch[] = {0x36, 0x00, 0x80, 0xD2};
                WriteMem(unitySlide + 0x4A38100, patch, sizeof(patch));
            } else {
                Byte orig[] = {0xF6, 0x03, 0x02, 0xAA};
                WriteMem(unitySlide + 0x4A38100, orig, sizeof(orig));
            }
            break;
        }
        case 2: { // Cam Xa
            if (enable) {
                Byte patchCam1[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
                Byte patchCam2[] = {0x00, 0x00, 0xA8, 0x52, 0x00, 0x00, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6};
                WriteMem(unitySlide + 0x554B9EC, patchCam1, sizeof(patchCam1));
                WriteMem(unitySlide + 0x541142C, patchCam2, sizeof(patchCam2));
                WriteMem(unitySlide + 0x550E2BC, patchCam2, sizeof(patchCam2));
            } else {
                Byte origCam1[] = {0xFF, 0xC3, 0x00, 0xD1, 0xF4, 0x4F, 0x01, 0xA9};
                Byte origCam2[] = {0xE9, 0x23, 0xBD, 0x6D, 0xF4, 0x4F, 0x01, 0xA9, 0xFD, 0x7B, 0x02, 0xA9};
                Byte origCam3[] = {0xF4, 0x4F, 0xBE, 0xA9, 0xFD, 0x7B, 0x01, 0xA9, 0xFD, 0x43, 0x00, 0x91};
                WriteMem(unitySlide + 0x554B9EC, origCam1, sizeof(origCam1));
                WriteMem(unitySlide + 0x541142C, origCam2, sizeof(origCam2));
                WriteMem(unitySlide + 0x550E2BC, origCam3, sizeof(origCam3));
            }
            break;
        }
        case 3: { // Show Unti
            if (enable) {
                Byte patchShowUnti[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
                WriteMem(unitySlide + 0x5F1C394, patchShowUnti, sizeof(patchShowUnti));
                WriteMem(unitySlide + 0x6A6B798, patchShowUnti, sizeof(patchShowUnti));
                WriteMem(unitySlide + 0x6A6B8FC, patchShowUnti, sizeof(patchShowUnti));
            } else {
                Byte orig1[] = {0xFF, 0x43, 0x01, 0xD1, 0xF8, 0x5F, 0x01, 0xA9};
                Byte orig2[] = {0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9};
                WriteMem(unitySlide + 0x5F1C394, orig1, sizeof(orig1));
                WriteMem(unitySlide + 0x6A6B798, orig2, sizeof(orig2));
                WriteMem(unitySlide + 0x6A6B8FC, orig2, sizeof(orig2));
            }
            break;
        }
        case 4: { // Show LSD
            if (enable) {
                Byte patchLSD[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
                WriteMem(unitySlide + 0x5ADF5A8, patchLSD, sizeof(patchLSD));
            } else {
                Byte origLSD[] = {0xF4, 0x4F, 0xBE, 0xA9, 0xFD, 0x7B, 0x01, 0xA9};
                WriteMem(unitySlide + 0x5ADF5A8, origLSD, sizeof(origLSD));
            }
            break;
        }
        case 5: { // Ẩn tia
            if (enable) {
                Byte patchAntray[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
                WriteMem(unitySlide + 0x5FBEC8C, patchAntray, sizeof(patchAntray));
            } else {
                Byte origAntray[] = {0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9};
                WriteMem(unitySlide + 0x5FBEC8C, origAntray, sizeof(origAntray));
            }
            break;
        }
        default:
            break;
    }
}
