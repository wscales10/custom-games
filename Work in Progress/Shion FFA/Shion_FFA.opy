settings {
    "main": {
        "modeName": "Shion FFA"
    },
    "lobby": {
        "ffaSlots": 11
    },
    "gamemodes": {
        "ffa": {
            "enabledMaps": [
                "dorado",
                "hanamura",
                "horizonLunarColony",
                "iliosLighthouse",
                "iliosRuins",
                "iliosWell",
                "lijiangControlCenter",
                "lijiangGarden",
                "lijiangNightMarket",
                "nepalSanctum",
                "nepalShrine",
                "nepalVillage",
                "oasisCityCenter",
                "oasisGardens",
                "oasisUniversity",
                "paris",
                "templeOfAnubis",
                "volskaya"
            ]
        },
        "general": {
            "heroLimit": "off",
            "enableKillCam": false
        }
    },
    "heroes": {
        "allTeams": {
            "shion": {
                "ability2Cooldown%": 73,
                "ability2Duration%": 425
            },
            "enabledHeroes": [
                "shion"
            ],
        }
    }
}

#Global variables

globalvar ObjectivePositions 0
globalvar IsObjectiveUnlocked 1
globalvar ObjectiveUnlockTime 2
globalvar AllowedObjectiveIndices 3
globalvar i 4
globalvar CapturingPlayers 5
globalvar PreviousObjective 6
globalvar CurrentObjectiveIndex 7
globalvar CurrentObjective 8
globalvar RemainingObjectiveIndices 9
globalvar ObjectiveRadius 10
globalvar StartImmediately 11
globalvar PreventGameFromEnding 12
globalvar CanContestedObjectivesBeCaptured 13
globalvar ChargingStationPosition 14
globalvar ChargingStationRadius 15
globalvar CapturedObjectives 16
globalvar CurrentShopPosition 17
globalvar AllBuffDescriptions 18
globalvar BuffIndicesInShop 19
globalvar PlayersToResurrect 20
globalvar PlayerToEvaluate 21
globalvar CurrentShopId 22
globalvar IsObjectiveVisible 23
globalvar PlayersWhoCapturedTheObjective 24
globalvar RestoreChargeTo 25
globalvar PlayersInTheObjectiveWhenCapture 26
globalvar MaximumObjectiveCaptureRate 27
globalvar ObjectiveCountdownSound 28
globalvar TemporarySanctuaryPosition 29
globalvar UpgradeChoiceButtons 30
globalvar AllBuffInternalNames 31
globalvar AllBuffNames 32
globalvar j 33
globalvar LogDamageUpgradeDiagnostics 34
globalvar EnableTestingControls 35
globalvar NextTelemetryPlayerId 36

#Player variables

# Movement / traversal
playervar CrouchCounter 0
playervar MantleState 1
playervar MantleTimer 2
playervar TryingToMantle 3
playervar CanDashJump 4
playervar IsDashJumping 5
playervar JumpCharge 6

# Objective / sanctuary / respawn state
playervar ObjectiveCaptureFraction 7
playervar IsCapturingObjective 8
playervar IsOnChargingStation 9
playervar IsInSanctuary 10
playervar RespawnAtTemporarySanctuary 11
playervar RespawnTimer 12
playervar LastObjectiveCountdownSound 13

# Charge / resource system
playervar Charge 14
playervar MaximumCharge 15
playervar RechargePerTick 16
playervar Ability2ChargeCost 17
playervar Ability1ChargeCost 18
playervar JumpChargeCost 19
playervar AmmoChargeCost 20
playervar MeleeChargeCost 21
playervar UltimateChargeCost 22
playervar SecondaryChargeCost 23
playervar MaxAmmo 24
playervar LowChargeWarningActive 25

# Combat / regeneration tuning
playervar AccxmulatedHealing 26
playervar RegenMultiplier 27
playervar FireRate 28

# Upgrades / shop
playervar CountOfEachBuff 29
playervar HasBoughtFromShop 30
playervar IsInShop 31
playervar IsSelectingUpgrade 32
playervar SelectedShopIndex 33

# Joyride Impact state
playervar JoyrideImpactVictims 34
playervar JoyrideImpactExpiryTimes 35
playervar ExpiredJoyrideImpactIndex 36

# Scripted damage dispatcher
playervar ScriptedDamageQueueVictims 37
playervar ScriptedDamageQueueAmounts 38
playervar ScriptedDamageQueueSources 39
playervar ScriptedDamageAttribUpgradeIds 40
playervar ScriptedDamageAttribAmounts 41
playervar ActiveScriptedDamageSource 42
playervar ActiveScriptedDamageVictim 43

# Telemetry identity / aggregate combat counters
playervar TelemetryPlayerId 44
playervar NativeDamageByAttackType 45
playervar NativeHitCountsByAttackType 46
playervar OtherNativeDamage 47
playervar OtherNativeHitCount 48
playervar ScriptedBonusDamageBySource 49
playervar FinalBlowCount 50
playervar DamageUpgradeActivationCounts 51
playervar DamageUpgradePureDamage 52
playervar DamageUpgradeTargetMaxHpSum 53

# Test / debug
playervar TestSelectedUpgrade 54

# Subroutine names

subroutine ChooseObjective 0
subroutine CreateDebugEffectsAndHUD 1
subroutine TrySpawnNewShop 2
subroutine ResurrectMe 3
subroutine SetMaximumCharge 4
subroutine BuySelectedUpgrade 5
subroutine UpdateMoveSpeed 6
subroutine InitialiseTelemetry 7
subroutine InitialiseCombatState 8
subroutine InitialiseChargeSystem 9
subroutine InitialisePlayerSystems 10
subroutine InitialisePlayerHUDAndEffects 11

#Activated extensions

#!extension playMoreEffects


#Only remove the following directive if the gamemode does not use tricks such as A+0, A*0, A or "", "am" == "**", etc which would otherwise be optimized out.
#!optimizeStrict

#!setupTags

enum ScriptedDamageSource:
    NONE = 0
    PRIMARY_BONUS
    MELEE_BONUS
    JOYRIDE_BONUS

macro NativeAttackAbilities = [
    Button.PRIMARY_FIRE,
    Button.SECONDARY_FIRE,
    Button.ABILITY_1,
    Button.ABILITY_2,
    Button.ULTIMATE,
    Button.MELEE
]

macro TelemetryEscape(value):
    (
        "{}".format(value)
        .replace("%", "%25")
        .replace("|", "%7C")
        .replace("=", "%3D")
        .replace("\n", "%0A")
        .replace("\r", "%0D")
    )

macro IsNativeDamage(ability):
    ability != null

macro IsClassifiedScriptedDamage(ability, sourcePlayer, targetPlayer):
    (
        ability == null
        and sourcePlayer.ActiveScriptedDamageSource
            != ScriptedDamageSource.NONE
        and sourcePlayer.ActiveScriptedDamageVictim == targetPlayer
    )

macro ClassifiedScriptedDamageSource(
    ability,
    sourcePlayer,
    targetPlayer
):
    (
        sourcePlayer.ActiveScriptedDamageSource
        if (
            ability == null
            and sourcePlayer.ActiveScriptedDamageSource
                != ScriptedDamageSource.NONE
            and sourcePlayer.ActiveScriptedDamageVictim == targetPlayer
        )
        else ScriptedDamageSource.NONE
    )

macro IsScriptedBonusDamage(
    ability,
    sourcePlayer,
    targetPlayer,
    source
):
    (
        ability == null
        and sourcePlayer.ActiveScriptedDamageSource == source
        and sourcePlayer.ActiveScriptedDamageVictim == targetPlayer
    )

macro UpgradeIndex(internalName):
    AllBuffInternalNames.index(internalName)

macro OffObjectivePrimaryBonusFactor(player):
    (
        0.06
        * player.CountOfEachBuff[
            UpgradeIndex("OFF_OBJECTIVE_PRIMARY_DAMAGE")
        ]
        if not player.IsCapturingObjective
        else 0
    )

macro PrimaryVsMaxHealthBonusFactor(player, target):
    (
        0.000125
        * player.CountOfEachBuff[
            UpgradeIndex("PRIMARY_VS_MAX_HEALTH")
        ]
        * target.getMaxHealth()
    )

macro PrimaryBonusDamage(nativeDamage, player, target):
    (
        nativeDamage
        * (
            (
                1 + OffObjectivePrimaryBonusFactor(player)
            )
            * (
                1 + PrimaryVsMaxHealthBonusFactor(
                    player,
                    target
                )
            )
            - 1
        )
    )

macro Player.recordDamageUpgradeActivation(upgradeName, target):
    self.DamageUpgradeActivationCounts[UpgradeIndex(upgradeName)]++
    self.DamageUpgradeTargetMaxHpSum[UpgradeIndex(upgradeName)] += target.getMaxHealth()

macro Player.enqueueScriptedDamage(
    target,
    amount,
    source,
    attributionUpgradeIndices=[],
    attributionAmounts=[]
):
    self.ScriptedDamageQueueVictims.append(target)
    self.ScriptedDamageQueueAmounts.append(amount)
    self.ScriptedDamageQueueSources.append(source)

    self.ScriptedDamageAttribUpgradeIds = (
        self.ScriptedDamageAttribUpgradeIds.concat(
            [attributionUpgradeIndices]
        )
    )

    self.ScriptedDamageAttribAmounts = (
        self.ScriptedDamageAttribAmounts.concat(
            [attributionAmounts]
        )
    )

