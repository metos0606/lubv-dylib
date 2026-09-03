#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

static char kSettingKeyAssociationKey;

// ============================================================
// SETTINGS MANAGEMENT
// ============================================================

@interface LUBVSettings : NSObject

@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) float playerSpeed;

@property (nonatomic, assign) BOOL alwaysImpostor;
@property (nonatomic, assign) BOOL alwaysKill;
@property (nonatomic, assign) BOOL alwaysVent;

@property (nonatomic, assign) BOOL unlockAllAchievements;
@property (nonatomic, assign) BOOL unlockAllCosmetics;

+ (instancetype)sharedInstance;

@end

@implementation LUBVSettings

+ (instancetype)sharedInstance {
    static LUBVSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LUBVSettings alloc] init];
        
        instance.fastSpeed = NO;
        instance.playerSpeed = 2.5f;
        instance.alwaysImpostor = NO;
        instance.alwaysKill = NO;
        instance.alwaysVent = NO;
        instance.unlockAllAchievements = NO;
        instance.unlockAllCosmetics = NO;
    });
    return instance;
}

@end

// ============================================================
// GUI BUTTON & CONTROL PANEL
// ============================================================

@interface LUBVGUIButton : UIButton <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:1.0 alpha:0.9];
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.masksToBounds = NO;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 8;
        self.layer.shadowOpacity = 0.5;
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:self.bounds];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:28];
        iconLabel.textColor = [UIColor whiteColor];
        iconLabel.userInteractionEnabled = NO;
        [self addSubview:iconLabel];
        
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.panGesture.delegate = self;
        [self addGestureRecognizer:self.panGesture];
        
        self.isMenuOpen = NO;
    }
    return self;
}

- (void)createMenu {
    if (self.menuView || !self.superview) return;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat menuWidth = 340.0;
    CGFloat menuHeight = 420.0;
    
    CGFloat menuX = (screenBounds.size.width - menuWidth) / 2.0;
    CGFloat menuY = (screenBounds.size.height - menuHeight) / 2.0;
    
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(menuX, menuY, menuWidth, menuHeight)];
    self.menuView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.95];
    self.menuView.layer.cornerRadius = 20;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 20;
    self.menuView.layer.shadowOpacity = 0.8;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    self.menuView.transform = CGAffineTransformMakeScale(0.85, 0.85);
    
    [self.superview addSubview:self.menuView];
    
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, menuWidth, 50)];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, menuWidth - 80, 30)];
    title.text = @"✦ LUBV MENU ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(menuWidth - 40, 10, 30, 30);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    closeBtn.layer.cornerRadius = 15;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 50, menuWidth - 20, menuHeight - 60)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.menuView addSubview:self.scrollView];
    
    NSArray *features = @[
        @"🏃 Fast Speed",
        @"🎭 Always Impostor",
        @"🗡️ Always Kill / No Cooldown",
        @"💨 Always Vent",
        @"🏆 Unlock All Achievements",
        @"🎁 Unlock All Cosmetics"
    ];
    
    NSArray *keys = @[
        @"fastSpeed",
        @"alwaysImpostor",
        @"alwaysKill",
        @"alwaysVent",
        @"unlockAllAchievements",
        @"unlockAllCosmetics"
    ];
    
    CGFloat yPos = 0;
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    
    for (NSUInteger i = 0; i < features.count; i++) {
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, yPos, menuWidth - 20, 44)];
        rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.7];
        rowView.layer.cornerRadius = 10;
        [self.scrollView addSubview:rowView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 180, 24)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [rowView addSubview:label];
        
        if ([keys[i] isEqualToString:@"fastSpeed"]) {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(150, 6, 50, 30)];
            switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            objc_setAssociatedObject(switchControl, &kSettingKeyAssociationKey, keys[i], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            switchControl.on = settings.fastSpeed;
            [rowView addSubview:switchControl];
            
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(205, 8, 70, 28)];
            self.speedSlider.minimumValue = 1.0f;
            self.speedSlider.maximumValue = 10.0f;
            self.speedSlider.value = settings.playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, 10, 35, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1fx", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:10];
            [rowView addSubview:self.speedLabel];
        } else {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(250, 6, 50, 30)];
            switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            
            objc_setAssociatedObject(switchControl, &kSettingKeyAssociationKey, keys[i], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            
            BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
            switchControl.on = isOn;
            
            [rowView addSubview:switchControl];
        }
        
        yPos += 50;
    }
    
    self.scrollView.contentSize = CGSizeMake(menuWidth - 20, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1fx", sender.value];
}

