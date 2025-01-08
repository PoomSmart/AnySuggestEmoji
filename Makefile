SIMULATOR = 0

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = arm64 x86_64 i386
else
	TARGET = iphone:clang:latest:10.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnySuggestEmoji
$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

all::
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/*.dylib /opt/simject
	@cp -v $(PWD)/*.plist /opt/simject
endif