rule "Global Setup":
    LogDamageUpgradeDiagnostics = createWorkshopSettingBool(
        "Testing",
        "Log Damage Upgrade Diagnostics",
        false
    )
    EnableTestingControls = createWorkshopSettingBool(
        "Testing",
        "Enable Testing Controls",
        false
    )
    UpgradeChoiceButtons = [Button.PRIMARY_FIRE, Button.JUMP, Button.MELEE, Button.RELOAD, Button.ABILITY_1, Button.CROUCH]
    MaximumObjectiveCaptureRate = 1 / createWorkshopSettingInt("General", "Minimum Time To Capture Objective", 10, 1, 900)
    RestoreChargeTo = createWorkshopSettingInt("General", "Restore Charge To", 200, 0, 1000)
    StartImmediately = createWorkshopSettingBool("General", "Start Immediately", true)
    PreventGameFromEnding = createWorkshopSettingBool("General", "Prevent game from ending", false)
    CanContestedObjectivesBeCaptured = createWorkshopSettingBool("General", "Can Contested Objectives be Captured", true)
    ObjectiveRadius = createWorkshopSettingInt("General", "Objective Diameter", 19, 2, 40) * 0.5
    CurrentObjectiveIndex = -1
    disableScoring()
    createEffect(getAllPlayers() if CurrentObjective else null, Effect.LIGHT_SHAFT, Color.TURQUOISE if IsObjectiveUnlocked else Color.GRAY, CurrentObjective + 20 * Vector.DOWN, ObjectiveRadius)
    createIcon(getAllPlayers() if IsObjectiveVisible else null, CurrentObjective + 1.9 * Vector.UP, Icon.ARROW_DOWN, IconReeval.VISIBILITY_POSITION_AND_COLOR, Color.TURQUOISE if IsObjectiveUnlocked else [30 * sinDeg(300 * getTotalTimeElapsed()) + 170].map(lambda x: rgb(x, x, x)))
    createEffect(
        getAllPlayers() if TemporarySanctuaryPosition else null,
        Effect.LIGHT_SHAFT,
        Color.WHITE,
        TemporarySanctuaryPosition + 20 * Vector.DOWN,
        ObjectiveRadius,
        EffectReeval.VISIBILITY_POSITION_AND_RADIUS
    )
    createIcon(
        getAllPlayers() if TemporarySanctuaryPosition else null,
        TemporarySanctuaryPosition + 1.9 * Vector.UP,
        Icon.HALO,
        IconReeval.VISIBILITY_AND_POSITION,
        Color.WHITE,
        false
    )
    if PreventGameFromEnding:
        disableGamemodeCompletion()
    if StartImmediately:
        while not isGameInProgress():
            startGamemode()
            wait(1)
    waitUntil(isGameInProgress(), 99999)
    setMatchTime(900)
    disableAnnouncer()
    hudSubtext(getAllPlayers(), "Controls", HudPosition.LEFT, -1, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudSubheader(getAllPlayers(), "{0}\n{1}".format("[{0}] twice in air — Dash Down\n[{1}] during Ground Dash — Dash Jump".format(inputBindingString(Button.CROUCH), inputBindingString(Button.JUMP)), "[{0}] near a ledge — Mantle\nHold [{1}] while bike on ground — Brake + Charge Super Jump\nEarly Respawn with [{0}] Disabled".format(inputBindingString(Button.JUMP), inputBindingString(Button.CROUCH))), HudPosition.LEFT, 0, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    
    hudSubtext(
        getAllPlayers(),
        "\nCapture Progress",
        HudPosition.LEFT,
        1,
        Color.WHITE if IsObjectiveUnlocked else Color.LIGHT_GRAY,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    for i in range(12):
        hudSubheader(
            getAllPlayers(),
            CapturingPlayers[evalOnce(i)].map(
                lambda x: "{0}  {1} {2}%".format(
                    heroIcon(x.getHero()),
                    x,
                    floor(100 * x.ObjectiveCaptureFraction)
                )
            ) if CapturingPlayers[evalOnce(i)] else " ",
            HudPosition.LEFT,
            2 + evalOnce(i),
            Color.WHITE,
            HudReeval.VISIBILITY_AND_STRING
        )

    if PreventGameFromEnding:
        disableMusic()
    createEffect(getAllPlayers(), Effect.LIGHT_SHAFT, Color.YELLOW, ChargingStationPosition + 20 * Vector.DOWN, ChargingStationRadius, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createIcon(getAllPlayers(), ChargingStationPosition + 1.9 * Vector.UP, Icon.BOLT, IconReeval.VISIBILITY_AND_POSITION, Color.WHITE)
    ChargingStationRadius = 9.5
    createEffect(getAllPlayers().filter(lambda player: not player.HasBoughtFromShop) if CurrentShopPosition else null, Effect.LIGHT_SHAFT, Color.GREEN, CurrentShopPosition + 20 * Vector.DOWN, ObjectiveRadius, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createIcon(getAllPlayers().filter(lambda player: not player.HasBoughtFromShop) if CurrentShopPosition else null, CurrentShopPosition + 1.9 * Vector.UP, Icon.QUESTION_MARK, IconReeval.VISIBILITY_AND_POSITION, Color.LIME_GREEN)
    AllBuffInternalNames = [
        "MAX_HEALTH",
        "OFF_OBJECTIVE_PRIMARY_DAMAGE",
        "JOYRIDE_IMPACT",
        "RESTORE_ON_ELIMINATION",
        "IMPROVED_SUPER_JUMP",
        "PRIMARY_VS_MAX_HEALTH",
        "SECONDARY_KNOCKBACK",
        "MELEE_LIFESTEAL",
        "MELEE_DAMAGE"
    ]
    AllBuffDescriptions = [
        c"Increase your maximum health.",
        c"Increase Primary Fire damage while you are not contesting the objective.",
        c"Enemies damaged by Joyride temporarily take increased damage from you.",
        c"Eliminations restore health and reduce your remaining ability cooldowns.",
        c"Charge Super Jump faster.",
        c"Primary Fire deals more damage to enemies with higher maximum health.",
        c"Increase Secondary Fire knockback.",
        c"Heal for a portion of the damage dealt by Quick Melee.",
        c"Increase Quick Melee damage."
    ]
    AllBuffNames = [
        "MAX HEALTH",
        "Off-Objective {0} Damage".format(
            abilityIconString(Hero.SHION, Button.PRIMARY_FIRE)
        ),
        "{0} Impact".format(
            abilityIconString(Hero.SHION, Button.ABILITY_2)
        ),
        "RESTORE ON ELIMINATION",
        "IMPROVED SUPER JUMP",
        "{0} vs Max Health".format(
            abilityIconString(Hero.SHION, Button.PRIMARY_FIRE)
        ),
        "{0} Knockback".format(
            abilityIconString(Hero.SHION, Button.SECONDARY_FIRE)
        ),
        "Melee Lifesteal",
        "Melee Damage"
    ]

rule "Initialise":
    @Event eachPlayer
    @Condition eventPlayer.TelemetryPlayerId == 0
    @Condition eventPlayer.hasSpawned() == true

    InitialiseTelemetry()
    InitialiseCombatState()
    InitialiseChargeSystem()
    InitialisePlayerSystems()
    InitialisePlayerHUDAndEffects()


def InitialiseTelemetry():
    NextTelemetryPlayerId++
    eventPlayer.TelemetryPlayerId = NextTelemetryPlayerId

    logToInspector(
        "SFFA|v=1|t={0}|e=PLAYER_MAP|pid={1}|name={2}".format(
            getTotalTimeElapsed(),
            eventPlayer.TelemetryPlayerId,
            TelemetryEscape(eventPlayer)
        )
    )

    eventPlayer.NativeDamageByAttackType = NativeAttackAbilities.map(lambda _: 0)
    eventPlayer.NativeHitCountsByAttackType = NativeAttackAbilities.map(lambda _: 0)

    eventPlayer.OtherNativeDamage = 0
    eventPlayer.OtherNativeHitCount = 0

    eventPlayer.ScriptedBonusDamageBySource = ScriptedDamageSource.toArray().map(lambda _: 0)

    eventPlayer.DamageUpgradeActivationCounts = AllBuffInternalNames.map(lambda _: 0)
    eventPlayer.DamageUpgradePureDamage = AllBuffInternalNames.map(lambda _: 0)
    eventPlayer.DamageUpgradeTargetMaxHpSum = AllBuffInternalNames.map(lambda _: 0)

    eventPlayer.FinalBlowCount = 0

    eventPlayer.ScriptedDamageQueueVictims = []
    eventPlayer.ScriptedDamageQueueAmounts = []
    eventPlayer.ScriptedDamageQueueSources = []

    eventPlayer.ScriptedDamageAttribUpgradeIds = []
    eventPlayer.ScriptedDamageAttribAmounts = []

    eventPlayer.ActiveScriptedDamageSource = ScriptedDamageSource.NONE
    eventPlayer.ActiveScriptedDamageVictim = null


def InitialiseCombatState():
    # Max Ammo does not work on Shion
    eventPlayer.MaxAmmo = 18

    # Shots per second
    eventPlayer.FireRate = 4

    eventPlayer.RechargePerTick = 0.088

    eventPlayer.Ability2ChargeCost = 150
    eventPlayer.Ability1ChargeCost = 30
    eventPlayer.AmmoChargeCost = 9
    eventPlayer.MeleeChargeCost = 10
    eventPlayer.UltimateChargeCost = 270
    eventPlayer.SecondaryChargeCost = 14 * eventPlayer.AmmoChargeCost


def InitialiseChargeSystem():
    SetMaximumCharge()
    eventPlayer.Charge = eventPlayer.MaximumCharge

    chaseAtRate(
        eventPlayer.RegenMultiplier,
        min(1, 0.1 + 0.06 * eventPlayer.Charge),
        100
    )

    startHealingModification(
        eventPlayer,
        eventPlayer,
        100 * eventPlayer.RegenMultiplier
    )


def InitialisePlayerSystems():
    eventPlayer.disableRespawn()

    eventPlayer.LastObjectiveCountdownSound = ObjectiveCountdownSound

    chaseAtRate(eventPlayer.MantleTimer, 0, 1, ChaseRateReeval.NONE)

    chaseAtRate(
        eventPlayer.ObjectiveCaptureFraction,
        1,
        MaximumObjectiveCaptureRate / max(1, len(getAllPlayers().filter(lambda player: player.IsCapturingObjective))) if eventPlayer.IsCapturingObjective else 0
    )

    chaseAtRate(eventPlayer.RespawnTimer, 0, 1, ChaseRateReeval.NONE)


def InitialisePlayerHUDAndEffects():
    # CreateDebugEffectsAndHUD()

    # Doesn't use localPlayer as I want to be able to see it in replays
    progressBarHud(
        eventPlayer,
        100 * (eventPlayer.Charge / eventPlayer.MaximumCharge),
        l"{0} / {1}".format(round(eventPlayer.Charge), eventPlayer.MaximumCharge),
        HudPosition.RIGHT,
        -100,
        rgb(
            200 if eventPlayer.Charge < RestoreChargeTo else
            200 + 36 * ((eventPlayer.Charge - RestoreChargeTo) / RestoreChargeTo) if eventPlayer.Charge < 2 * RestoreChargeTo else
            236 + 19 * min(1, (eventPlayer.Charge - 2 * RestoreChargeTo) / RestoreChargeTo),

            0 if eventPlayer.Charge < RestoreChargeTo else
            153 * ((eventPlayer.Charge - RestoreChargeTo) / RestoreChargeTo) if eventPlayer.Charge < 2 * RestoreChargeTo else
            153 + 102 * min(1, (eventPlayer.Charge - 2 * RestoreChargeTo) / RestoreChargeTo),

            19 if eventPlayer.Charge < RestoreChargeTo else
            19 - 19 * ((eventPlayer.Charge - RestoreChargeTo) / RestoreChargeTo) if eventPlayer.Charge < 2 * RestoreChargeTo else
            255 * min(1, (eventPlayer.Charge - 2 * RestoreChargeTo) / RestoreChargeTo)
        )
    )

    createEffect(
        getAllPlayers().filter(lambda player: eventPlayer in player.JoyrideImpactVictims),
        Effect.BAD_AURA,
        Color.PURPLE,
        eventPlayer.getEyePosition(),
        0.85,
        EffectReeval.VISIBILITY_POSITION_AND_RADIUS
    )

    createEffect(
        getAllPlayers().filter(lambda player: eventPlayer in player.JoyrideImpactVictims),
        Effect.SPHERE,
        Color.PURPLE,
        eventPlayer.getEyePosition() + 0.5 * Vector.UP,
        0.15,
        EffectReeval.VISIBILITY_POSITION_AND_RADIUS
    )


rule "Local UX Setup":
    @Condition len(AllBuffNames) > 1

    progressBarHud(localPlayer if localPlayer.IsCapturingObjective else null, localPlayer.ObjectiveCaptureFraction * 100, l"Capturing", HudPosition.TOP, 10)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsCapturingObjective else null, Effect.PICKUP_SOUND, Color.WHITE, localPlayer, 40 + localPlayer.ObjectiveCaptureFraction * 60, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(localPlayer if localPlayer.IsInSanctuary else null, Effect.SPARKLES_SOUND, Color.WHITE, localPlayer, 80, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createInWorldText(localPlayer if IsObjectiveVisible and distance(localPlayer, CurrentObjective) > ObjectiveRadius + 5 else null, l"{0} m".format(round(distance(localPlayer, CurrentObjective))), CurrentObjective + 2 * Vector.UP, 1.5, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, rgb(200, 200, 200, 127))
    createInWorldText(localPlayer if ChargingStationPosition and distance(localPlayer, ChargingStationPosition) > ChargingStationRadius + 5 else null, l"{0} m".format(round(distance(localPlayer, ChargingStationPosition))), ChargingStationPosition + 2 * Vector.UP, 1.5, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, rgb(200, 200, 200, 127))
    createInWorldText(localPlayer if CurrentShopPosition and not localPlayer.HasBoughtFromShop and distance(localPlayer, CurrentShopPosition) > ObjectiveRadius + 5 else null, l"{0} m".format(round(distance(localPlayer, CurrentShopPosition))), CurrentShopPosition + 2 * Vector.UP, 1.5, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_AND_STRING, rgb(200, 200, 200, 127))
    createEffect(localPlayer if localPlayer.IsOnChargingStation and localPlayer.Charge < localPlayer.MaximumCharge else null, Effect.ENERGY_SOUND, Color.WHITE, localPlayer, 100, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    hudText(
        localPlayer,
        abilityIconString(localPlayer.getHero(), Button.PRIMARY_FIRE),
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.AmmoChargeCost
        ),
        [
            " <fg6CBEF4FF>+DMG</fg>"
            if localPlayer.CountOfEachBuff[1] > 0 and not localPlayer.IsCapturingObjective
            else ""
        ].map(
            lambda suffix:
                "Sanctuary" if localPlayer.IsInSanctuary else
                "Firing{0}".format(suffix) if localPlayer.isFiringPrimaryFire() else
                "Not enough charge" if localPlayer.Charge < localPlayer.AmmoChargeCost else
                "Reloading{0}".format(suffix) if localPlayer.isReloading() else
                abilityIconString(Hero.SHION, Button.ULTIMATE) if localPlayer.isUsingUltimate() else
                "Riding{0}".format(suffix) if localPlayer.isUsingAbility2() else
                "Ready{0}".format(suffix)
        )[0],
        HudPosition.RIGHT,
        -99,
        Color.GRAY if localPlayer.IsInSanctuary else
        Color.ORANGE if localPlayer.isFiringPrimaryFire() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.AmmoChargeCost else
        Color.GRAY if (
            localPlayer.isReloading()
            or localPlayer.isUsingUltimate()
            or localPlayer.isUsingAbility2()
        ) else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.GRAY if localPlayer.IsInSanctuary else
        Color.ORANGE if localPlayer.isFiringPrimaryFire() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.AmmoChargeCost else
        Color.GRAY if (
            localPlayer.isReloading()
            or localPlayer.isUsingUltimate()
            or localPlayer.isUsingAbility2()
        ) else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    hudText(
        localPlayer,
        abilityIconString(localPlayer.getHero(), Button.SECONDARY_FIRE),
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.SecondaryChargeCost
        ),
        "Sanctuary" if localPlayer.IsInSanctuary else
        "Firing" if localPlayer.isFiringSecondaryFire() else
        "Not enough charge" if localPlayer.Charge < localPlayer.SecondaryChargeCost else
        ceil(localPlayer.getAbilityCooldown(Button.SECONDARY_FIRE)) if localPlayer.getAbilityCooldown(Button.SECONDARY_FIRE) else
        abilityIconString(Hero.SHION, Button.ULTIMATE) if localPlayer.isUsingUltimate() else
        "Riding" if localPlayer.isUsingAbility2() else
        "Ready",
        HudPosition.RIGHT,
        -98,
        Color.GRAY if localPlayer.IsInSanctuary else
        Color.ORANGE if localPlayer.isFiringSecondaryFire() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.SecondaryChargeCost else
        Color.GRAY if (
            localPlayer.getAbilityCooldown(Button.SECONDARY_FIRE)
            or localPlayer.isUsingUltimate()
            or localPlayer.isUsingAbility2()
        ) else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.GRAY if localPlayer.IsInSanctuary else
        Color.ORANGE if localPlayer.isFiringSecondaryFire() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.SecondaryChargeCost else
        Color.GRAY if (
            localPlayer.getAbilityCooldown(Button.SECONDARY_FIRE)
            or localPlayer.isUsingUltimate()
            or localPlayer.isUsingAbility2()
        ) else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    hudText(
        localPlayer,
        abilityIconString(localPlayer.getHero(), Button.ABILITY_1),
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.Ability1ChargeCost
        ),
        "Dashing" if localPlayer.isUsingAbility1() else
        "Not enough charge" if localPlayer.Charge < localPlayer.Ability1ChargeCost else
        ceil(localPlayer.getAbilityCooldown(Button.ABILITY_1)) if localPlayer.getAbilityCooldown(Button.ABILITY_1) else
        abilityIconString(Hero.SHION, Button.ULTIMATE) if localPlayer.isUsingUltimate() else
        "Ready",
        HudPosition.RIGHT,
        -97,
        Color.ORANGE if localPlayer.isUsingAbility1() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.Ability1ChargeCost else
        Color.GRAY if (
            localPlayer.getAbilityCooldown(Button.ABILITY_1)
            or localPlayer.isUsingUltimate()
        ) else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.ORANGE if localPlayer.isUsingAbility1() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.Ability1ChargeCost else
        Color.GRAY if (
            localPlayer.getAbilityCooldown(Button.ABILITY_1)
            or localPlayer.isUsingUltimate()
        ) else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    hudText(
        localPlayer,
        abilityIconString(localPlayer.getHero(), Button.ABILITY_2),
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.Ability2ChargeCost
        ),
        "Riding" if localPlayer.isUsingAbility2() else
        "Not enough charge" if localPlayer.Charge < localPlayer.Ability2ChargeCost else
        ceil(localPlayer.getAbilityCooldown(Button.ABILITY_2)) if localPlayer.getAbilityCooldown(Button.ABILITY_2) else
        abilityIconString(Hero.SHION, Button.ULTIMATE) if localPlayer.isUsingUltimate() else
        "Ready",
        HudPosition.RIGHT,
        -96,
        Color.ORANGE if localPlayer.isUsingAbility2() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.Ability2ChargeCost else
        Color.GRAY if (
            localPlayer.getAbilityCooldown(Button.ABILITY_2)
            or localPlayer.isUsingUltimate()
        ) else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.ORANGE if localPlayer.isUsingAbility2() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.Ability2ChargeCost else
        Color.GRAY if (
            localPlayer.getAbilityCooldown(Button.ABILITY_2)
            or localPlayer.isUsingUltimate()
        ) else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    hudText(
        localPlayer,
        abilityIconString(localPlayer.getHero(), Button.ULTIMATE),
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.UltimateChargeCost
        ),
        "Sanctuary" if localPlayer.IsInSanctuary else
        "Active" if localPlayer.isUsingUltimate() else
        "Not enough charge" if localPlayer.Charge < localPlayer.UltimateChargeCost else
        l"{0}%".format(localPlayer.getUltCharge()) if localPlayer.getUltCharge() < 100 else
        "Ready",
        HudPosition.RIGHT,
        -95,
        Color.GRAY if localPlayer.IsInSanctuary else
        Color.ORANGE if localPlayer.isUsingUltimate() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.UltimateChargeCost else
        Color.GRAY if localPlayer.getUltCharge() < 100 else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.GRAY if localPlayer.IsInSanctuary else
        Color.ORANGE if localPlayer.isUsingUltimate() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.UltimateChargeCost else
        Color.GRAY if localPlayer.getUltCharge() < 100 else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    hudText(
        localPlayer,
        "Melee",
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.MeleeChargeCost
        ),
        "Attacking" if localPlayer.isMeleeing() else
        "Not enough charge" if localPlayer.Charge < localPlayer.MeleeChargeCost else
        abilityIconString(Hero.SHION, Button.ULTIMATE) if localPlayer.isUsingUltimate() else
        "Riding" if localPlayer.isUsingAbility2() else
        "Ready",
        HudPosition.RIGHT,
        -94,
        Color.ORANGE if localPlayer.isMeleeing() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.MeleeChargeCost else
        Color.GRAY if (
            localPlayer.isUsingUltimate()
            or localPlayer.isUsingAbility2()
        ) else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.ORANGE if localPlayer.isMeleeing() else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.MeleeChargeCost else
        Color.GRAY if (
            localPlayer.isUsingUltimate()
            or localPlayer.isUsingAbility2()
        ) else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )

    hudText(
        localPlayer,
        l"Jump",
        "{0} {1}".format(
            iconString(Icon.BOLT),
            localPlayer.JumpChargeCost
        ),
        "Jumping" if localPlayer.isJumping() or localPlayer.IsDashJumping else
        "Not enough charge" if localPlayer.Charge < localPlayer.JumpChargeCost else
        "Ready",
        HudPosition.RIGHT,
        -93,
        Color.ORANGE if (
            localPlayer.isJumping()
            or localPlayer.IsDashJumping
        ) else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.JumpChargeCost else
        Color.WHITE,
        rgb(191, 191, 191),
        Color.ORANGE if (
            localPlayer.isJumping()
            or localPlayer.IsDashJumping
        ) else
        Color.LIGHT_RED if localPlayer.Charge < localPlayer.JumpChargeCost else
        Color.WHITE,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )
    createInWorldText(localPlayer if localPlayer.JumpCharge > 0 else null, ["O\nO\nO\nO\nO", "O\nO\nO\nO\nX", "O\nO\nO\nX\nX", "O\nO\nX\nX\nX", "O\nX\nX\nX\nX", "X\nX\nX\nX\nX"][min(5, floor(localPlayer.JumpCharge * 5))], updateEveryFrame(localPlayer.getEyePosition() + 0.3 * Vector.UP), 1.5, Clip.NONE, WorldTextReeval.VISIBILITY_POSITION_STRING_AND_COLOR, rgb(220, 250, 255) if localPlayer.JumpCharge >= 1 else rgb(85 - 35 * localPlayer.JumpCharge, 115 + 100 * localPlayer.JumpCharge, 180 + 75 * localPlayer.JumpCharge, 130 + 125 * localPlayer.JumpCharge))
    hudText(localPlayer if localPlayer.isDead() else null, ceil(localPlayer.RespawnTimer), "SECONDS UNTIL AUTO-RESPAWN", "OBJECTIVE CAPTURE ALSO REVIVES YOU", HudPosition.TOP, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(
        localPlayer if localPlayer.IsInShop and not localPlayer.HasBoughtFromShop and not localPlayer.IsSelectingUpgrade else null,
        "[{0}]".format(inputBindingString(Button.INTERACT)),
        null,
        "SELECT UPGRADE",
        HudPosition.TOP,
        10,
        Color.ORANGE,
        Color.WHITE,
        Color.WHITE,
        HudReeval.VISIBILITY_AND_STRING
    )

    hudSubtext(
        localPlayer,
        "\nUpgrades",
        HudPosition.LEFT,
        14,
        Color.WHITE if len(localPlayer.CountOfEachBuff.filter(lambda x: x > 0)) > 0 else Color.LIGHT_GRAY,
        HudReeval.VISIBILITY_STRING_AND_COLOR
    )
    
    for i in range(len(UpgradeChoiceButtons)):
        hudText(
            localPlayer if localPlayer.IsSelectingUpgrade and len(BuffIndicesInShop) >= evalOnce(i + 1) else null,
            inputBindingString(evalOnce(UpgradeChoiceButtons[i])),
            AllBuffDescriptions[BuffIndicesInShop[evalOnce(i)]],
            AllBuffNames[BuffIndicesInShop[evalOnce(i)]],
            HudPosition.TOP,
            10 + i,
            Color.WHITE,
            Color.WHITE,
            Color.ORANGE if localPlayer.SelectedShopIndex == evalOnce(i) else Color.WHITE,
            HudReeval.VISIBILITY_STRING_AND_COLOR
        )

    for i in range(len(AllBuffNames)):
        hudText(
            localPlayer,
            null,
            "{0} ×{1}".format(
                evalOnce(AllBuffNames[i]),
                localPlayer.CountOfEachBuff[evalOnce(i)]
            ),
            null,
            HudPosition.LEFT,
            15 + evalOnce(i),
            Color.WHITE,
            Color.WHITE if localPlayer.CountOfEachBuff[evalOnce(i)] > 0 else Color.GRAY,
            Color.WHITE,
            HudReeval.VISIBILITY_STRING_AND_COLOR
        )


rule "Reset Crouch Counter":
    @Event eachPlayer
    @Condition eventPlayer.CrouchCounter == 1
    
    wait(0.44, Wait.ABORT_WHEN_FALSE)
    eventPlayer.CrouchCounter = 0


rule "Reset Crouch Counter & Gravity on ground":
    @Event eachPlayer
    @Condition eventPlayer.isOnGround() == true
    
    eventPlayer.IsDashJumping = false
    eventPlayer.CrouchCounter = 0
    eventPlayer.setGravity(100)
    eventPlayer.setJumpVerticalSpeed(100)


rule "While not on bike":
    @Event eachPlayer
    @Condition (eventPlayer.isUsingAbility2() and eventPlayer.getHero() == Hero.SHION) == false
    
    eventPlayer.JumpChargeCost = 1
    eventPlayer.setGravity(100)
    eventPlayer.setJumpVerticalSpeed(100)


rule "Mantle - Initiate":
    @Event eachPlayer
    @Condition eventPlayer.getHero() == Hero.SHION
    @Condition eventPlayer.isUsingAbility1() == false
    @Condition eventPlayer.isUsingAbility2() == false
    @Condition eventPlayer.isHoldingButton(Button.JUMP) == true
    @Condition eventPlayer.getThrottle().z > 0.5
    @Condition distance(worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true)) < 1.4
    @Condition distance(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true)) > 1.5
    
    eventPlayer.TryingToMantle = true
    wait()
    if ruleCondition:
        loop()
    eventPlayer.TryingToMantle = false
    eventPlayer.MantleTimer = 0


rule "Mantle - Initiate":
    @Event eachPlayer
    @Condition eventPlayer.TryingToMantle == true
    @Condition eventPlayer.MantleState == 0
    
    eventPlayer.MantleState = 1
    eventPlayer.MantleTimer = 0.2


rule "Mantle - Movement":
    @Event eachPlayer
    @Condition eventPlayer.MantleState == 1
    
    eventPlayer.startForcingThrottle(0, 1, 0, 1, 0, 0)
    while eventPlayer.MantleTimer > 0:
        eventPlayer.applyImpulse(Vector.UP, max(0, 6.33 - eventPlayer.getVerticalSpeed()), Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
        wait()
    eventPlayer.stopForcingThrottle()
    eventPlayer.MantleState = 2


rule "Mantle - Terminate":
    @Event eachPlayer
    @Condition eventPlayer.MantleState == 1
    @Condition distance(worldVector(vect(0, 0.25, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 0.25, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 0.25, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true)) > 1.5
    @Condition distance(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true)) > 1.5
    
    eventPlayer.MantleTimer = 0


rule "Mantle - Reset":
    @Event eachPlayer
    @Condition eventPlayer.MantleState == 2
    @Condition eventPlayer.isOnGround() == true
    
    eventPlayer.MantleState = 0


rule "Teleport Dummy To Initial Objective":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == true
    @Condition CurrentObjective != null
    @Condition distance(eventPlayer, CurrentObjective) > ObjectiveRadius

    eventPlayer.teleport(CurrentObjective)
    wait(1)

    if ruleCondition:
        loop()


rule "Set Objective Positions":
    @Condition getCurrentGamemode() == Gamemode.FFA
    @Condition ObjectiveRadius > 0
    @Condition ChargingStationRadius > 0
    
    ObjectivePositions = getSpawnPoints(Team.ALL).map(lambda x: x.getPosition())
    ChargingStationPosition = random.choice(ObjectivePositions)
    if createWorkshopSettingBool("Testing", "Spawn Dummy Bot", false):
        createDummy(Hero.SHION, Team.ALL, 1, ChargingStationPosition, Vector.FORWARD)

    #Keep objectives sufficiently far from the charging station
    ObjectivePositions = ObjectivePositions.filter(
        lambda x:
            distance(
                vect(x.x, 0, x.z),
                vect(ChargingStationPosition.x, 0, ChargingStationPosition.z)
            ) + ObjectiveRadius - ChargingStationRadius > 30
    )
    RemainingObjectiveIndices = ObjectivePositions.map(lambda _, i_: i_)


def UpdateMoveSpeed():
    @Name "Update Move Speed"

    eventPlayer.setMoveSpeed(
        100 * (
            (
                (0.6 if eventPlayer.IsSelectingUpgrade else 1)
                * (0.6 if eventPlayer.isOnGround() and eventPlayer.isHoldingButton(Button.CROUCH) else 1)
            )
            if eventPlayer.isUsingAbility2()
            else 1
        )
    )

    
def ChooseObjective():
    @Name "Choose Objective"
    
    AllowedObjectiveIndices = RemainingObjectiveIndices.map(lambda x: x)
    if CurrentObjectiveIndex > -1:
        PreviousObjective = ObjectivePositions[CurrentObjectiveIndex]
        AllowedObjectiveIndices = AllowedObjectiveIndices.filter(lambda x: magnitude(vect((ObjectivePositions[x] - PreviousObjective).x, 0, (ObjectivePositions[x] - PreviousObjective).z)) > 2 * ObjectiveRadius)
    if CurrentShopPosition:
        AllowedObjectiveIndices = AllowedObjectiveIndices.filter(lambda x: magnitude(vect((ObjectivePositions[x] - CurrentShopPosition).x, 0, (ObjectivePositions[x] - CurrentShopPosition).z)) > 2 * ObjectiveRadius)
    if len(AllowedObjectiveIndices) == 0:
        RemainingObjectiveIndices = ObjectivePositions.map(lambda _, i_: i_)
        wait()
        loop()
    CurrentObjectiveIndex = random.choice(AllowedObjectiveIndices)
    RemainingObjectiveIndices.remove(CurrentObjectiveIndex)
    CurrentObjective = ObjectivePositions[CurrentObjectiveIndex]
    getAllPlayers().filter(lambda player: player.isDummy()).teleport(CurrentObjective)


rule "Choose And Unlock New Objective":
    @Condition isGameInProgress() == true
    @Condition CurrentObjective == null
    
    IsObjectiveVisible = false
    IsObjectiveUnlocked = false
    TrySpawnNewShop()
    ChooseObjective()
    ObjectiveUnlockTime = getTotalTimeElapsed() + max(createWorkshopSettingInt("General", "Minimum Time Between Objectives", 11, 0, 50), 4 + (distance(CurrentObjective, PreviousObjective) / 13 + 1 if PreviousObjective else 0))
    setObjectiveDescription(getAllPlayers(), "Next Objective Unlocks In {0}".format(max(0, ObjectiveUnlockTime - getTotalTimeElapsed())), HudReeval.VISIBILITY_AND_STRING)
    wait(4)
    IsObjectiveVisible = true
    
    waitUntil(getTotalTimeElapsed() >= ObjectiveUnlockTime - 3, 99999)
    ObjectiveCountdownSound++

    waitUntil(getTotalTimeElapsed() >= ObjectiveUnlockTime - 2, 99999)
    ObjectiveCountdownSound++

    waitUntil(getTotalTimeElapsed() >= ObjectiveUnlockTime - 1, 99999)
    ObjectiveCountdownSound++

    waitUntil(getTotalTimeElapsed() >= ObjectiveUnlockTime, 99999)
    if not isGameInProgress():
        return
    setObjectiveDescription(getAllPlayers(), "Capture The Objective", HudReeval.VISIBILITY_AND_STRING)
    TemporarySanctuaryPosition = null
    IsObjectiveUnlocked = true

rule "Objective Nearly Unlocked Sound":
    @Event eachPlayer
    @Condition ObjectiveCountdownSound > eventPlayer.LastObjectiveCountdownSound

    eventPlayer.LastObjectiveCountdownSound = ObjectiveCountdownSound
    playEffect(
        eventPlayer,
        DynamicEffect.BUFF_EXPLOSION_SOUND,
        Color.WHITE,
        eventPlayer,
        80
    )


rule "Capture Objective":
    @Condition (getAllPlayers().any(lambda player: player.IsCapturingObjective and player.ObjectiveCaptureFraction >= 1)) == true
    @Condition (CanContestedObjectivesBeCaptured or len(getLivingPlayers(Team.ALL).filter(lambda player: player.IsCapturingObjective)) == 1) == true
    
    PlayersInTheObjectiveWhenCapture = getLivingPlayers(Team.ALL).filter(lambda player: player.IsCapturingObjective)
    for i in range(len(PlayersInTheObjectiveWhenCapture)):
        heal(PlayersInTheObjectiveWhenCapture[i], null, PlayersInTheObjectiveWhenCapture[i].getMaxHealth() / len(PlayersInTheObjectiveWhenCapture))
    getAllPlayers().filter(lambda player: player.IsCapturingObjective).Charge max= RestoreChargeTo
    IsObjectiveUnlocked = false
    PlayersWhoCapturedTheObjective = getLivingPlayers(Team.ALL).filter(lambda player: player.IsCapturingObjective and player.ObjectiveCaptureFraction >= 1)
    PlayersWhoCapturedTheObjective.addToScore(1)
    TemporarySanctuaryPosition = CurrentObjective
    PlayersToResurrect = getDeadPlayers(Team.ALL)
    bigMessage(PlayersWhoCapturedTheObjective, "Objective Secured")
    bigMessage(getAllPlayers().exclude(PlayersWhoCapturedTheObjective), "Objective Lost")
    if len(PlayersWhoCapturedTheObjective) == 1:
        smallMessage(
            getAllPlayers(),
            "{0} captured the objective".format(
                PlayersWhoCapturedTheObjective[0]
            )
        )
    else:
        smallMessage(
            getAllPlayers(),
            "{0} players captured the objective".format(
                len(PlayersWhoCapturedTheObjective)
            )
        )
    CapturedObjectives++
    CurrentObjective = null
    getAllPlayers().ObjectiveCaptureFraction = 0
    PlayersToResurrect.RespawnAtTemporarySanctuary = true


rule "Shorter Hero Select":
    @Condition isAssemblingHeroes() == true
    
    setMatchTime(10)


rule "Objective Unlock Sound":
    @Event eachPlayer
    @Condition IsObjectiveUnlocked == true
    
    playEffect(eventPlayer, DynamicEffect.BUFF_IMPACT_SOUND, Color.WHITE, eventPlayer, 100)


rule "Player Is Capturing Objective":
    @Event eachPlayer
    @Condition IsObjectiveUnlocked == true
    @Condition distance(vect(eventPlayer.getPosition().x, 0, eventPlayer.getPosition().z), vect(CurrentObjective.x, 0, CurrentObjective.z)) < ObjectiveRadius
    @Condition eventPlayer.getPosition().y > CurrentObjective.y - 20
    @Condition eventPlayer.getPosition().y < CurrentObjective.y + 10
    @Condition eventPlayer.isAlive() == true
    
    eventPlayer.IsCapturingObjective = true


rule "Player Outside of Objective Radius":
    @Event eachPlayer
    @Condition distance(vect(eventPlayer.getPosition().x, 0, eventPlayer.getPosition().z), vect(CurrentObjective.x, 0, CurrentObjective.z)) >= ObjectiveRadius
    
    eventPlayer.IsCapturingObjective = false


rule "Vertically outside of the zone":
    @Event eachPlayer
    @Condition (eventPlayer.getPosition().y > CurrentObjective.y - 20 and eventPlayer.getPosition().y < CurrentObjective.y + 10) == false
    
    eventPlayer.IsCapturingObjective = false


def CreateDebugEffectsAndHUD():
    @Name "Debug"
    
    hudHeader(eventPlayer, eventPlayer.getThrottle(), HudPosition.RIGHT, 0, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(eventPlayer, "{0}".format(distance(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true))), null, "Upper Distance", HudPosition.TOP, 0, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(eventPlayer, "{0}".format(distance(worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true))), null, "1m Distance", HudPosition.TOP, 1, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(eventPlayer, "{0}".format(distance(worldVector(vect(0, 0.25, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 0.25, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 0.25, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true))), null, "0.25m Distance", HudPosition.TOP, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(eventPlayer, "{0}".format(eventPlayer.getVerticalSpeed()), null, "Vertical Speed", HudPosition.TOP, 3, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    createBeam(getAllPlayers(), Beam.GRAPPLE, worldVector(vect(0, 0.25, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 0.25, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), Color.WHITE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    hudText(eventPlayer, eventPlayer.getPosition(), null, "pos", HudPosition.TOP, 4, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    createBeam(getAllPlayers(), Beam.GRAPPLE, worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), Color.WHITE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.GRAPPLE, worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), Color.WHITE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    hudText(eventPlayer, "{0}".format(eventPlayer.getThrottle().z > 0.5), null, "Forward Input", HudPosition.TOP, 5, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(eventPlayer, "{0}".format(distance(worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1, 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1, 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true)) < 1.4), null, "1m Ray Condition", HudPosition.TOP, 6, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)
    hudText(eventPlayer, "{0}".format(distance(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), raycastHitPosition(worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 0), eventPlayer, Transform.ROTATION_AND_TRANSLATION), worldVector(vect(0, 1.5 * (eventPlayer.getEyePosition().y - eventPlayer.getPosition().y), 2), eventPlayer, Transform.ROTATION_AND_TRANSLATION), null, eventPlayer, true)) > 1.5), null, "Upper Ray Condition", HudPosition.TOP, 7, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)


rule "Set Capturing Players":
    @Condition IsObjectiveUnlocked == true
    
    CapturingPlayers = sorted(getAllPlayers().filter(lambda player: player.ObjectiveCaptureFraction > 0.01), lambda x: x.ObjectiveCaptureFraction)
    wait(0.2, Wait.ABORT_WHEN_FALSE)
    if ruleCondition:
        loop()


rule "Objective Locked":
    @Condition IsObjectiveUnlocked == false
    
    getAllPlayers().IsCapturingObjective = false
    CapturingPlayers = []


rule "Player Died":
    @Event playerDied
    
    eventPlayer.IsDashJumping = false
    eventPlayer.disallowButton(Button.JUMP)
    eventPlayer.IsCapturingObjective = false
    eventPlayer.IsOnChargingStation = false
    eventPlayer.IsInSanctuary = false
    eventPlayer.JoyrideImpactVictims = []
    eventPlayer.JoyrideImpactExpiryTimes = []
    
    for i in range(getNumberOfSlots(Team.ALL)):
        PlayerToEvaluate = getPlayersInSlot(i, Team.ALL)[0]
    
        if PlayerToEvaluate:
            PlayerToEvaluate.ExpiredJoyrideImpactIndex = PlayerToEvaluate.JoyrideImpactVictims.index(eventPlayer)
    
            if PlayerToEvaluate.ExpiredJoyrideImpactIndex >= 0:
                del PlayerToEvaluate.JoyrideImpactVictims[
                    PlayerToEvaluate.ExpiredJoyrideImpactIndex
                ]
                del PlayerToEvaluate.JoyrideImpactExpiryTimes[
                    PlayerToEvaluate.ExpiredJoyrideImpactIndex
                ]


def TrySpawnNewShop():
    @Name "Try Spawn New Shop"
    
    if CapturedObjectives % 2 == 1:
        PreviousObjective = ObjectivePositions[CurrentObjectiveIndex]
        CurrentShopPosition = random.choice(ObjectivePositions.filter(lambda x: distance(vect(x.x, 0, x.z), vect(PreviousObjective.x, 0, PreviousObjective.z)) > ObjectiveRadius * 2))
        BuffIndicesInShop = random.shuffle(AllBuffDescriptions.map(lambda _, i_: i_)).slice(0, createWorkshopSettingInt("General", "Upgrades per Shop", 3, 1, 6))
        getAllPlayers().HasBoughtFromShop = false

        CurrentShopId++

        for j in range(len(BuffIndicesInShop)):
            logToInspector(
                "SFFA|v=1|t={0}|e=SHOP_OFFER|shop={1}|slot={2}|upgrade={3}".format(
                    getTotalTimeElapsed(),
                    CurrentShopId,
                    j,
                    AllBuffInternalNames[BuffIndicesInShop[j]]
                )
            )


rule "Player Is Alive":
    @Event eachPlayer
    @Condition eventPlayer.isAlive() == true
    
    eventPlayer.RespawnTimer = 0
    eventPlayer.allowButton(Button.JUMP)
    eventPlayer.Charge max= RestoreChargeTo


rule "Passive Recharge":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.MaximumCharge
    @Condition eventPlayer.isAlive() == true
    
    eventPlayer.Charge = min(eventPlayer.MaximumCharge, eventPlayer.Charge + eventPlayer.RechargePerTick)
    wait()
    if ruleCondition:
        loop()


rule "Moving Uses Charge":
    @Event eachPlayer
    @Condition eventPlayer.isUsingAbility2() == false
    @Condition eventPlayer.isUsingAbility1() == false
    @Condition magnitude(eventPlayer.getThrottle()) > 0
    
    eventPlayer.Charge = max(0, eventPlayer.Charge - eventPlayer.RechargePerTick)
    wait()
    if ruleCondition:
        loop()


rule "Not enough charge for Ability 1":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.Ability1ChargeCost
    @Condition eventPlayer.isUsingAbility1() == false
    
    eventPlayer.setAbility1Enabled(false)


rule "Enough charge for Ability 1":
    @Event eachPlayer
    @Condition eventPlayer.Charge >= eventPlayer.Ability1ChargeCost
    @Condition eventPlayer.IsSelectingUpgrade == false
    
    eventPlayer.setAbility1Enabled(true)


rule "Is using Ability 1":
    @Event eachPlayer
    @Condition eventPlayer.isUsingAbility1() == true
    
    eventPlayer.IsDashJumping = false
    eventPlayer.Charge -= eventPlayer.Ability1ChargeCost
    if eventPlayer.isInAir():
        return
    if eventPlayer.getHero() != Hero.SHION:
        return
    eventPlayer.CanDashJump = true
    waitUntil(not eventPlayer.isUsingAbility1(), 99999)
    eventPlayer.CanDashJump = false


rule "Not enough charge for Ability 2":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.Ability2ChargeCost
    @Condition eventPlayer.isUsingAbility2() == false
    
    eventPlayer.setAbility2Enabled(false)


rule "Enough charge for Ability 2":
    @Event eachPlayer
    @Condition eventPlayer.Charge >= eventPlayer.Ability2ChargeCost
    
    eventPlayer.setAbility2Enabled(true)


rule "Is using Ability 2":
    @Event eachPlayer
    @Condition eventPlayer.isUsingAbility2() == true
    
    eventPlayer.IsDashJumping = false
    eventPlayer.Charge -= eventPlayer.Ability2ChargeCost
    UpdateMoveSpeed()


rule "Is using Ability 2":
    @Event eachPlayer
    @Condition eventPlayer.isUsingAbility2() == true
    @Condition eventPlayer.JumpCharge == 0
    
    eventPlayer.JumpChargeCost = 4


rule "Disable Jump":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.JumpChargeCost
    
    eventPlayer.setJumpEnabled(false)


rule "Enable Jump":
    @Event eachPlayer
    @Condition eventPlayer.Charge >= eventPlayer.JumpChargeCost
    @Condition eventPlayer.IsSelectingUpgrade == false
    
    eventPlayer.setJumpEnabled(true)


rule "Is jumping":
    @Event eachPlayer
    @Condition eventPlayer.isJumping() == true
    
    eventPlayer.Charge -= eventPlayer.JumpChargeCost


rule "Not enough charge for primary fire":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.AmmoChargeCost
    @Condition eventPlayer.isUsingAbility2() == false
    
    eventPlayer.setPrimaryFireEnabled(false)


rule "Enough charge for primary fire":
    @Event eachPlayer
    @Condition eventPlayer.IsSelectingUpgrade == false
    @Condition (
        eventPlayer.isUsingAbility2()
        or (
            eventPlayer.Charge >= eventPlayer.AmmoChargeCost
            and not eventPlayer.IsInSanctuary
        )
    ) == true

    eventPlayer.setPrimaryFireEnabled(true)


rule "Firing primary uses charge":
    @Event eachPlayer
    @Condition eventPlayer.isFiringPrimaryFire() == true
    
    eventPlayer.Charge -= eventPlayer.AmmoChargeCost * eventPlayer.FireRate * 0.016
    wait()
    if ruleCondition:
        loop()


rule "Not enough charge for secondary fire":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.SecondaryChargeCost
    
    eventPlayer.disallowButton(Button.SECONDARY_FIRE)


rule "Enough charge for secondary fire":
    @Event eachPlayer
    @Condition eventPlayer.Charge >= eventPlayer.SecondaryChargeCost
    @Condition eventPlayer.IsInSanctuary == false

    eventPlayer.allowButton(Button.SECONDARY_FIRE)


rule "Is firing secondary":
    @Event eachPlayer
    @Condition eventPlayer.getAbilityCooldown(Button.SECONDARY_FIRE) > 0
    
    eventPlayer.Charge -= eventPlayer.SecondaryChargeCost


rule "Not enough charge for melee":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.MeleeChargeCost
    
    eventPlayer.setMeleeEnabled(false)


rule "Enough charge for melee":
    @Event eachPlayer
    @Condition eventPlayer.Charge >= eventPlayer.MeleeChargeCost
    @Condition eventPlayer.IsSelectingUpgrade == false
    
    eventPlayer.setMeleeEnabled(true)


rule "Is meleeing":
    @Event eachPlayer
    @Condition eventPlayer.isMeleeing() == true
    
    eventPlayer.Charge -= eventPlayer.MeleeChargeCost


rule "Not enough charge for ult":
    @Event eachPlayer
    @Condition eventPlayer.Charge < eventPlayer.UltimateChargeCost
    
    eventPlayer.disallowButton(Button.ULTIMATE)


rule "Enough charge for ult":
    @Event eachPlayer
    @Condition eventPlayer.Charge >= eventPlayer.UltimateChargeCost
    @Condition eventPlayer.IsInSanctuary == false

    eventPlayer.allowButton(Button.ULTIMATE)


rule "Is using ult":
    @Event eachPlayer
    @Condition eventPlayer.isUsingUltimate() == true
    
    eventPlayer.IsDashJumping = false
    eventPlayer.Charge -= eventPlayer.UltimateChargeCost


rule "Player is in charging station":
    @Event eachPlayer
    @Condition eventPlayer.hasSpawned() == true
    @Condition eventPlayer.isAlive() == true
    @Condition eventPlayer.getPosition().y > ChargingStationPosition.y - 20
    @Condition eventPlayer.getPosition().y < ChargingStationPosition.y + 10
    @Condition magnitude(vectorTowards(ChargingStationPosition, eventPlayer).map(lambda x: vect(x.x, 0, x.z))) < ChargingStationRadius
    
    eventPlayer.IsOnChargingStation = true


rule "Record Amount of Health Regenerated":
    @Event playerReceivedHealing
    @Condition healer == healee
    
    eventPlayer.AccxmulatedHealing += eventHealing * (1 - 0.1 / eventPlayer.RegenMultiplier)


rule "Regen uses charge":
    @Event eachPlayer
    
    eventPlayer.Charge -= eventPlayer.AccxmulatedHealing / 4
    eventPlayer.AccxmulatedHealing = 0
    wait()
    loop()


rule "Regain Charge in Charging Station":
    @Event eachPlayer
    @Condition (eventPlayer.IsOnChargingStation or eventPlayer.isDummy()) == true
    
    eventPlayer.Charge = min(eventPlayer.MaximumCharge, eventPlayer.Charge + (0.016 * createWorkshopSettingInt("General", "Charge Rate from Charging Station", 100, 0, 300)))
    wait(0.016, Wait.ABORT_WHEN_FALSE)
    if ruleCondition:
        loop()


rule "Too far away from Charging Station vertically":
    @Event eachPlayer
    @Condition (eventPlayer.getPosition().y > ChargingStationPosition.y - 20 and eventPlayer.getPosition().y < ChargingStationPosition.y + 10) == false
    
    eventPlayer.IsOnChargingStation = false


rule "Outside of Charging Station radius":
    @Event eachPlayer
    @Condition magnitude(vectorTowards(ChargingStationPosition, eventPlayer).map(lambda x: vect(x.x, 0, x.z))) >= ChargingStationRadius
    
    eventPlayer.IsOnChargingStation = false


rule "Charge Jump":
    @Event eachPlayer
    @Hero shion
    @Condition eventPlayer.isUsingAbility2() == true
    @Condition eventPlayer.isHoldingButton(Button.CROUCH) == true
    @Condition eventPlayer.isOnGround() == true
    
    UpdateMoveSpeed()
    eventPlayer.JumpCharge = 0
    eventPlayer.JumpChargeCost = 9
    chaseAtRate(eventPlayer.JumpCharge, 1, 0.4 + eventPlayer.CountOfEachBuff[4] * 0.17)


rule "Reset Move Speed While Not holding crouch on ground":
    @Event eachPlayer
    @Condition (eventPlayer.isOnGround() and eventPlayer.isHoldingButton(Button.CROUCH) and eventPlayer.isUsingAbility2()) == false
    
    UpdateMoveSpeed()


rule "Player Leaves Ground":
    @Event eachPlayer
    @Condition eventPlayer.isOnGround() == false
    
    if eventPlayer.isUsingAbility2() and eventPlayer.isJumping() and eventPlayer.JumpCharge > 0:
        eventPlayer.setGravity(100 - 50 * eventPlayer.JumpCharge)
        eventPlayer.setJumpVerticalSpeed(100 * (sqrt((1 + (0.03 * eventPlayer.CountOfEachBuff[4] - 0.5) * eventPlayer.JumpCharge) / (1 - 0.6 * eventPlayer.JumpCharge))))
        playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION_SOUND, Color.WHITE, eventPlayer.getEyePosition(), 30 + 70 * eventPlayer.JumpCharge)
    stopChasing(eventPlayer.JumpCharge)
    eventPlayer.JumpCharge = 0


rule "Crouch Button no longer held":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.CROUCH) == false
    
    if eventPlayer.JumpCharge == 0:
        return
    stopChasing(eventPlayer.JumpCharge)
    wait(1, Wait.ABORT_WHEN_FALSE)
    eventPlayer.JumpCharge = 0


rule "Not On Bike":
    @Event eachPlayer
    @Condition eventPlayer.isUsingAbility2() == false
    
    stopChasing(eventPlayer.JumpCharge)
    eventPlayer.JumpCharge = 0
    UpdateMoveSpeed()

def BuySelectedUpgrade():
    @Name "Buy Selected Upgrade"

    if len(BuffIndicesInShop) <= eventPlayer.SelectedShopIndex:
        return

    playEffect(eventPlayer, DynamicEffect.BUFF_IMPACT_SOUND, Color.WHITE, eventPlayer, 80)

    eventPlayer.CountOfEachBuff[BuffIndicesInShop[eventPlayer.SelectedShopIndex]]++

    logToInspector(
        "SFFA|v=1|t={0}|e=UPGRADE_BUY|pid={1}|shop={2}|upgrade={3}|stack={4}".format(
            getTotalTimeElapsed(),
            eventPlayer.TelemetryPlayerId,
            CurrentShopId,
            AllBuffInternalNames[
                BuffIndicesInShop[eventPlayer.SelectedShopIndex]
            ],
            eventPlayer.CountOfEachBuff[
                BuffIndicesInShop[eventPlayer.SelectedShopIndex]
            ]
        )
    )

    smallMessage(
        getAllPlayers(),
        "{0} got upgrade '{1}' ({2} stacks to {3})".format(
            eventPlayer,
            AllBuffNames[BuffIndicesInShop[eventPlayer.SelectedShopIndex]],
            eventPlayer.CountOfEachBuff[BuffIndicesInShop[eventPlayer.SelectedShopIndex]] - 1,
            eventPlayer.CountOfEachBuff[BuffIndicesInShop[eventPlayer.SelectedShopIndex]]
        )
    )

    eventPlayer.HasBoughtFromShop = true


rule "Player Is In Shop":
    @Event eachPlayer
    @Condition CurrentShopPosition != null
    @Condition distance(vect(eventPlayer.getPosition().x, 0, eventPlayer.getPosition().z), vect(CurrentShopPosition.x, 0, CurrentShopPosition.z)) < ObjectiveRadius
    @Condition eventPlayer.getPosition().y > CurrentShopPosition.y - 20
    @Condition eventPlayer.getPosition().y < CurrentShopPosition.y + 10
    @Condition eventPlayer.isAlive() == true
    
    eventPlayer.IsInShop = true


rule "Player Is Not In Shop":
    @Event eachPlayer
    @Condition (CurrentShopPosition and distance(vect(eventPlayer.getPosition().x, 0, eventPlayer.getPosition().z), vect(CurrentShopPosition.x, 0, CurrentShopPosition.z)) < ObjectiveRadius and eventPlayer.getPosition().y > CurrentShopPosition.y - 20 and eventPlayer.getPosition().y < CurrentShopPosition.y + 10 and eventPlayer.isAlive()) == false
    
    eventPlayer.IsInShop = false


def SetMaximumCharge():
    @Name "Set Maximum Charge"
    
    eventPlayer.MaximumCharge = createWorkshopSettingInt("General", "Base Max Charge / 10", 200, 30, 300) * 10


rule "Secondary Fire deals knockback":
    @Event playerDealtDamage
    @Condition eventAbility == Button.SECONDARY_FIRE
    @Condition attacker.CountOfEachBuff[6] > 0
    
    victim.applyImpulse(directionFromAngles(horizontalAngleOfDirection(eventDirection), -19), 3.395 - 4.772 / (attacker.CountOfEachBuff[6] + 1.154), Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
    victim.setEnvironmentalKillCreditor(attacker)


rule "Melee Damage":
    @Event playerDealtDamage
    @Condition eventAbility == Button.MELEE
    @Condition attacker.CountOfEachBuff[8] > 0

    if LogDamageUpgradeDiagnostics:
        logToInspector(
            "BONUS_REQ|t={0}|type=MELEE|atk={1}|vic={2}|input={3}|joyActive={4}|joyStacks={5}|meleeStacks={6}|requested={7}".format(
                getTotalTimeElapsed(),
                attacker,
                victim,
                eventDamage,
                victim in attacker.JoyrideImpactVictims,
                attacker.CountOfEachBuff[2],
                attacker.CountOfEachBuff[8],
                eventDamage
                * 0.2
                * attacker.CountOfEachBuff[8]
            )
        )
    
    attacker.enqueueScriptedDamage(
        victim,
        eventDamage
        * 0.2
        * attacker.CountOfEachBuff[
            UpgradeIndex("MELEE_DAMAGE")
        ],
        ScriptedDamageSource.MELEE_BONUS
    )


rule "Melee Lifesteal":
    @Event playerDealtDamage
    @Condition (
        eventAbility == Button.MELEE
        or IsScriptedBonusDamage(
            eventAbility,
            attacker,
            victim,
            ScriptedDamageSource.MELEE_BONUS
        )
    ) == true
    @Condition attacker.CountOfEachBuff[7] > 0

    heal(
        attacker,
        null,
        eventDamage * (
            0.15 * attacker.CountOfEachBuff[7]
            + 0.25
        )
    )


rule "Primary Fire Upgrade Damage":
    @Event playerDealtDamage
    @Condition eventAbility == Button.PRIMARY_FIRE
    @Condition (
        OffObjectivePrimaryBonusFactor(attacker) > 0
        or PrimaryVsMaxHealthBonusFactor(attacker, victim) > 0
    ) == true

    if LogDamageUpgradeDiagnostics:
        logToInspector(
            "BONUS_REQ|t={0}|type=PRIMARY|atk={1}|vic={2}|input={3}|joyActive={4}|joyStacks={5}|offStacks={6}|maxHpStacks={7}|capturing={8}|targetMaxHp={9}|requested={10}".format(
                getTotalTimeElapsed(),
                attacker,
                victim,
                eventDamage,
                victim in attacker.JoyrideImpactVictims,
                attacker.CountOfEachBuff[2],
                attacker.CountOfEachBuff[1],
                attacker.CountOfEachBuff[5],
                attacker.IsCapturingObjective,
                victim.getMaxHealth(),
                PrimaryBonusDamage(eventDamage, attacker, victim)
            )
        )

    if OffObjectivePrimaryBonusFactor(attacker) > 0:
        attacker.recordDamageUpgradeActivation(
            "OFF_OBJECTIVE_PRIMARY_DAMAGE",
            victim
        )

    if PrimaryVsMaxHealthBonusFactor(attacker, victim) > 0:
        attacker.recordDamageUpgradeActivation(
            "PRIMARY_VS_MAX_HEALTH",
            victim
        )

    attacker.enqueueScriptedDamage(
        victim,
        PrimaryBonusDamage(eventDamage, attacker, victim),
        ScriptedDamageSource.PRIMARY_BONUS,
        [
            UpgradeIndex("OFF_OBJECTIVE_PRIMARY_DAMAGE"),
            UpgradeIndex("PRIMARY_VS_MAX_HEALTH")
        ],
        [
            eventDamage * OffObjectivePrimaryBonusFactor(attacker),
            eventDamage * PrimaryVsMaxHealthBonusFactor(attacker, victim)
        ]
    )


rule "Joyride Impact Bonus Damage":
    @Event playerDealtDamage
    @Condition IsNativeDamage(eventAbility)
    @Condition victim in attacker.JoyrideImpactVictims
    @Condition attacker.CountOfEachBuff[2] > 0

    if LogDamageUpgradeDiagnostics:
        logToInspector(
            "JOY_BONUS_REQ|t={0}|atk={1}|vic={2}|sourceAbility={3}|input={4}|joyStacks={5}|requested={6}".format(
                getTotalTimeElapsed(),
                attacker,
                victim,
                eventAbility,
                eventDamage,
                attacker.CountOfEachBuff[2],
                eventDamage * 0.08 * attacker.CountOfEachBuff[2]
            )
        )

    attacker.enqueueScriptedDamage(
        victim,
        eventDamage * 0.08 * attacker.CountOfEachBuff[2],
        ScriptedDamageSource.JOYRIDE_BONUS
    )


rule "Dispatch Scripted Bonus Damage":
    @Event eachPlayer
    @Condition len(eventPlayer.ScriptedDamageQueueSources) > 0
    @Condition eventPlayer.ActiveScriptedDamageSource == ScriptedDamageSource.NONE

    eventPlayer.ActiveScriptedDamageVictim = (
        eventPlayer.ScriptedDamageQueueVictims[0]
    )

    eventPlayer.ActiveScriptedDamageSource = (
        eventPlayer.ScriptedDamageQueueSources[0]
    )

    if LogDamageUpgradeDiagnostics:
        logToInspector(
            "BONUS_DISPATCH|t={0}|atk={1}|vic={2}|source={3}|requested={4}|queue={5}".format(
                getTotalTimeElapsed(),
                eventPlayer,
                eventPlayer.ActiveScriptedDamageVictim,
                eventPlayer.ActiveScriptedDamageSource,
                eventPlayer.ScriptedDamageQueueAmounts[0],
                len(eventPlayer.ScriptedDamageQueueSources)
            )
        )

    damage(
        eventPlayer.ActiveScriptedDamageVictim,
        eventPlayer,
        eventPlayer.ScriptedDamageQueueAmounts[0]
    )

    wait()

    del eventPlayer.ScriptedDamageQueueVictims[0]
    del eventPlayer.ScriptedDamageQueueAmounts[0]
    del eventPlayer.ScriptedDamageQueueSources[0]
    del eventPlayer.ScriptedDamageAttribUpgradeIds[0]
    del eventPlayer.ScriptedDamageAttribAmounts[0]

    eventPlayer.ActiveScriptedDamageSource = ScriptedDamageSource.NONE
    eventPlayer.ActiveScriptedDamageVictim = null

    if len(eventPlayer.ScriptedDamageQueueSources) > 0:
        loop()


rule "Accxmulate Combat Damage Counters":
    @Event playerDealtDamage
    @Condition attacker != null
    @Condition attacker != victim
    @Condition attacker.TelemetryPlayerId > 0

    if IsNativeDamage(eventAbility):
        if eventAbility in NativeAttackAbilities:
            attacker.NativeDamageByAttackType[
                NativeAttackAbilities.index(eventAbility)
            ] += eventDamage

            attacker.NativeHitCountsByAttackType[
                NativeAttackAbilities.index(eventAbility)
            ]++
        else:
            attacker.OtherNativeDamage += eventDamage
            attacker.OtherNativeHitCount++

    elif IsClassifiedScriptedDamage(
        eventAbility,
        attacker,
        victim
    ):
        attacker.ScriptedBonusDamageBySource[
            attacker.ActiveScriptedDamageSource
        ] += eventDamage
    
        if attacker.ScriptedDamageQueueAmounts[0] > 0:
            attacker.DamageUpgradePureDamage = (
                attacker.DamageUpgradePureDamage.map(
                    lambda currentDamage, upgradeIndex:
                        currentDamage
                        + (
                            attacker.ScriptedDamageAttribAmounts[0][
                                attacker.ScriptedDamageAttribUpgradeIds[
                                    0
                                ].index(upgradeIndex)
                            ]
                            * eventDamage
                            / attacker.ScriptedDamageQueueAmounts[0]
                            if upgradeIndex
                            in attacker.ScriptedDamageAttribUpgradeIds[0]
                            else 0
                        )
                )
            )


rule "Log Damage Upgrade Diagnostic":
    @Event playerDealtDamage
    @Condition LogDamageUpgradeDiagnostics == true

    logToInspector(
        "DMG|t={0}|atk={1}|vic={2}|ability={3}|damage={4}|joyActive={5}|joyStacks={6}|offStacks={7}|maxHpStacks={8}|meleeStacks={9}|capturing={10}|targetMaxHp={11}|native={12}|scriptedSource={13}".format(
            getTotalTimeElapsed(),
            attacker,
            victim,
            eventAbility,
            eventDamage,
            victim in attacker.JoyrideImpactVictims,
            attacker.CountOfEachBuff[2],
            attacker.CountOfEachBuff[1],
            attacker.CountOfEachBuff[5],
            attacker.CountOfEachBuff[8],
            attacker.IsCapturingObjective,
            victim.getMaxHealth(),
            IsNativeDamage(eventAbility),
            ClassifiedScriptedDamageSource(
                eventAbility,
                attacker,
                victim
            )
        )
    )


rule "Apply Joyride Impact":
    @Event playerDealtDamage
    @Condition eventAbility == Button.ABILITY_2
    @Condition attacker.CountOfEachBuff[2] > 0

    if victim not in attacker.JoyrideImpactVictims:
        attacker.JoyrideImpactVictims.append(victim)

    attacker.JoyrideImpactExpiryTimes[
        attacker.JoyrideImpactVictims.index(victim)
    ] = getTotalTimeElapsed() + 1 + attacker.CountOfEachBuff[2] / 5

    if LogDamageUpgradeDiagnostics:
        logToInspector(
            "JOY_MARK|t={0}|atk={1}|vic={2}|stacks={3}|expires={4}".format(
                getTotalTimeElapsed(),
                attacker,
                victim,
                attacker.CountOfEachBuff[2],
                attacker.JoyrideImpactExpiryTimes[
                    attacker.JoyrideImpactVictims.index(victim)
                ]
            )
        )


rule "Player Buffs Setup":
    @Event eachPlayer
    @Condition AllBuffDescriptions != null
    @Condition len(AllBuffDescriptions) > 0
    
    eventPlayer.JoyrideImpactVictims = []
    eventPlayer.JoyrideImpactExpiryTimes = []
    eventPlayer.CountOfEachBuff = AllBuffDescriptions.map(lambda _: createWorkshopSettingInt("Testing", "Starting Count of Each Buff", 0, 0, 20))
    eventPlayer.addHealthPool(
        Health.NORMAL,
        50
        + 100 * min(eventPlayer.CountOfEachBuff[0], 5)
        + 75 * min(max(eventPlayer.CountOfEachBuff[0] - 5, 0), 5)
        + 50 * min(max(eventPlayer.CountOfEachBuff[0] - 10, 0), 5)
        + 25 * max(eventPlayer.CountOfEachBuff[0] - 15, 0),
        true
    )


rule "Remove Expired Joyride Impacts":
    @Event eachPlayer
    @Condition eventPlayer.JoyrideImpactExpiryTimes.any(lambda x: x < getTotalTimeElapsed()) == true

    eventPlayer.ExpiredJoyrideImpactIndex = eventPlayer.JoyrideImpactExpiryTimes.map(
        lambda _, i_: i_
    ).filter(
        lambda i_: eventPlayer.JoyrideImpactExpiryTimes[i_] < getTotalTimeElapsed()
    )[0]

    del eventPlayer.JoyrideImpactVictims[eventPlayer.ExpiredJoyrideImpactIndex]
    del eventPlayer.JoyrideImpactExpiryTimes[eventPlayer.ExpiredJoyrideImpactIndex]

    if ruleCondition:
        loop()

rule "Player Final Blow":
    @Event playerDealtFinalBlow
    @Condition attacker != null
    @Condition attacker != victim

    if attacker.TelemetryPlayerId > 0:
        attacker.FinalBlowCount++

    if attacker.CountOfEachBuff[3] > 0:
        heal(
            attacker,
            null,
            20 * attacker.CountOfEachBuff[3]
        )

        attacker.setAbilityCooldown(
            Button.SECONDARY_FIRE,
            attacker.getAbilityCooldown(Button.SECONDARY_FIRE)
            * max(0, 1 - attacker.CountOfEachBuff[3] / 5)
        )

        attacker.setAbilityCooldown(
            Button.ABILITY_1,
            attacker.getAbilityCooldown(Button.ABILITY_1)
            * max(0, 1 - attacker.CountOfEachBuff[3] / 5)
        )

        attacker.setAbilityCooldown(
            Button.ABILITY_2,
            attacker.getAbilityCooldown(Button.ABILITY_2)
            * max(0, 1 - attacker.CountOfEachBuff[3] / 5)
        )


rule "Resurrect players once objective captured":
    @Event eachPlayer
    @Condition eventPlayer.RespawnAtTemporarySanctuary == true
    
    ResurrectMe()


rule "Resurrection Replaces Respawning":
    @Event eachPlayer
    @Condition eventPlayer.isDead() == true
    
    eventPlayer.RespawnTimer = createWorkshopSettingInt("General", "Max Respawn Time", 8, 1, 90)
    waitUntil(eventPlayer.RespawnTimer <= 0, 99999)
    ResurrectMe()


def ResurrectMe():
    @Name "Resurrect Me"
    
    if eventPlayer.isAlive():
        return
    
    if eventPlayer.RespawnAtTemporarySanctuary and TemporarySanctuaryPosition:
        eventPlayer.teleport(TemporarySanctuaryPosition)
    else:
        eventPlayer.teleport(ChargingStationPosition)
    
    eventPlayer.RespawnAtTemporarySanctuary = false    
    eventPlayer.resurrect()
    playEffect(getAllPlayers(), DynamicEffect.GOOD_PICKUP_EFFECT, Color.YELLOW, eventPlayer, 1)
    eventPlayer.communicate(Comms.HELLO)


rule "Dummy Bot Auto Aim":
    @Event eachPlayer
    @Condition eventPlayer.isDummy() == true
    @Condition eventPlayer.isAlive() == true
    @Condition hostPlayer.isAlive() == true
    
    if createWorkshopSettingBool(
        "Testing",
        "Dummy Bot Auto Aim",
        false
    ):
        eventPlayer.startForcingButton(Button.PRIMARY_FIRE)
        eventPlayer.startFacing(directionTowards(eventPlayer.getEyePosition(), hostPlayer.getEyePosition()), 720)


rule "Low Charge Warning":
    @Event eachPlayer
    @Condition eventPlayer.Charge < 1.5 * RestoreChargeTo
    @Condition eventPlayer.LowChargeWarningActive == false

    eventPlayer.LowChargeWarningActive = true
    bigMessage(
        eventPlayer,
        "{0} LOW CHARGE".format(iconString(Icon.WARNING))
    )


rule "Reset Low Charge Warning":
    @Event eachPlayer
    @Condition eventPlayer.Charge > 2.5 * RestoreChargeTo
    @Condition eventPlayer.LowChargeWarningActive == true

    eventPlayer.LowChargeWarningActive = false


rule "Player Is In Sanctuary":
    @Event eachPlayer
    @Condition eventPlayer.isAlive() == true
    @Condition (
        eventPlayer.IsOnChargingStation
        or (
            TemporarySanctuaryPosition
            and distance(
                vect(eventPlayer.getPosition().x, 0, eventPlayer.getPosition().z),
                vect(TemporarySanctuaryPosition.x, 0, TemporarySanctuaryPosition.z)
            ) < ObjectiveRadius
            and eventPlayer.getPosition().y > TemporarySanctuaryPosition.y - 20
            and eventPlayer.getPosition().y < TemporarySanctuaryPosition.y + 10
        )
    ) == true

    eventPlayer.IsInSanctuary = true


rule "Player Is Not In Sanctuary":
    @Event eachPlayer
    @Condition eventPlayer.IsOnChargingStation == false
    @Condition (
        TemporarySanctuaryPosition
        and distance(
            vect(eventPlayer.getPosition().x, 0, eventPlayer.getPosition().z),
            vect(TemporarySanctuaryPosition.x, 0, TemporarySanctuaryPosition.z)
        ) < ObjectiveRadius
        and eventPlayer.getPosition().y > TemporarySanctuaryPosition.y - 20
        and eventPlayer.getPosition().y < TemporarySanctuaryPosition.y + 10
    ) == false

    eventPlayer.IsInSanctuary = false


rule "Apply Sanctuary Status":
    @Event eachPlayer
    @Condition eventPlayer.IsInSanctuary == true

    eventPlayer.setStatusEffect(null, Status.PHASED_OUT, 9999)
    
    if not eventPlayer.isUsingAbility2():
        eventPlayer.setPrimaryFireEnabled(false)
    
    eventPlayer.disallowButton(Button.SECONDARY_FIRE)
    eventPlayer.disallowButton(Button.ULTIMATE)


rule "Remove Sanctuary Status":
    @Event eachPlayer
    @Condition eventPlayer.IsInSanctuary == false

    eventPlayer.clearStatusEffect(Status.PHASED_OUT)


rule "Open Upgrade Selection":
    @Event eachPlayer
    @Condition eventPlayer.IsInShop == true
    @Condition eventPlayer.HasBoughtFromShop == false
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true

    eventPlayer.SelectedShopIndex = -1
    eventPlayer.IsSelectingUpgrade = true

    logToInspector(
        "SFFA|v=1|t={0}|e=SHOP_OPEN|pid={1}|shop={2}".format(
            getTotalTimeElapsed(),
            eventPlayer.TelemetryPlayerId,
            CurrentShopId
        )
    )


rule "Close Upgrade Selection":
    @Event eachPlayer
    @Condition (
        eventPlayer.IsInShop
        and not eventPlayer.HasBoughtFromShop
        and eventPlayer.isHoldingButton(Button.INTERACT)
    ) == false

    eventPlayer.IsSelectingUpgrade = false
    eventPlayer.SelectedShopIndex = -1

rule "Is Player Holding Primary Fire":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE) == true

    if (eventPlayer.IsInSanctuary):
        playEffect(eventPlayer, DynamicEffect.DEBUFF_IMPACT_SOUND, Color.WHITE, eventPlayer, 20)

    if not (
        eventPlayer.IsSelectingUpgrade
        and len(BuffIndicesInShop) > UpgradeChoiceButtons.index(Button.PRIMARY_FIRE)
    ):
        return

    eventPlayer.SelectedShopIndex = UpgradeChoiceButtons.index(Button.PRIMARY_FIRE)
    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
            and eventPlayer.IsSelectingUpgrade
            and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.PRIMARY_FIRE)
        ),
        99999
    )

    if (
        eventPlayer.IsSelectingUpgrade
        and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.PRIMARY_FIRE)
    ):
        BuySelectedUpgrade()


rule "Is Player Holding Jump":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.JUMP) == true

    if eventPlayer.IsSelectingUpgrade and len(BuffIndicesInShop) > UpgradeChoiceButtons.index(Button.JUMP):
        eventPlayer.SelectedShopIndex = UpgradeChoiceButtons.index(Button.JUMP)
        waitUntil(
            not (
                eventPlayer.isHoldingButton(Button.JUMP)
                and eventPlayer.IsSelectingUpgrade
                and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.JUMP)
            ),
            99999
        )

        if (
            eventPlayer.IsSelectingUpgrade
            and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.JUMP)
        ):
            BuySelectedUpgrade()

        return

    if not eventPlayer.CanDashJump:
        return
    if eventPlayer.Charge < eventPlayer.JumpChargeCost:
        return
    eventPlayer.IsDashJumping = true
    eventPlayer.Charge -= eventPlayer.JumpChargeCost
    eventPlayer.cancelPrimaryAction()
    eventPlayer.applyImpulse(directionFromAngles(horizontalAngleOfDirection(eventPlayer.getVelocity()), -18), 25, Relativity.TO_WORLD, Impulse.CANCEL_CONTRARY_MOTION_XYZ)