- (void)switchToggled:(UISwitch *)sender {
    NSString *key = objc_getAssociatedObject(sender, &kSettingKeyAssociationKey);
    if (key) {
        [[LUBVSettings sharedInstance] setValue:@(sender.on) forKey:key];
    }
}

- (void)toggleMenu {
    if (!self.menuView) {
        [self createMenu];
    }
    
    self.isMenuOpen = !self.isMenuOpen;
    
    if (self.isMenuOpen) {
        self.menuView.hidden = NO;
        [self.superview bringSubviewToFront:self.menuView];
        [self.superview bringSubviewToFront:self];
        
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.menuView.alpha = 1.0;
            self.menuView.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.menuView.alpha = 0.0;
            self.menuView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL finished) {
            self.menuView.hidden = YES;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(30, MIN(screenBounds.size.width - 30, newCenter.x));
    newCenter.y = MAX(30, MIN(screenBounds.size.height - 30, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

// ============================================================
// OVERLAY WINDOW ATTACHMENT
// ============================================================

static LUBVGUIButton *guiButton = nil;

static void SetupOverlayWindow(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            targetWindow = window;
                            break;
                        }
                    }
                }
                if (targetWindow) break;
            }
        }
        
        if (!targetWindow) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    targetWindow = window;
                    break;
                }
            }
        }
        
        if (!targetWindow) {
            targetWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (targetWindow && !guiButton) {
            guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 50, 50)];
            [targetWindow addSubview:guiButton];
            [targetWindow bringSubviewToFront:guiButton];
        }
    });
}

// ============================================================
// HOOK SIGNATURES & DYNAMIC BASE RESOLUTION
// ============================================================

static float (*orig_PlayerPhysics_get_TrueSpeed)(void *instance);
static void (*orig_MeetingHud_ForceSkipAll)(void *instance);
static bool (*orig_RoleBehaviour_get_IsImpostor)(void *instance);
static void (*orig_PlayerControl_SetKillTimer)(void *instance, float time);
static void (*orig_RoleBehaviour_Initialize)(void *instance, void *player);

static bool (*orig_HatData_get_IsFree)(void *instance);
static bool (*orig_VisorData_get_IsFree)(void *instance);
static bool (*orig_SkinData_get_IsFree)(void *instance);
static bool (*orig_PetData_get_IsFree)(void *instance);
static bool (*orig_NameplateData_get_IsFree)(void *instance);

// Dynamic ASLR lookup for Unity binary image
static uintptr_t GetRealBaseAddress(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "UnityFramework") || strstr(name, "Frameworks/UnityFramework.framework"))) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// Safe hooking wrapper
static void SafeHook(uintptr_t targetOffset, void *replacement, void **original) {
    if (targetOffset == 0 || replacement == NULL) return;
    uintptr_t base = GetRealBaseAddress();
    if (base != 0) {
        MSHookFunction((void *)(base + targetOffset), replacement, original);
    }
}

// ============================================================
// HOOK HANDLERS
// ============================================================

float hk_PlayerPhysics_get_TrueSpeed(void *instance) {
    if (!instance) return 1.0f;
    
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    float baseSpeed = orig_PlayerPhysics_get_TrueSpeed ? orig_PlayerPhysics_get_TrueSpeed(instance) : 1.0f;

    if (settings.fastSpeed) {
        return baseSpeed * settings.playerSpeed;
    }
    
    return baseSpeed;
}

void hk_MeetingHud_ForceSkipAll(void *instance) {
    if (!instance) return;
    if (orig_MeetingHud_ForceSkipAll) {
        orig_MeetingHud_ForceSkipAll(instance);
    }
}

