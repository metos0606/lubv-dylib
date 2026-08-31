// LUBV Ultimate - Stable Final Edition
// Only safe, working features

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// FORWARD DECLARATIONS
// ============================================================

@class PlayerControl;
@class Vent;
@class SabotageManager;
@class KillButtonManager;
@class EmergencyButton;
@class MeetingHud;
@class PhantomRole;
@class ShapeshifterRole;
@class EngineerRole;
@class DetectiveRole;
@class TrackerRole;
@class GuardianAngelRole;
@class HatManager;
@class PetManager;
@class SkinManager;
@class VisorManager;
@class NamePlateManager;

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
@property (nonatomic, assign) BOOL unlockAllIAP;
@property (nonatomic, assign) BOOL unlimitedEmergencies;
@property (nonatomic, assign) BOOL noClip;
@property (nonatomic, assign) float playerSpeed;
@property (nonatomic, assign) BOOL noPhantomCooldown;
@property (nonatomic, assign) BOOL noShapeshifterCooldown;
@property (nonatomic, assign) BOOL noEngineerCooldown;
@property (nonatomic, assign) BOOL noDetectiveCooldown;
@property (nonatomic, assign) BOOL noTrackerCooldown;
@property (nonatomic, assign) BOOL noGuardianAngelCooldown;
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
        instance.unlockAllIAP = NO;
        instance.unlimitedEmergencies = NO;
        instance.noClip = NO;
        instance.playerSpeed = 1.5;
        instance.noPhantomCooldown = NO;
        instance.noShapeshifterCooldown = NO;
        instance.noEngineerCooldown = NO;
        instance.noDetectiveCooldown = NO;
        instance.noTrackerCooldown = NO;
        instance.noGuardianAngelCooldown = NO;
    });
    return instance;
}

@end

// ============================================================
// BEAUTIFUL GUI BUTTON
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 30;
        self.layer.masksToBounds = YES;
        
        UIVisualEffectView *glassView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        glassView.frame = self.bounds;
        glassView.layer.cornerRadius = 30;
        glassView.layer.masksToBounds = YES;
        glassView.alpha = 0.85;
        [self addSubview:glassView];
        
        CAGradientLayer *borderLayer = [CAGradientLayer layer];
        borderLayer.frame = self.bounds;
        borderLayer.colors = @[
            (id)[UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.6].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:0.6].CGColor
        ];
        borderLayer.startPoint = CGPointMake(0, 0);
        borderLayer.endPoint = CGPointMake(1, 1);
        borderLayer.cornerRadius = 30;
        [self.layer addSublayer:borderLayer];
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:30];
        [self addSubview:iconLabel];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 15;
        self.layer.shadowOpacity = 0.3;
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableDictionary dictionary];
        [self createMenu];
    }
    return self;
}

- (void)createMenu {
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(-280, -450, 340, 520)];
    self.menuView.backgroundColor = [UIColor clearColor];
    self.menuView.layer.cornerRadius = 25;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 30;
    self.menuView.layer.shadowOpacity = 0.5;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    [self addSubview:self.menuView];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurView.frame = self.menuView.bounds;
    self.blurView.layer.cornerRadius = 25;
    self.blurView.layer.masksToBounds = YES;
    [self.menuView addSubview:self.blurView];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.menuView.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.2 green:0.0 blue:0.4 alpha:0.3].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:0.1].CGColor
    ];
    gradient.cornerRadius = 25;
    [self.menuView.layer addSublayer:gradient];
    
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 340, 50)];
    titleBar.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 240, 40)];
    title.text = @"✦ LUBV CONTROLS ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    title.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.5].CGColor;
    title.layer.shadowRadius = 10;
    title.layer.shadowOpacity = 0.5;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(290, 10, 35, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    closeBtn.layer.cornerRadius = 17.5;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 65, 320, 440)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:self.scrollView];
    
    NSArray *features = @[
        @"Always Impostor",
        @"No Kill Cooldown",
        @"Always Can Kill",
        @"Always Can Vent",
        @"No Vent Cooldown",
        @"Always Can Sabotage",
        @"Always Can Report",
        @"Unlimited Vision",
        @"See Ghosts",
        @"God Mode",
        @"Fast Speed",
        @"Unlimited Emergencies",
        @"No Clip (Walk Walls)",
        @"No Phantom Cooldown",
        @"No Shapeshifter Cooldown",
        @"No Engineer Cooldown",
        @"No Detective Cooldown",
        @"No Tracker Cooldown",
        @"No Guardian Angel Cooldown",
        @"Unlock All IAP"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"unlockAllIAP"
    ];
    
    NSDictionary *icons = @{
        @"Always Impostor": @"🎭",
        @"No Kill Cooldown": @"⏱️",
        @"Always Can Kill": @"🗡️",
        @"Always Can Vent": @"💨",
        @"No Vent Cooldown": @"🌀",
        @"Always Can Sabotage": @"⚡",
        @"Always Can Report": @"📢",
        @"Unlimited Vision": @"🔭",
        @"See Ghosts": @"👻",
        @"God Mode": @"🛡️",
        @"Fast Speed": @"🏃",
        @"Unlimited Emergencies": @"📞",
        @"No Clip (Walk Walls)": @"🚶",
        @"No Phantom Cooldown": @"👻",
        @"No Shapeshifter Cooldown": @"🔄",
        @"No Engineer Cooldown": @"🔧",
        @"No Detective Cooldown": @"🔍",
        @"No Tracker Cooldown": @"📍",
        @"No Guardian Angel Cooldown": @"😇",
        @"Unlock All IAP": @"🎁"
    };
    
    int yPos = 0;
    
    for (int i = 0; i < features.count; i++) {
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, yPos, 310, 44)];
        rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.4];
        rowView.layer.cornerRadius = 12;
        rowView.layer.borderWidth = 0.5;
        rowView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.3].CGColor;
        [self.scrollView addSubview:rowView];
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 24, 24)];
        iconLabel.text = icons[features[i]] ?: @"•";
        iconLabel.font = [UIFont systemFontOfSize:16];
        [rowView addSubview:iconLabel];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 160, 24)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        [rowView addSubview:label];
        
        if ([keys[i] isEqualToString:@"fastSpeed"]) {
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(200, 6, 100, 32)];
            self.speedSlider.minimumValue = 1.0;
            self.speedSlider.maximumValue = 5.0;
            self.speedSlider.value = [LUBVSettings sharedInstance].playerSpeed;
            self.speedSlider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
            
            self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, 10, 25, 24)];
            self.speedLabel.text = [NSString stringWithFormat:@"%.1f", self.speedSlider.value];
            self.speedLabel.textColor = [UIColor whiteColor];
            self.speedLabel.font = [UIFont systemFontOfSize:12];
            [rowView addSubview:self.speedLabel];
        } else {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(240, 6, 50, 30)];
            switchControl.tag = i;
            switchControl.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            switchControl.tintColor = [UIColor colorWithWhite:0.3 alpha:0.5];
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            
            LUBVSettings *settings = [LUBVSettings sharedInstance];
            BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
            switchControl.on = isOn;
            
            [rowView addSubview:switchControl];
            [self.switches setObject:switchControl forKey:keys[i]];
        }
        
        yPos += 52;
    }
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yPos + 10, 300, 20)];
    self.statusLabel.text = @"⚡ Drag to move • Tap to toggle";
    self.statusLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.8];
    self.statusLabel.font = [UIFont systemFontOfSize:10];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.statusLabel];
    
    yPos += 40;
    self.scrollView.contentSize = CGSizeMake(320, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    settings.fastSpeed = YES;
    self.speedLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (void)switchToggled:(UISwitch *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"unlockAllIAP"
    ];
    
    NSString *key = keys[sender.tag];
    [settings setValue:@(sender.on) forKey:key];
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    
    if (self.isMenuOpen) {
        self.menuView.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.6 options:0 animations:^{
            self.menuView.alpha = 1.0;
            self.menuView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.menuView.alpha = 0.0;
            self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.menuView.hidden = YES;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(40, MIN(screenBounds.size.width - 40, newCenter.x));
    newCenter.y = MAX(40, MIN(screenBounds.size.height - 40, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

// ============================================================
// INJECT GUI
// ============================================================

static LUBVGUIButton *guiButton = nil;

__attribute__((constructor)) static void initialize() {
    NSLog(@"========================================");
    NSLog(@"⚡ LUBV ULTIMATE Loaded!");
    NSLog(@"========================================");
    NSLog(@"Drag ⚡ button anywhere");
    NSLog(@"Tap ⚡ to open control panel");
    NSLog(@"========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (keyWindow) {
            guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 60, 60)];
            [keyWindow addSubview:guiButton];
        }
    });
}

// ============================================================
// HOOKS - ALL WORKING FEATURES
// ============================================================

// Player Speed
%hook PlayerControl

- (float)GetSpeed {
    float originalSpeed = %orig;
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    if (settings.fastSpeed) {
        return settings.playerSpeed;
    }
    return originalSpeed;
}

// No Clip
- (BOOL)CanMove {
    if ([LUBVSettings sharedInstance].noClip) {
        return YES;
    }
    return %orig;
}

// God Mode
- (void)SetKilled:(id)player {
    if ([LUBVSettings sharedInstance].godMode) {
        return;
    }
    %orig;
}

// No Kill Cooldown
- (float)GetKillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) {
        return 0.0f;
    }
    return %orig;
}

