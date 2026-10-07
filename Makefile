TARGET := iphone:clang:latest:10.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Eri

Eri_FILES = menu.mm
Eri_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
