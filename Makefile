export TARGET = iphone:clang:latest:7.0
export ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LUBV
LUBV_FILES = Tweak.xm
LUBV_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