rule "Is Player Holding Melee":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.MELEE) == true

    if not (
        eventPlayer.IsSelectingUpgrade
        and len(BuffIndicesInShop) > UpgradeChoiceButtons.index(Button.MELEE)
    ):
        return

    eventPlayer.SelectedShopIndex = UpgradeChoiceButtons.index(Button.MELEE)
    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.MELEE)
            and eventPlayer.IsSelectingUpgrade
            and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.MELEE)
        ),
        99999
    )

    if (
        eventPlayer.IsSelectingUpgrade
        and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.MELEE)
    ):
        BuySelectedUpgrade()


rule "Is Player Holding Reload":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.RELOAD) == true

    if not (
        eventPlayer.IsSelectingUpgrade
        and len(BuffIndicesInShop) > UpgradeChoiceButtons.index(Button.RELOAD)
    ):
        return

    eventPlayer.SelectedShopIndex = UpgradeChoiceButtons.index(Button.RELOAD)
    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.RELOAD)
            and eventPlayer.IsSelectingUpgrade
            and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.RELOAD)
        ),
        99999
    )

    if (
        eventPlayer.IsSelectingUpgrade
        and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.RELOAD)
    ):
        BuySelectedUpgrade()


rule "Is Player Holding Ability 1":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.ABILITY_1) == true

    if not (
        eventPlayer.IsSelectingUpgrade
        and len(BuffIndicesInShop) > UpgradeChoiceButtons.index(Button.ABILITY_1)
    ):
        return

    eventPlayer.SelectedShopIndex = UpgradeChoiceButtons.index(Button.ABILITY_1)
    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.ABILITY_1)
            and eventPlayer.IsSelectingUpgrade
            and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.ABILITY_1)
        ),
        99999
    )

    if (
        eventPlayer.IsSelectingUpgrade
        and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.ABILITY_1)
    ):
        BuySelectedUpgrade()


rule "Is Player Holding Crouch":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.CROUCH) == true

    if eventPlayer.IsSelectingUpgrade and len(BuffIndicesInShop) > UpgradeChoiceButtons.index(Button.CROUCH):
        eventPlayer.SelectedShopIndex = UpgradeChoiceButtons.index(Button.CROUCH)
        waitUntil(
            not (
                eventPlayer.isHoldingButton(Button.CROUCH)
                and eventPlayer.IsSelectingUpgrade
                and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.CROUCH)
            ),
            99999
        )

        if (
            eventPlayer.IsSelectingUpgrade
            and eventPlayer.SelectedShopIndex == UpgradeChoiceButtons.index(Button.CROUCH)
        ):
            BuySelectedUpgrade()

        return

    if eventPlayer.isOnGround():
        return
    if eventPlayer.CrouchCounter == 0:
        eventPlayer.CrouchCounter++
    elif eventPlayer.CrouchCounter == 1:
        eventPlayer.CrouchCounter++
        if eventPlayer.Charge >= eventPlayer.JumpChargeCost:
            eventPlayer.Charge -= eventPlayer.JumpChargeCost
            eventPlayer.applyImpulse(Vector.DOWN, 20, Relativity.TO_WORLD, Impulse.CANCEL_CONTRARY_MOTION_XYZ)
            playEffect(getAllPlayers(), DynamicEffect.EXPLOSION_SOUND, Color.WHITE, eventPlayer, 80)


