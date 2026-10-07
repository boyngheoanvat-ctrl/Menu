THEOS_DEVICE_IP = 
ARCHS = arm64
TARGET = iphone:clang:latest:12.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PubgCheat

PubgCheat_FILES = PubgLoad.m ImGuiDrawView.mm menu.mm JHDragView.m JHPP.m
PubgCheat_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-value
PubgCheat_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 UnityFramework || true"
