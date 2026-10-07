#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_prot.h>
#import <mach/vm_map.h>
#import <libkern/OSCacheControl.h>
#import <sys/mman.h>

// --- ĐỊNH NGHĨA IMGUI GỌN GÀNG TRỰC TIẾP ---
struct ImVec2 { float x, y; ImVec2() : x(0), y(0) {} ImVec2(float _x, float _y) : x(_x), y(_y) {} };
struct ImVec4 { float x, y, z, w; ImVec4() : x(0), y(0), z(0), w(0) {} ImVec4(float x, float y, float z, float w) : x(x), y(y), z(z), w(w) {} };

enum ImGuiWindowFlags_ {
    ImGuiWindowFlags_None = 0,
    ImGuiWindowFlags_AlwaysAutoResize = 1 << 0,
};

namespace ImGui {
    inline void Begin(const char* name, bool* p_open = nullptr, int flags = 0) {}
    inline void End() {}
    inline void Text(const char* fmt, ...) {}
    inline void TextColored(const ImVec4& col, const char* fmt, ...) {}
    inline bool Checkbox(const char* label, bool* v) { return false; }
    inline void Separator() {}
}
// ------------------------------------------

static BOOL isOpen = YES;
static BOOL fixCrackActive = NO;
static BOOL antibanActive = NO;
static BOOL mapHackActive = NO;
static BOOL camXaActive = NO;
static BOOL showUntiActive = NO;
static BOOL showLSDActive = NO;
static BOOL antrayActive = NO;

static uint64_t unitySlide = 0;
static uint64_t anortSlide = 0;

void WriteMem(uint64_t address, const void *bytes, size_t size) {
    if (address == 0) return;
    mach_port_t task = mach_task_self();
    vm_address_t targetPage = (vm_address_t)address & ~(vm_page_size - 1);
    vm_prot_t oldProt = 0;
    
    vm_protect(task, targetPage, vm_page_size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    memcpy((void *)address, bytes, size);
    vm_protect(task, targetPage, vm_page_size, false, oldProt);
    sys_icache_invalidate((void *)address, size);
}

void ApplyPatches() {
    // 1. Fix Crack (anort)
    if (anortSlide > 0) {
        Byte patchFixCrack[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
        WriteMem(anortSlide + 0x31C4C, patchFixCrack, sizeof(patchFixCrack));
        WriteMem(anortSlide + 0x4591C, patchFixCrack, sizeof(patchFixCrack));
        fixCrackActive = YES;
    }

    // 2. Antiban (UnityFramework)
    if (unitySlide > 0) {
        Byte patchAB1[] = {0xC0, 0x03, 0x5F, 0xD6};
        Byte patchAB2[] = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
        Byte patchAB4[] = {0xC0, 0x03, 0x5F, 0xD6, 0x1F, 0x20, 0x03, 0xD5, 0x1F, 0x20, 0x03, 0xD5};
        
        WriteMem(unitySlide + 0x6339604, patchAB1, sizeof(patchAB1));
        WriteMem(unitySlide + 0x706DBA4, patchAB2, sizeof(patchAB2));
        WriteMem(unitySlide + 0x706DF5C, patchAB2, sizeof(patchAB2));
        WriteMem(unitySlide + 0x706E6BC, patchAB4, sizeof(patchAB4));
        antibanActive = YES;
    }
}

__attribute__((constructor)) void initEri() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; i++) {
            const char *name = _dyld_get_image_name(i);
            if (strstr(name, "UnityFramework")) {
                unitySlide = _dyld_get_image_vmaddr_slide(i);
            } else if (strstr(name, "anort")) {
                anortSlide = _dyld_get_image_vmaddr_slide(i);
            }
        }
        ApplyPatches();
    });
}
