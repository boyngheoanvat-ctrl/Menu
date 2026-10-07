TARGET := iphone:clang:latest:10.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Eri

# Thêm menu.mm và các file xử lý ImGui (nếu có thêm imgui.cpp thì điền vào đây)
Eri_FILES = menu.mm 
Eri_FRAMEWORKS = UIKit Foundation OpenGLES Metal QuartzCore
Eri_CFLAGS = -fobjc-arc -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk

after-package::
	@echo "Fixing Substrate dependency path..."
	@install_name_tool -change /Library/Frameworks/Cydiasubstrate.framework/Cydiasubstrate @executable_path/libsubstrate.dylib .theos/obj/Eri.dylib || true
