#define USE_REAL_PATH
#define AVAILABILITY2_H
#import "../PS.h"
#import "lock.h"

os_unfair_lock override_lock = OS_UNFAIR_LOCK_INIT;

@interface UITextView (Private)
@property(retain, nonatomic) NSString *attributedPlaceholder;
@end

@interface EMKTextView : UITextView
- (void)setEmojiConversionEnabled:(BOOL)enabled;
@end

@interface EMKTextView (Workaround)
- (void)_updatePlaceholder;
@end

@interface _UIFieldEditorContentView : UIView
@end

@interface UIFieldEditor : NSObject
- (NSTextContainer *)_textContainer;
@end

@interface UITextField (Private)
@property(retain, nonatomic) EMKTextView *textView;
- (UIView *)_effectiveContentView;
- (UIFieldEditor *)_fieldEditor;
@end

@interface CKMessageEntryTextView : EMKTextView
@end

%group Extend

%hook UITextView

+ (id)alloc
{
	if (os_unfair_lock_trylock(&override_lock)) {
		id r = [NSClassFromString(@"EMKTextView") alloc];
		os_unfair_lock_unlock(&override_lock);
		return r;
	}
	return %orig;
}

%end

BOOL fakeEmoji = NO;

NSString *(*standardLanguage)(NSString *);
%hookf(NSString *, standardLanguage, NSString *lang)
{
	return fakeEmoji ? @"emoji" : %orig(lang);
}

%hook EMKTextView

- (void)setEmojiConversionLanguagesAndActivateConversion:(bool)enabled
{
	fakeEmoji = YES;
	%orig;
	fakeEmoji = NO;
}

- (id)initWithFrame:(CGRect)frame
{
	self = %orig;
	if (self) {
		MSHookIvar<UILabel *>(self, "_placeholderLabel") = [[UILabel alloc] initWithFrame:CGRectZero];
		MSHookIvar<UILabel *>(self, "_placeholderLabel").textColor = UIColor.lightGrayColor;
		[self addSubview:MSHookIvar<UILabel *>(self, "_placeholderLabel")];
	}
	return self;
}

- (void)layoutSubviews
{
	%orig;
	[MSHookIvar<UILabel *>(self, "_placeholderLabel") sizeToFit];
}

%new
- (void)textChanged:(id)arg1
{
	[self _updatePlaceholder];
}

%new
- (void)_updatePlaceholder
{
	MSHookIvar<UILabel *>(self, "_placeholderLabel").hidden = self.hasText;
}

%new
- (NSString *)placeholder
{
	return MSHookIvar<UILabel *>(self, "_placeholderLabel").text;
}

%new
- (void)setPlaceholder:(NSString *)text
{
	MSHookIvar<UILabel *>(self, "_placeholderLabel").text = text;
}

%end

%end

%ctor
{
	const char *path = realPath2(@"/System/Library/PrivateFrameworks/EmojiKit.framework/EmojiKit");
	dlopen(path, RTLD_LAZY);
	MSImageRef ref = MSGetImageByName(path);
	standardLanguage = (NSString *(*)(NSString *))MSFindSymbol(ref, "_standardLanguage");
	%init;
	if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.MobileSMS"])
		return;
	%init(Extend);
}
