#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <mach/vm_prot.h>
#import <libkern/OSCacheControl.h>

static BOOL WriteMemory(uint64_t address,
                        const void *bytes,
                        size_t size)
{
    if (address == 0 || bytes == NULL || size == 0)
        return NO;

    mach_port_t task = mach_task_self();

    vm_address_t page =
        (vm_address_t)address & ~(vm_page_size - 1);

    vm_size_t offset =
        (vm_address_t)address - page;

    vm_size_t length =
        ((offset + size + vm_page_size - 1) /
         vm_page_size) * vm_page_size;

    vm_prot_t current = 0;
    vm_prot_t max = 0;

    kern_return_t kr = vm_region_64(
        task,
        &page,
        &length,
        VM_REGION_BASIC_INFO_64,
        (vm_region_info_t)&current,
        &(mach_msg_type_number_t){VM_REGION_BASIC_INFO_COUNT_64},
        &(mach_port_t){0}
    );

    if (kr != KERN_SUCCESS)
        return NO;

    vm_prot_t writable =
        current | VM_PROT_READ | VM_PROT_WRITE;

    kr = vm_protect(
        task,
        page,
        length,
        false,
        writable
    );

    if (kr != KERN_SUCCESS)
        return NO;

    memcpy((void *)address, bytes, size);

    sys_icache_invalidate(
        (void *)address,
        size
    );

    vm_protect(
        task,
        page,
        length,
        false,
        current
    );

    return YES;
}
