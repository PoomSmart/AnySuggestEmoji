SIMULATOR = 0

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:10.2
	ARCHS = armv7 arm64
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnySuggestEmoji
AnySuggestEmoji_FILES = Tweak.xm
AnySuggestEmoji_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

all::
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/*.dylib /opt/simject
	@cp -v $(PWD)/*.plist /opt/simject
endif
