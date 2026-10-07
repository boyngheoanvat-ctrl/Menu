TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Eri

Eri_FILES = menu.mm PubgLoad.m
Eri_PLIST = Eri.plist

include $(THEOS_MAKE_PATH)/tweak.mk
