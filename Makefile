TARGET = iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = AmongUs

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LUBV
LUBV_FILES = LUBV_Ultimate.xm
LUBV_CFLAGS = -fobjc-arc
LUBV_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk