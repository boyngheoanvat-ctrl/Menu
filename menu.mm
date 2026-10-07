#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>
#import "ImGuiDrawView.h"

void WriteMem(uint64_t address, const void *bytes, size_t size) {
    mach_port_t task = mach_task_self();
    vm_address_t targetPage = (vm_address_t)address & ~(vm_page_size - 1);
    vm_prot_t oldProt = 0;
    
    vm_protect(task, targetPage, vm_page_size, false, VM_PROT_READ | VM_WRITE | VM_COPY);
    memcpy((void *)address, bytes, size);
    vm_protect(task, targetPage, vm_page_size, false, oldProt);
    sys_icache_invalidate((void *)address, size);
}

// Hàm thực thi toàn bộ các offset đã cung cấp
void ApplyAllPatches() {
    uint64_t unitySlide = 0;
    uint64_t anortSlide = 0;
    
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "UnityFramework")) {
            unitySlide = _dyld_get_image_vmaddr_slide(i);
        } else if (strstr(name, "anort")) {
            anortSlide = _dyld_get_image_vmaddr_slide(i);
        }
    }

    // 1. Fix Crack (anort.framework)
    if (anortSlide > 0) {
        Byte patchFixCrack[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
        WriteMem(anortSlide + 0x31C4C, patchFixCrack, sizeof(patchFixCrack));
        WriteMem(anortSlide + 0x4591C, patchFixCrack, sizeof(patchFixCrack));
    }

    // 2. UnityFramework Patches
    if (unitySlide > 0) {
        // Antiban
        Byte patchAB1[] = {0xC0, 0x03, 0x5F, 0xD6};
        Byte patchAB2[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
        Byte patchAB4[] = {0xC0, 0x03, 0x5F, 0xD6, 0x1F, 0x20, 0x03, 0xD5, 0x1F, 0x20, 0x03, 0xD5};
        
        WriteMem(unitySlide + 0x6339604, patchAB1, sizeof(patchAB1));
        WriteMem(unitySlide + 0x706DBA4, patchAB2, sizeof(patchAB2));
        WriteMem(unitySlide + 0x706DF5C, patchAB2, sizeof(patchAB2));
        WriteMem(unitySlide + 0x706E6BC, patchAB4, sizeof(patchAB4));
        
        // Map
        Byte patchMap[] = {0x36, 0x00, 0x80, 0xD2};
        WriteMem(unitySlide + 0x4A38100, patchMap, sizeof(patchMap));
        
        // Cam xa
        Byte patchCam1[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
        Byte patchCam2[] = {0x00, 0x00, 0xA8, 0x52, 0x00, 0x00, 0x27, 0x1E, 0xC0, 0x03, 0x5F, 0xD6};
        WriteMem(unitySlide + 0x554B9EC, patchCam1, sizeof(patchCam1));
        WriteMem(unitySlide + 0x541142C, patchCam2, sizeof(patchCam2));
        WriteMem(unitySlide + 0x550E2BC, patchCam2, sizeof(patchCam2));
        
        // Show Unti
        Byte patchShowUnti[] = {0x20, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
        WriteMem(unitySlide + 0x5F1C394, patchShowUnti, sizeof(patchShowUnti));
        WriteMem(unitySlide + 0x6A6B798, patchShowUnti, sizeof(patchShowUnti));
        WriteMem(unitySlide + 0x6A6B8FC, patchShowUnti, sizeof(patchShowUnti));
        
        // Show LSD
        WriteMem(unitySlide + 0x5ADF5A8, patchShowUnti, sizeof(patchShowUnti));
        
        // Ẩn tia
        WriteMem(unitySlide + 0x5FBEC8C, patchShowUnti, sizeof(patchShowUnti));
    }
}

@implementation ImGuiDrawView

- (void)drawView {
    ImGui::Begin("PUBG Mobile Hack Menu", &isMenuOpen, ImGuiWindowFlags_AlwaysAutoResize);
    
    if (ImGui::Button("🚀 Apply All Cheats / Patches", ImVec2(200, 30))) {
        ApplyAllPatches();
    }
    
    ImGui::Separator();
    ImGui::Text("Status: Loaded Successfully");
    
    ImGui::End();
}

@end
