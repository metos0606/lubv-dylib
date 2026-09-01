// LUBV Ultimate - Complete Edition (Fixed Logos Hooks & GUI)

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

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
        // Default settings
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
@property (nonatomic, strong) NSMutableDictionary *switches;
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
        self.switches = [NSMutableDictionary dictionary];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.superview) {
                [self createMenu];
            }
        });
    }
    return self;
}

- (void)createMenu {
    if (self.menuView) return;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat menuWidth = 340.0;
    CGFloat menuHeight = 500.0;
    
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
    
    // Header
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
    
    // Scroll Area
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 50, menuWidth - 20, menuHeight - 60)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.menuView addSubview:self.scrollView];
    
    NSArray *features = @[
        @"🎭 Always Impostor", @"⏱️ No Kill Cooldown", @"🗡️ Always Can Kill",
        @"💨 Always Can Vent", @"🌀 No Vent Cooldown", @"⚡ Always Can Sabotage",
        @"📢 Always Can Report", @"🔭 Unlimited Vision", @"👻 See Ghosts",
        @"🛡️ God Mode", @"🏃 Fast Speed", @"📞 Unlimited Emergencies",
        @"🚶 No Clip", @"🎁 Unlock All IAP"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
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
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(190, 8, 80, 28)];
            self.speedSlider.minimumValue = 0.5f;
            self.speedSlider.maximumValue = 3.0f;
            self.speedSlider.value = settings.playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(275, 10, 35, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1f", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:11];
            [rowView addSubview:self.speedLabel];
        } else {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(260, 6, 50, 30)];
            switchControl.tag = i;
            switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            
            BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
            switchControl.on = isOn;
            
            [rowView addSubview:switchControl];
            [self.switches setObject:switchControl forKey:keys[i]];
        }
        
        yPos += 50;
    }
    
    self.scrollView.contentSize = CGSizeMake(menuWidth - 20, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    settings.fastSpeed = YES;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (void)switchToggled:(UISwitch *)sender {
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"unlockAllIAP"
    ];
    
    if (sender.tag < keys.count) {
        NSString *key = keys[sender.tag];
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

- (void)dealloc {
    if (self.menuView) {
        [self.menuView removeFromSuperview];
        self.menuView = nil;
    }
}

@end

// ============================================================
// INJECT GUI OVERLAY
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

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetupOverlayWindow();
    });
}

// ============================================================
// LOGOS HOOKS - Based on Unity Dump
// ============================================================

// Based on: NetworkedPlayerInfo (has RoleType property)
%hook NetworkedPlayerInfo

// Hook role type getter
- (RoleTypes)get_RoleType {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return RoleTypes.Impostor;
    }
    return %orig;
}

// Hook is dead check
- (bool)get_IsDead {
    if ([LUBVSettings sharedInstance].godMode) {
        return false;
    }
    return %orig;
}

%end

// Based on: PlayerControl (from Unity dump)
%hook PlayerControl

// IsImpostor property (from dump)
- (bool)get_IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return true;
    }
    return %orig;
}

// Hook KillCooldown property
- (float)get_KillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

// Hook speed property
- (float)get_Speed {
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return [LUBVSettings sharedInstance].playerSpeed;
    }
    return %orig;
}

// Hook vision radius
- (float)get_VisionRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) {
        return 999.0f;
    }
    return %orig;
}

// Hook CanMove property
- (bool)get_CanMove {
    if ([LUBVSettings sharedInstance].noClip) {
        return true;
    }
    return %orig;
}

// Hook ghost state
- (bool)get_IsGhost {
    if ([LUBVSettings sharedInstance].seeGhosts) {
        return false;
    }
    return %orig;
}

// Hook kill method
- (void)MurderPlayer:(id)player {
    if ([LUBVSettings sharedInstance].godMode && [self get_IsImpostor] == false) {
        // Allow killing in god mode
        %orig;
        return;
    }
    %orig;
}

%end

// Based on: Vent
%hook Vent

// Hook CanUse
- (bool)get_CanUse {
    if ([LUBVSettings sharedInstance].alwaysCanVent) {
        return true;
    }
    return %orig;
}

// Hook cooldown
- (float)get_Cooldown {
    if ([LUBVSettings sharedInstance].noVentCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

// Based on: SabotageManager / SwitchSystem (from dump)
%hook SwitchSystem

// Hook sabotage availability
- (bool)get_IsActive {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return true;
    }
    return %orig;
}

%end

// Based on: KillButton (from dump)
%hook KillButton

// Hook CanKill
- (bool)get_CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return true;
    }
    return %orig;
}

%end

// Based on: MeetingHud
%hook MeetingHud

// Hook report availability
- (bool)get_CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return true;
    }
    return %orig;
}

%end

// Based on: EmergencyButton (from dump)
%hook EmergencyButton

// Hook emergency count
- (int)get_RemainingUses {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return 99;
    }
    return %orig;
}

- (bool)get_CanUse {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return true;
    }
    return %orig;
}

%end

// Based on: HatManager (from dump)
%hook HatManager

// Hook hat unlock check
- (bool)get_IsHatUnlocked:(id)hat {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return true;
    }
    return %orig;
}

%end

// Based on: PetData
%hook PetData

// Hook pet unlock
- (bool)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return false;
    }
    return %orig;
}

%end

// Based on: SkinData
%hook SkinData

// Hook skin unlock
- (bool)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return false;
    }
    return %orig;
}

%end

// Based on: VisorData
%hook VisorData

// Hook visor unlock
- (bool)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return false;
    }
    return %orig;
}

%end

// Based on: NamePlateData
%hook NamePlateData

// Hook nameplate unlock
- (bool)get_IsEmpty {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return false;
    }
    return %orig;
}

%end

// ============================================================
// ROLE COOLDOWN HOOKS (from dump)
// ============================================================

// PhantomRole (if exists)
%hook PhantomRole
- (float)get_Cooldown {
    if ([LUBVSettings sharedInstance].noPhantomCooldown) {
        return 0.0f;
    }
    return %orig;
}
%end

// ShapeshifterRole (if exists)
%hook ShapeshifterRole
- (float)get_Cooldown {
    if ([LUBVSettings sharedInstance].noShapeshifterCooldown) {
        return 0.0f;
    }
    return %orig;
}
%end

// EngineerRole (if exists)
%hook EngineerRole
- (float)get_Cooldown {
    if ([LUBVSettings sharedInstance].noEngineerCooldown) {
        return 0.0f;
    }
    return %orig;
}
%end

// ============================================================
// IAP UNLOCK FOR INVENTORY MANAGER (from dump)
// ============================================================

%hook InventoryManager

// Hook item purchase check
- (bool)GetPurchase:(id)itemKey bundleKey:(id)bundleKey {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return true;
    }
    return %orig;
}

%end