rule "Disable Upgrade Choice Actions":
    @Event eachPlayer
    @Condition eventPlayer.IsSelectingUpgrade == true

    eventPlayer.setPrimaryFireEnabled(false)
    eventPlayer.setJumpEnabled(false)
    eventPlayer.setMeleeEnabled(false)
    eventPlayer.setReloadEnabled(false)
    eventPlayer.setAbility1Enabled(false)
    eventPlayer.setCrouchEnabled(false)
    UpdateMoveSpeed()

rule "Restore Upgrade Choice Actions":
    @Event eachPlayer
    @Condition eventPlayer.IsSelectingUpgrade == false

    eventPlayer.setReloadEnabled(true)
    eventPlayer.setCrouchEnabled(true)
    UpdateMoveSpeed()

rule "Testing Select Next Upgrade":
    @Event eachPlayer
    @Condition EnableTestingControls == true
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true
    @Condition eventPlayer.isHoldingButton(Button.RELOAD) == true

    eventPlayer.TestSelectedUpgrade = (
        eventPlayer.TestSelectedUpgrade + 1
    ) % len(AllBuffNames)

    smallMessage(
        eventPlayer,
        "TEST UPGRADE: {0} x{1}".format(
            AllBuffNames[eventPlayer.TestSelectedUpgrade],
            eventPlayer.CountOfEachBuff[eventPlayer.TestSelectedUpgrade]
        )
    )

    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.INTERACT)
            and eventPlayer.isHoldingButton(Button.RELOAD)
        ),
        99999
    )


