TARGET := iphone:clang:14.5:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GSMRelayOutgoing

GSMRelayOutgoing_FILES = Tweak.x
GSMRelayOutgoing_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