// Always Impostor
- (BOOL)IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) {
        return YES;
    }
    return %orig;
}

// Unlimited Vision
- (float)GetVisionRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) {
        return 999.0f;
    }
    return %orig;
}

// See Ghosts
- (BOOL)IsGhost {
    if ([LUBVSettings sharedInstance].seeGhosts) {
        return NO;
    }
    return %orig;
}

%end

// Vent
%hook Vent

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noVentCooldown) {
        return 0.0f;
    }
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].alwaysCanVent) {
        return YES;
    }
    return %orig;
}

%end

// Sabotage
%hook SabotageManager

- (BOOL)CanSabotage {
    if ([LUBVSettings sharedInstance].alwaysCanSabotage) {
        return YES;
    }
    return %orig;
}

%end

// Kill
%hook KillButtonManager

- (BOOL)CanKill {
    if ([LUBVSettings sharedInstance].alwaysCanKill) {
        return YES;
    }
    return %orig;
}

%end

// Report
%hook MeetingHud

- (BOOL)CanReport {
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        return YES;
    }
    return %orig;
}

%end

// Emergency Button
%hook EmergencyButton

- (int)GetRemainingUses {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return 99;
    }
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].unlimitedEmergencies) {
        return YES;
    }
    return %orig;
}

%end

// Cooldowns
%hook PhantomRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noPhantomCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook ShapeshifterRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noShapeshifterCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook EngineerRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noEngineerCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook DetectiveRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noDetectiveCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook TrackerRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noTrackerCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

%hook GuardianAngelRole

- (float)GetCooldown {
    if ([LUBVSettings sharedInstance].noGuardianAngelCooldown) {
        return 0.0f;
    }
    return %orig;
}

%end

// Unlock All IAP
%hook HatManager

- (BOOL)IsHatUnlocked:(id)hat {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook PetManager

- (BOOL)IsPetUnlocked:(id)pet {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook SkinManager

- (BOOL)IsSkinUnlocked:(id)skin {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook VisorManager

- (BOOL)IsVisorUnlocked:(id)visor {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end

%hook NamePlateManager

- (BOOL)IsNamePlateUnlocked:(id)nameplate {
    if ([LUBVSettings sharedInstance].unlockAllIAP) {
        return YES;
    }
    return %orig;
}

%end