bool hk_RoleBehaviour_get_IsImpostor(void *instance) {
    if (!instance) return false;

    LUBVSettings *settings = [LUBVSettings sharedInstance];
    if (settings.alwaysImpostor) {
        return true;
    }

    return orig_RoleBehaviour_get_IsImpostor ? orig_RoleBehaviour_get_IsImpostor(instance) : false;
}

void hk_PlayerControl_SetKillTimer(void *instance, float time) {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    if (settings.alwaysKill) {
        time = 0.0f;
    }

    if (orig_PlayerControl_SetKillTimer) {
        orig_PlayerControl_SetKillTimer(instance, time);
    }
}

void hk_RoleBehaviour_Initialize(void *instance, void *player) {
    if (orig_RoleBehaviour_Initialize) {
        orig_RoleBehaviour_Initialize(instance, player);
    }
}

bool hk_HatData_get_IsFree(void *instance) {
    if ([LUBVSettings sharedInstance].unlockAllCosmetics) return true;
    return orig_HatData_get_IsFree ? orig_HatData_get_IsFree(instance) : false;
}

bool hk_VisorData_get_IsFree(void *instance) {
    if ([LUBVSettings sharedInstance].unlockAllCosmetics) return true;
    return orig_VisorData_get_IsFree ? orig_VisorData_get_IsFree(instance) : false;
}

bool hk_SkinData_get_IsFree(void *instance) {
    if ([LUBVSettings sharedInstance].unlockAllCosmetics) return true;
    return orig_SkinData_get_IsFree ? orig_SkinData_get_IsFree(instance) : false;
}

bool hk_PetData_get_IsFree(void *instance) {
    if ([LUBVSettings sharedInstance].unlockAllCosmetics) return true;
    return orig_PetData_get_IsFree ? orig_PetData_get_IsFree(instance) : false;
}

bool hk_NameplateData_get_IsFree(void *instance) {
    if ([LUBVSettings sharedInstance].unlockAllCosmetics) return true;
    return orig_NameplateData_get_IsFree ? orig_NameplateData_get_IsFree(instance) : false;
}

// ============================================================
// CONSTRUCTOR & INITIALIZATION
// ============================================================

static void InitializeHooks(void) {
    // Movement & Meeting
    SafeHook(0x1C666EC, (void *)hk_PlayerPhysics_get_TrueSpeed, (void **)&orig_PlayerPhysics_get_TrueSpeed);
    SafeHook(0x1B90790, (void *)hk_MeetingHud_ForceSkipAll, (void **)&orig_MeetingHud_ForceSkipAll);

    // Gameplay & Roles
    SafeHook(0x1C9BEA0, (void *)hk_RoleBehaviour_get_IsImpostor, (void **)&orig_RoleBehaviour_get_IsImpostor);
    SafeHook(0x1C50FB4, (void *)hk_PlayerControl_SetKillTimer, (void **)&orig_PlayerControl_SetKillTimer);
    SafeHook(0x1C963E4, (void *)hk_RoleBehaviour_Initialize, (void **)&orig_RoleBehaviour_Initialize);

    // Cosmetics
    SafeHook(0x1B381A0, (void *)hk_HatData_get_IsFree, (void **)&orig_HatData_get_IsFree);
    SafeHook(0x1B39D50, (void *)hk_VisorData_get_IsFree, (void **)&orig_VisorData_get_IsFree);
    SafeHook(0x1B3B180, (void *)hk_SkinData_get_IsFree, (void **)&orig_SkinData_get_IsFree);
    SafeHook(0x1B3CB30, (void *)hk_PetData_get_IsFree, (void **)&orig_PetData_get_IsFree);
    SafeHook(0x1B3E040, (void *)hk_NameplateData_get_IsFree, (void **)&orig_NameplateData_get_IsFree);
}

__attribute__((constructor))
static void InitAllTweakHooks(void) {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                     object:nil
                                                      queue:[NSOperationQueue mainQueue]
                                                 usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            SetupOverlayWindow();
            InitializeHooks();
        });
    }];
}
