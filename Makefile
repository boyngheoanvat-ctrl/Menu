THEOS_DEVICE_IP = 
ARCHS = arm64
TARGET = iphone:clang:latest:12.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PubgCheatMenu

PubgCheatMenu_FILES = menu.mm
PubgCheatMenu_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-value
PubgCheatMenu_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 UnityFramework || true"
