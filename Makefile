target := iphone:clang:latest:14.0
installer := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GSMBridgeDaemon

GSMBridgeDaemon_FILES = Tweak.xm
GSMBridgeDaemon_FRAMEWORKS = Foundation CoreTelephony

include $(THEOS_MAKE_PATH)/tweak.mk
