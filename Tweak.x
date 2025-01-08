#define USE_REAL_PATH
#import <PSHeader/Misc.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <os/lock.h>

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

+ (id)alloc {
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
%hookf(NSString *, standardLanguage, NSString *lang) {
    return fakeEmoji ? @"emoji" : %orig(lang);
}

%hook EMKTextView

- (void)setEmojiConversionLanguagesAndActivateConversion:(bool)enabled {
    fakeEmoji = YES;
    %orig;
    fakeEmoji = NO;
}

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    if (self) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textColor = UIColor.lightGrayColor;
        [self setValue:label forKey:@"_placeholderLabel"];
        [self addSubview:label];
    }
    return self;
}

- (void)layoutSubviews {
    %orig;
    [(UILabel *)[self valueForKey:@"_placeholderLabel"] sizeToFit];
}

%new(v@:@)
- (void)textChanged:(id)arg1 {
    [self _updatePlaceholder];
}

%new(v@:)
- (void)_updatePlaceholder {
    ((UILabel *)[self valueForKey:@"_placeholderLabel"]).hidden = self.hasText;
}

%new(@@:)
- (NSString *)placeholder {
    return ((UILabel *)[self valueForKey:@"_placeholderLabel"]).text;
}

%new(v@:@)
- (void)setPlaceholder:(NSString *)text {
    ((UILabel *)[self valueForKey:@"_placeholderLabel"]).text = text;
}

%end

%end

%ctor {
    const char *path = realPath2(@"/System/Library/PrivateFrameworks/EmojiKit.framework/EmojiKit");
    dlopen(path, RTLD_LAZY);
    MSImageRef ref = MSGetImageByName(path);
    standardLanguage = (NSString *(*)(NSString *))MSFindSymbol(ref, "_standardLanguage");
    %init;
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.MobileSMS"])
        return;
    %init(Extend);
}
