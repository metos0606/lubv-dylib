#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <mach-o/dyld.h>

static char kSettingKeyAssociationKey;

// ============================================================
// SETTINGS MANAGER
// ============================================================

@interface LUBVSettings : NSObject
@property (nonatomic, assign) BOOL alwaysImpostor;
@property (nonatomic, assign) BOOL noKillCooldown;
@property (nonatomic, assign) BOOL alwaysCanKill;
@property (nonatomic, assign) BOOL alwaysCanVent;
@property (nonatomic, assign) BOOL alwaysCanSabotage;
@property (nonatomic, assign) BOOL alwaysCanReport;
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL unlimitedVision;
@property (nonatomic, assign) BOOL seeGhosts;
@property (nonatomic, assign) BOOL unlimitedEmergencies;
@property (nonatomic, assign) BOOL noClip;
@property (nonatomic, assign) float playerSpeed;
@property (nonatomic, assign) BOOL unlockAllIAP;
+ (instancetype)sharedInstance;
@end

@implementation LUBVSettings

+ (instancetype)sharedInstance {
    static LUBVSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LUBVSettings alloc] init];
        instance.alwaysImpostor = YES;
        instance.noKillCooldown = YES;
        instance.alwaysCanKill = YES;
        instance.alwaysCanVent = YES;
        instance.alwaysCanSabotage = YES;
        instance.alwaysCanReport = YES;
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.unlimitedVision = YES;
        instance.seeGhosts = YES;
        instance.unlimitedEmergencies = NO;
        instance.noClip = NO;
        instance.playerSpeed = 1.5f;
        instance.unlockAllIAP = NO;
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
    CGFloat menuHeight = 450.0;
    
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
    title.text = @"✦ LUBV ULTIMATE ✦";
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
        @"⏱️ No Kill Cooldown", @"🏃 Fast Speed", @"🔭 Unlimited Vision",
        @"🎭 Always Impostor", @"🗡️ Always Can Kill", @"💨 Always Can Vent",
        @"🌀 No Vent Cooldown", @"⚡ Always Can Sabotage", @"📢 Always Can Report",
        @"👻 See Ghosts", @"🛡️ God Mode", @"📞 Unlimited Emergencies",
        @"🚶 No Clip", @"🎁 Unlock All IAP"
    ];
    
    NSArray *keys = @[
        @"noKillCooldown", @"fastSpeed", @"unlimitedVision",
        @"alwaysImpostor", @"alwaysCanKill", @"alwaysCanVent",
        @"noVentCooldown", @"alwaysCanSabotage", @"alwaysCanReport",
        @"seeGhosts", @"godMode", @"unlimitedEmergencies",
        @"noClip", @"unlockAllIAP"
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
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(170, 8, 90, 28)];
            self.speedSlider.minimumValue = 0.5f;
            self.speedSlider.maximumValue = 5.0f;
            self.speedSlider.value = settings.playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(265, 10, 40, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1fx", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:11];
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
    settings.fastSpeed = YES;
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
    UIWindow *targetWindow = nil;
    
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            targetWindow = window;
            break;
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
}

// ============================================================
// HOOK IMPLEMENTATIONS (CORRECTED TYPES AND SAFETY CHECKS)
// ============================================================

static bool (*orig_PlayerControl_get_IsKillTimerEnabled)(void *instance);
static float (*orig_PlayerPhysics_get_TrueSpeed)(void *instance);

// Corrected return type from float to bool
bool hk_PlayerControl_get_IsKillTimerEnabled(void *instance) {
    if (!instance) return false;
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return false;
    }
    return orig_PlayerControl_get_IsKillTimerEnabled ? orig_PlayerControl_get_IsKillTimerEnabled(instance) : false;
}

float hk_PlayerPhysics_get_TrueSpeed(void *instance) {
    if (!instance) return 1.0f;
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return [LUBVSettings sharedInstance].playerSpeed * 2.5f;
    }
    return orig_PlayerPhysics_get_TrueSpeed ? orig_PlayerPhysics_get_TrueSpeed(instance) : 1.0f;
}

static void InitializeHooks(void) {
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    if (base == 0) return;

    MSHookFunction((void *)(base + 0x1C50C30), (void *)hk_PlayerControl_get_IsKillTimerEnabled, (void **)&orig_PlayerControl_get_IsKillTimerEnabled);
    MSHookFunction((void *)(base + 0x1C666EC), (void *)hk_PlayerPhysics_get_TrueSpeed, (void **)&orig_PlayerPhysics_get_TrueSpeed);
}

%ctor {
    // Increased delay to 5s to ensure unity/il2cpp engine is fully loaded before hooking
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetupOverlayWindow();
        InitializeHooks();
    });
}
