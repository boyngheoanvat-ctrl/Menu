TARGET := iphone:clang:latest:10.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Eri

Eri_FILES = menu.mm
Eri_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# Tự động tạo và copy file Eri.plist vào thư mục stage để Theos không bao giờ báo lỗi thiếu
before-package::
	mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/
	cp Eri.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/Eri.plist
	cp .theos/obj/Eri.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/Eri.dylib

after-package::
	@echo "Fixing Substrate dependency path..."
	@install_name_tool -change /Library/Frameworks/Cydiasubstrate.framework/Cydiasubstrate @executable_path/libsubstrate.dylib .theos/obj/Eri.dylib || true