rule "Testing Increase Upgrade Stack":
    @Event eachPlayer
    @Condition EnableTestingControls == true
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE) == true

    eventPlayer.CountOfEachBuff[eventPlayer.TestSelectedUpgrade]++

    smallMessage(
        eventPlayer,
        "{0} x{1}".format(
            AllBuffNames[eventPlayer.TestSelectedUpgrade],
            eventPlayer.CountOfEachBuff[eventPlayer.TestSelectedUpgrade]
        )
    )

    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.INTERACT)
            and eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
        ),
        99999
    )


rule "Testing Decrease Upgrade Stack":
    @Event eachPlayer
    @Condition EnableTestingControls == true
    @Condition eventPlayer == hostPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true
    @Condition eventPlayer.isHoldingButton(Button.SECONDARY_FIRE) == true

    eventPlayer.CountOfEachBuff[eventPlayer.TestSelectedUpgrade] = max(
        0,
        eventPlayer.CountOfEachBuff[eventPlayer.TestSelectedUpgrade] - 1
    )

    smallMessage(
        eventPlayer,
        "{0} x{1}".format(
            AllBuffNames[eventPlayer.TestSelectedUpgrade],
            eventPlayer.CountOfEachBuff[eventPlayer.TestSelectedUpgrade]
        )
    )

    waitUntil(
        not (
            eventPlayer.isHoldingButton(Button.INTERACT)
            and eventPlayer.isHoldingButton(Button.SECONDARY_FIRE)
        ),
        99999
    )