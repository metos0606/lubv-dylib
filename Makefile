# Target iOS 14.0+ for modern iOS toolchains, architecture arm64
TARGET = iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LUBV

# Build files & flags
LUBV_FILES = Tweak.xm
LUBV_CFLAGS = -fobjc-arc
LUBV_FRAMEWORKS = UIKit CoreGraphics QuartzCore
LUBV_LDFLAGS = -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk

# Kill game process after installation via modern payload
after-install::
	install.exec "killall -9 AmongUs"
