#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>
#import "ImGuiDrawView.h"

// Hàm ghi bộ nhớ và đồng bộ instruction cache cho ARM64
void WriteMem(uint64_t address, const void *bytes, size_t size) {
    mach_port_t task = mach_task_self();
    vm_address_t targetPage = (vm_address_t)address & ~(vm_page_size - 1);
    vm_prot_t oldProt = 0;
    
    vm_protect(task, targetPage, vm_page_size, false, VM_PROT_READ | VM_WRITE | VM_COPY);
    memcpy((void *)address, bytes, size);
    vm_protect(task, targetPage, vm_page_size, false, oldProt);
    sys_icache_invalidate((void *)address, size);
}

// Lưu trữ các slide địa chỉ khi app khởi động
static uint64_t unitySlide = 0;
static uint64_t anortSlide = 0;

// Hàm tự động chạy khi tweak vừa load (Luôn bật: Fix crack & Antiban)
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
    });
}

@implementation ImGuiDrawView

- (void)drawView {
    ImGui::Begin("PUBG Mobile Hack Menu", &isMenuOpen, ImGuiWindowFlags_AlwaysAutoResize);
    
    ImGui::TextColored(ImVec4(0, 1, 0, 1), "Status: Fix Crack & Antiban Active");
    ImGui::Separator();
    
    // Khai báo trạng thái các chức năng Bật/Tắt
    static bool b_map = false;
    static bool b_camxa = false;
    static bool b_showunti = false;
    static bool b_showlsd = false;
    static bool b_antray = false;
    
    // 1. Map (Có bật/tắt)
    if (ImGui::Checkbox("Map Hack", &b_map)) {
        if (unitySlide > 0) {
            if (b_map) {
                Byte patch[] = {0x36, 0x00, 0x80, 0xD2};
                WriteMem(unitySlide + 0x4A38100, patch, sizeof(patch));
            } else {
                // Byte gốc của Map (bạn cần thay thế lại byte gốc nếu tắt, hoặc tạm thời để trống nếu chỉ cần bật)
            }
        }
    }
    
    // 2. Cam xa (Có bật/tắt)
    if (ImGui::Checkbox("Cam Xa (Zoom Camera)", &b_camxa)) {
        if (unitySlide > 0 && b_camxa) {
            Byte patchCam1[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
            Byte patchCam2[] = {0x00, 0x00, 0xA8, 0x52, 0x00, 0x00, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6};
            WriteMem(unitySlide + 0x554B9EC, patchCam1, sizeof(patchCam1));
            WriteMem(unitySlide + 0x541142C, patchCam2, sizeof(patchCam2));
            WriteMem(unitySlide + 0x550E2BC, patchCam2, sizeof(patchCam2));
        }
    }
    
    // 3. Show Unti (Có bật/tắt)
    if (ImGui::Checkbox("Show Unti", &b_showunti)) {
        if (unitySlide > 0 && b_showunti) {
            Byte patchShowUnti[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
            WriteMem(unitySlide + 0x5F1C394, patchShowUnti, sizeof(patchShowUnti));
            WriteMem(unitySlide + 0x6A6B798, patchShowUnti, sizeof(patchShowUnti));
            WriteMem(unitySlide + 0x6A6B8FC, patchShowUnti, sizeof(patchShowUnti));
        }
    }
    
    // 4. Show LSD (Có bật/tắt)
    if (ImGui::Checkbox("Show LSD", &b_showlsd)) {
        if (unitySlide > 0 && b_showlsd) {
            Byte patchLSD[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
            WriteMem(unitySlide + 0x5ADF5A8, patchLSD, sizeof(patchLSD));
        }
    }
    
    // 5. Ẩn tia (Có bật/tắt)
    if (ImGui::Checkbox("An Tia", &b_antray)) {
        if (unitySlide > 0 && b_antray) {
            Byte patchAntray[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
            WriteMem(unitySlide + 0x5FBEC8C, patchAntray, sizeof(patchAntray));
        }
    }
    
    ImGui::End();
}

@end
