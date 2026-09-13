TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GSMRouter

GSMRouter_FILES = Tweak.x
GSMRouter_CFLAGS = -fobjc-arc
GSMRouter_FRAMEWORKS = Foundation UIKit
GSMRouter_PRIVATE_FRAMEWORKS = TelephonyUtilities

include $(THEOS_MAKE_PATH)/tweak.mk
