TARGET := iphone:clang:latest:10.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Eri

Eri_FILES = menu.mm
Eri_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# Tự sinh ra file Eri.plist ngay từ bước đầu tiên trước khi stage check
internal-tweak-stage::
	@echo "Generating Eri.plist programmatically..."
	@echo '{\n    Filter = {\n        Bundles = (\n            "com.garena.game.kgvn"\n        );\n    };\n}' > $(_THEOS_CURRENT_PROJECT_DIR)/Eri.plist

after-package::
	@echo "Fixing Substrate dependency path..."
	@install_name_tool -change /Library/Frameworks/Cydiasubstrate.framework/Cydiasubstrate @executable_path/libsubstrate.dylib .theos/obj/Eri.dylib || true
