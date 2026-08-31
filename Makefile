export TARGET = iphone:clang:latest:7.0
export ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LUBV
LUBV_FILES = Tweak.xm
LUBV_FRAMEWORKS = UIKit

# Force output directory
LUBV_OBJ_DIR = $(THEOS_OBJ_DIR)/$(TWEAK_NAME)

include $(THEOS_MAKE_PATH)/tweak.mk

# Add a dummy rule to ensure build
all::
	@echo "Building $(TWEAK_NAME)"
	@ls -la $(THEOS_OBJ_DIR)/debug/arm64/ 2>/dev/null || echo "Build output not found"
