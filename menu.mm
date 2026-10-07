#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>
#import "ImGuiDrawView.h"
#import <substrate.h> // Hoặc CaptainHook tuỳ môi trường

// Hàm hỗ trợ patch offset ARM64
void WriteMem(uint64_t address, const void *bytes, size_t size) {
    mach_port_t task = mach_task_self();
    vm_address_t targetPage = (vm_address_t)address & ~(vm_page_size - 1);
    vm_prot_t oldProt = 0;
    
    vm_protect(task, targetPage, vm_page_size, false, VM_PROT_READ | VM_WRITE | VM_COPY);
    memcpy((void *)address, bytes, size);
    vm_protect(task, targetPage, vm_page_size, false, oldProt);
    
    // Đồng bộ cache instruction cho ARM64
    sys_icache_invalidate((void *)address, size);
}

// Hàm patch nhanh các byte hex cho ARM64
void PatchOffset(uint64_t offset, std::vector<uint8_t> bytes) {
    uint64_t slide = _dyld_get_image_vmaddr_slide(0); // Hoặc slide của UnityFramework
    // Nếu dùng UnityFramework, cần lấy slide của Image tương ứng. 
    // Ở đây ví dụ cách patch cơ bản:
    uint64_t addr = offset; // Đã bao gồm slide hoặc tính toán thêm
    
    // Cấp quyền ghi bộ nhớ
    DWORD oldProtect;
    // Sử dụng vm_write hoặc mprotect tiêu chuẩn iOS
    mach_port_t tache = mach_task_self();
    vm_address_t page = (vm_address_t)addr & ~(vm_page_size - 1);
    vm_prot_t prot;
    vm_get_protection(tache, page, &prot);
    vm_protect(tache, page, vm_page_size, false, VM_PROT_READ | VM_WRITE | VM_EXECUTE);
    
    memcpy((void *)addr, bytes.data(), bytes.size());
    
    vm_protect(tache, page, vm_page_size, false, prot);
    sys_icache_invalidate((void *)addr, bytes.size());
}

// Thực thi patch các tính năng khi bật menu
void ApplyPatches() {
    uint64_t unitySlide = 0;
    uint64_t anortSlide = 0;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "UnityFramework")) {
            unitySlide = _dyld_get_image_vmaddr_slide(i);
        } else if (strstr(name, "anort")) {
            anortSlide = _dyld_get_image_vmaddr_slide(i);
        }
    }

    // 1. Fix Crack (anort)
    // 0x31C4C: 00 00 80 D2 C0 03 5F D6
    // 0x4591C: 00 00 80 D2 C0 03 5F D6
    if (anortSlide > 0) {
        Byte patch1[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
        WriteMem(anortSlide + 0x31C4C, patch1, sizeof(patch1));
        WriteMem(anortSlide + 0x4591C, patch1, sizeof(patch1));
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
    }
}

// Giao diện ImGui Menu
@implementation ImGuiDrawView

static bool b_map = false;
static bool b_camxa = false;
static bool b_showunti = false;
static bool b_showlsd = false;
static bool b_antray = false;

- (void)drawView {
    ImGui::Begin("PUBG Mobile Cheat Menu", &isMenuOpen, ImGuiWindowFlags_AlwaysAutoResize);
    
    if (ImGui::Button("Apply Fix Crack & Antiban")) {
        ApplyPatches();
    }
    
    ImGui::Separator();
    
    if (ImGui::Checkbox("Map Hack", &b_map)) {
        uint64_t unitySlide = 0; // Lấy slide tương tự
        // Patch Map: 0x4A38100: 36 00 80 D2
        // Thêm logic bật/tắt tùy ý ở đây
    }
    
    if (ImGui::Checkbox("Cam Xa (Zoom Camera)", &b_camxa)) {
        // Offset Cam xa: 0x554B9EC, 0x541142C, 0x550E2BC
    }
    
    if (ImGui::Checkbox("Show Unti", &b_showunti)) {
        // Offset: 0x5F1C394, 0x6A6B798, 0x6A6B8FC
    }
    
    if (ImGui::Checkbox("Show LSD", &b_showlsd)) {
        // Offset: 0x5ADF5A8
    }
    
    if (ImGui::Checkbox("Ẩn Tia", &b_antray)) {
        // Offset: 0x5FBEC8C
    }
    
    ImGui::End();
}

@end
