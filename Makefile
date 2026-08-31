ARCHS = arm64
TARGET = iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LUBV
LUBV_FILES = Tweak.xm
LUBV_FRAMEWORKS = UIKit CoreGraphics QuartzCore
LUBV_CFLAGS = -fobjc-arc
LUBV_LDFLAGS = -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 AmongUs"
