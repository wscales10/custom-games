settings {
    "gamemodes": {
        "ffa": {
            "enabledMaps": [
                "workshopExpanse"
            ],
        },
    }
}

# State

playervar FishingActionState 0
playervar BobberState 1
playervar FishInteractionState 2
playervar FishingActionStateEntryTimes 3
playervar FishInteractionStateEntryTimes 4


# Rod / casting

playervar CastCharge 5

playervar RodRotationAngle 6
playervar RodAngularVelocity 7

playervar RodBaseOffset 8
playervar RodTipOffset 9
playervar RodPivotOffset 10

playervar RodVisualBaseOffset 11
playervar RodVisualTipOffset 12


# Bobber / line

playervar BobberPosition 13
playervar PreviousBobberPosition 14
playervar BobberVelocity 15

playervar BobberSurfacePosition 16
playervar FishingLineLength 17



# Bite

playervar ScheduledBiteTime 19
playervar BiteStartPosition 20
playervar HookWindowEndTime 21

# Fishing states

enum FishingActionState:
    UNINITIALIZED = 0
    READY
    CHARGING
    SWINGING
    CASTING

enum BobberState:
    ATTACHED = 0
    AIRBORNE
    WATER
    LAND

enum FishInteractionState:
    NONE = 0
    BITE
    REELING
    CATCH_COMPLETE


# General bobber / simulation

macro BOBBER_TICK = 0.016
macro BOBBER_GRAVITY = 17.5
macro BOBBER_RADIUS = 0.1
macro TETHERED_BOBBER_DAMPING = 0.95


# Water

macro WATER_RADIUS = 10
macro WATER_SPRING_STRENGTH = 80
macro WATER_DAMPING = 14

macro WAITING_BOB_AMPLITUDE = 0.05
macro WAITING_BOB_PERIOD = 1.6


# Bite timing / animation

macro MIN_BITE_TIME = 2.5
macro MAX_BITE_TIME = 6.0
macro HOOK_WINDOW = 0.8

macro BITE_DIP_DISTANCE = 0.5
macro BITE_DIP_TIME = 0.2


# Cast charge / speed

macro MIN_CAST_SPEED = 5.5
macro MAX_CAST_SPEED = 25
macro MAX_CAST_CHARGE_TIME = 1.55


# Rod geometry

macro ROD_LENGTH = 2.1
macro ROD_REST_ANGLE = 21
macro ROD_PIVOT_OFFSET = vect(-0.25, -0.3, 0)
macro ROD_BASE_OFFSET = vect(-0.25, -0.55, -0.4)

macro PRE_RELEASE_LINE_LENGTH = ROD_LENGTH * 0.4
macro REEL_SPEED = 5

macro ROD_REST_DIRECTION = vect(
    0,
    sinDeg(ROD_REST_ANGLE),
    cosDeg(ROD_REST_ANGLE)
)

macro ROD_TIP_OFFSET = (
    ROD_BASE_OFFSET
    + ROD_REST_DIRECTION
    * ROD_LENGTH
)


# Rod limits / dynamics

macro MAX_ROD_CAST_ANGLE = 129
macro MIN_NEUTRAL_ROD_ROTATION = -27
macro MAX_CHARGED_ROD_ROTATION = 172

macro ROD_SWING_SETTLE_TIME = 0.3
macro ROD_ANGULAR_RESPONSE = 4 / ROD_SWING_SETTLE_TIME


# Generic helpers

macro smoothstep(t):
    t * t * (3 - 2 * t)


# Fishing state helpers

macro Player.setFishingActionState(state):
    self.FishingActionState = state
    self.FishingActionStateEntryTimes[state] = getTotalTimeElapsed()

macro Player.setFishInteractionState(state):
    self.FishInteractionState = state
    self.FishInteractionStateEntryTimes[state] = getTotalTimeElapsed()

macro Player.isBobberInWater():
    (
        self.BobberPosition.y <= BOBBER_RADIUS
        and distance(
            vect(
                self.BobberPosition.x,
                0,
                self.BobberPosition.z
            ),
            vect(0, 0, 0)
        ) < WATER_RADIUS
    )

# Basic rod helpers

macro Player.getNeutralRodRotation():
    max(
        -self.getVerticalFacingAngle(),
        MIN_NEUTRAL_ROD_ROTATION
    )


# Cast charge helpers

macro castChargeFromTime(player):
    1 - (
        1 - min(
            (
                getTotalTimeElapsed()
                - player.FishingActionStateEntryTimes[FishingActionState.CHARGING]
            )
            / MAX_CAST_CHARGE_TIME,
            1
        )
    ) ** 2

macro Player.getMaxAvailableCastCharge():
    min(
        max(
            (
                MAX_CHARGED_ROD_ROTATION
                - self.getNeutralRodRotation()
            ) / MAX_ROD_CAST_ANGLE,
            0
        ),
        1
    )

macro Player.getEffectiveCastCharge():
    min(
        castChargeFromTime(self),
        self.getMaxAvailableCastCharge()
    )


# Rod target / visual helpers

macro Player.getRodTargetRotation():
    (
        self.getNeutralRodRotation()
        + (
            MAX_ROD_CAST_ANGLE
            * self.getEffectiveCastCharge()
            if self.FishingActionState == FishingActionState.CHARGING
            else 0
        )
    )

macro Player.rotateRodPoint(point, angle):
    (
        self.RodPivotOffset
        + vect(
            (point - self.RodPivotOffset).x,
            (point - self.RodPivotOffset).y * cosDeg(angle)
                + (point - self.RodPivotOffset).z * sinDeg(angle),
            (point - self.RodPivotOffset).z * cosDeg(angle)
                - (point - self.RodPivotOffset).y * sinDeg(angle)
        )
    )

macro Player.updateRodVisualOffsets():
    self.RodVisualBaseOffset = self.rotateRodPoint(
        self.RodBaseOffset,
        self.RodRotationAngle
    )

    self.RodVisualTipOffset = self.rotateRodPoint(
        self.RodTipOffset,
        self.RodRotationAngle
    )

macro Player.getRodTipPosition():
    (
        self.getEyePosition()
        + worldVector(
            self.RodVisualTipOffset,
            self,
            Transform.ROTATION
        )
    )

subroutine ResetFishing 0
subroutine LaunchBobber 1
subroutine UpdateBobberMotion 2


def LaunchBobber():
    @Name "Launch Bobber"

    /* eventPlayer.BobberVelocity = (
        normalize(eventPlayer.BobberVelocity)
        * (
            MIN_CAST_SPEED
            + (
                MAX_CAST_SPEED
                - MIN_CAST_SPEED
            ) * eventPlayer.CastCharge
        )
    ) */

    eventPlayer.setFishingActionState(FishingActionState.CASTING)


rule "Global Setup":
    createEffect(
        getAllPlayers(),
        Effect.RING,
        Color.BLUE,
        vect(0, 0.1, 0),
        WATER_RADIUS,
        EffectReeval.VISIBILITY
    )


rule "Fishing Setup":
    @Event eachPlayer

    waitUntil(eventPlayer.hasSpawned())

    progressBarHud(
        eventPlayer,
        100 * eventPlayer.getEffectiveCastCharge(),
        "{}°".format(round(eventPlayer.RodRotationAngle)),
        HudPosition.TOP,
        0,
        Color.WHITE,
        Color.WHITE,
        ProgressHudReeval.VISIBILITY_AND_VALUES
    )
    eventPlayer.startCamera(eventPlayer.getEyePosition() + vect(5, 0, 0), eventPlayer.getEyePosition(), 0)
    eventPlayer.setPrimaryFireEnabled(false)
    eventPlayer.setAbility1Enabled(false)
    eventPlayer.setReloadEnabled(false)
    eventPlayer.RodBaseOffset = ROD_BASE_OFFSET
    eventPlayer.RodTipOffset = ROD_TIP_OFFSET
    eventPlayer.RodPivotOffset = ROD_PIVOT_OFFSET
    ResetFishing()

    createEffect(
        getAllPlayers(),
        Effect.SPHERE,
        Color.RED,
        eventPlayer.BobberPosition,
        BOBBER_RADIUS,
        EffectReeval.VISIBILITY_POSITION_AND_RADIUS
    )
    createBeam(
        getAllPlayers(),
        Beam.GRAPPLE,
        eventPlayer.getEyePosition()
        + worldVector(
            eventPlayer.RodVisualBaseOffset,
            eventPlayer,
            Transform.ROTATION
        ),
        eventPlayer.getEyePosition()
        + worldVector(
            eventPlayer.RodVisualTipOffset,
            eventPlayer,
            Transform.ROTATION
        ),
        Color.WHITE,
        EffectReeval.POSITION_AND_RADIUS
    )
    createBeam(
        getAllPlayers(),
        Beam.GRAPPLE,
        eventPlayer.getEyePosition()
        + worldVector(
            eventPlayer.RodVisualTipOffset,
            eventPlayer,
            Transform.ROTATION
        ),
        eventPlayer.BobberPosition + 0.5 * BOBBER_RADIUS * Vector.UP,
        Color.WHITE,
        EffectReeval.VISIBILITY_POSITION_AND_RADIUS
    )


def ResetFishing():
    @Name "Reset Fishing"

    eventPlayer.RodRotationAngle = eventPlayer.getNeutralRodRotation()
    eventPlayer.RodAngularVelocity = 0
    eventPlayer.updateRodVisualOffsets()
    
    eventPlayer.FishingLineLength = PRE_RELEASE_LINE_LENGTH
    eventPlayer.BobberPosition = (
        eventPlayer.getRodTipPosition()
        + Vector.DOWN * eventPlayer.FishingLineLength
    )

    eventPlayer.PreviousBobberPosition = eventPlayer.BobberPosition
    eventPlayer.BobberVelocity = vect(0, 0, 0)

    eventPlayer.ScheduledBiteTime = 0
    eventPlayer.HookWindowEndTime = 0

    eventPlayer.setFishingActionState(FishingActionState.READY)
    eventPlayer.setFishInteractionState(FishInteractionState.NONE)


rule "Ability 1 Fishing Input":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.ABILITY_1) == true

    if (eventPlayer.FishingActionState == FishingActionState.READY):
        eventPlayer.PreviousBobberPosition = eventPlayer.BobberPosition
        eventPlayer.setFishingActionState(FishingActionState.CHARGING)


rule "Reload Fishing Input":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.RELOAD) == true

    if eventPlayer.FishInteractionState == FishInteractionState.BITE:
        eventPlayer.setFishInteractionState(FishInteractionState.REELING)

        # Placeholder reeling result.
        wait(0.5)
        eventPlayer.setFishInteractionState(FishInteractionState.CATCH_COMPLETE)
        smallMessage(eventPlayer, "Caught a fish!")

        wait(0.75)
        ResetFishing()

        
rule "Start Forward Swing":
    @Event eachPlayer
    @Condition eventPlayer.FishingActionState == FishingActionState.CHARGING
    @Condition eventPlayer.isHoldingButton(Button.ABILITY_1) == false

    eventPlayer.CastCharge = eventPlayer.getEffectiveCastCharge()
    eventPlayer.setFishingActionState(FishingActionState.SWINGING)


rule "Update Rod Motion":
    @Event eachPlayer

    eventPlayer.RodAngularVelocity += (
        (
            ROD_ANGULAR_RESPONSE ** 2
            * (
                eventPlayer.getRodTargetRotation()
                - eventPlayer.RodRotationAngle
            )
        )
        - (
            2
            * ROD_ANGULAR_RESPONSE
            * eventPlayer.RodAngularVelocity
        )
    ) * BOBBER_TICK

    eventPlayer.RodRotationAngle += (
        eventPlayer.RodAngularVelocity
        * BOBBER_TICK
    )

    eventPlayer.updateRodVisualOffsets()

    wait(BOBBER_TICK)

    loop()


rule "Release Fishing Line":
    @Event eachPlayer
    @Condition eventPlayer.FishingActionState == FishingActionState.SWINGING
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE) == false

    LaunchBobber()


rule "Update Bobber Motion":
    @Event eachPlayer
    @Condition eventPlayer.FishingActionState > FishingActionState.UNINITIALIZED
    @Condition eventPlayer.FishInteractionState != FishInteractionState.BITE

    UpdateBobberMotion()

    wait(BOBBER_TICK)

    if ruleCondition:
        loop()


rule "Start Fishing Bite Timer":
    @Event eachPlayer

    @Condition eventPlayer.hasSpawned() == true
    @Condition eventPlayer.FishingActionState > FishingActionState.UNINITIALIZED
    @Condition eventPlayer.FishInteractionState == FishInteractionState.NONE
    @Condition eventPlayer.BobberState == BobberState.WATER
    @Condition eventPlayer.ScheduledBiteTime == 0

    eventPlayer.ScheduledBiteTime = (
        getTotalTimeElapsed()
        + random.uniform(
            MIN_BITE_TIME,
            MAX_BITE_TIME
        )
    )


rule "Cancel Fishing Bite Timer":
    @Event eachPlayer

    @Condition eventPlayer.BobberState != BobberState.WATER
    @Condition eventPlayer.ScheduledBiteTime > 0

    eventPlayer.ScheduledBiteTime = 0


def UpdateBobberMotion():
    @Name "Update Bobber Motion"

    eventPlayer.PreviousBobberPosition = eventPlayer.BobberPosition

    # Physical behaviour based on where the bobber is.

    if eventPlayer.BobberState == BobberState.WATER:
        eventPlayer.BobberVelocity += (
            Vector.UP
            * (
                WATER_SPRING_STRENGTH
                * (
                    (
                        eventPlayer.BobberSurfacePosition.y
                        - WAITING_BOB_AMPLITUDE
                        * sinDeg(
                            getTotalTimeElapsed()
                            / WAITING_BOB_PERIOD
                            * 360
                        )
                    )
                    - eventPlayer.BobberPosition.y
                )
                - WATER_DAMPING
                * eventPlayer.BobberVelocity.y
            )
            * BOBBER_TICK
        )

        eventPlayer.BobberPosition += (
            eventPlayer.BobberVelocity
            * BOBBER_TICK
        )

    elif eventPlayer.BobberState == BobberState.AIRBORNE:
        eventPlayer.BobberVelocity += (
            Vector.DOWN
            * BOBBER_GRAVITY
            * BOBBER_TICK
        )

        eventPlayer.BobberPosition += (
            eventPlayer.BobberVelocity
            * BOBBER_TICK
        )

    elif eventPlayer.BobberState == BobberState.LAND:
        eventPlayer.BobberVelocity = vect(0, 0, 0)


    # Apply the fishing-line constraint independently of bobber environment.

    if (
        eventPlayer.FishingActionState == FishingActionState.READY
        or eventPlayer.FishingActionState == FishingActionState.CHARGING
        or (
            eventPlayer.FishingActionState == FishingActionState.SWINGING
            and eventPlayer.isHoldingButton(Button.PRIMARY_FIRE)
        )
    ):
        if distance(
            eventPlayer.BobberPosition,
            eventPlayer.getRodTipPosition()
        ) > eventPlayer.FishingLineLength:
            eventPlayer.BobberPosition = (
                eventPlayer.getRodTipPosition()
                + normalize(
                    eventPlayer.BobberPosition
                    - eventPlayer.getRodTipPosition()
                )
                * eventPlayer.FishingLineLength
            )

            eventPlayer.BobberVelocity = (
                eventPlayer.BobberPosition
                - eventPlayer.PreviousBobberPosition
            ) / BOBBER_TICK

            eventPlayer.BobberVelocity = [
                directionTowards(
                    eventPlayer.getRodTipPosition(),
                    eventPlayer.BobberPosition
                )
            ].map(
                lambda lineDirection:
                    (
                        lineDirection
                        * dotProduct(
                            eventPlayer.BobberVelocity,
                            lineDirection
                        )
                    )
                    + (
                        eventPlayer.BobberVelocity
                        - (
                            lineDirection
                            * dotProduct(
                                eventPlayer.BobberVelocity,
                                lineDirection
                            )
                        )
                    ) * TETHERED_BOBBER_DAMPING
            )[0]

            return

    eventPlayer.BobberVelocity = (
        eventPlayer.BobberPosition
        - eventPlayer.PreviousBobberPosition
    ) / BOBBER_TICK


rule "Fishing Bite":
    @Event eachPlayer
    @Condition eventPlayer.FishInteractionState == FishInteractionState.NONE
    @Condition eventPlayer.ScheduledBiteTime > 0
    @Condition getTotalTimeElapsed() > eventPlayer.ScheduledBiteTime
    @Condition eventPlayer.BobberState == BobberState.WATER

    eventPlayer.setFishInteractionState(FishInteractionState.BITE)
    eventPlayer.ScheduledBiteTime = 0
    eventPlayer.HookWindowEndTime = eventPlayer.FishInteractionStateEntryTimes[FishInteractionState.BITE] + HOOK_WINDOW

    playEffect(
        eventPlayer,
        DynamicEffect.DEBUFF_IMPACT_SOUND,
        Color.WHITE,
        eventPlayer.BobberPosition,
        80
    )

    eventPlayer.BobberVelocity = vect(0, 0, 0)
    eventPlayer.BiteStartPosition = eventPlayer.BobberPosition


rule "Cancel Bite When Bobber Leaves Water":
    @Event eachPlayer
    @Condition eventPlayer.FishInteractionState == FishInteractionState.BITE
    @Condition eventPlayer.BobberState != BobberState.WATER

    eventPlayer.ScheduledBiteTime = 0
    eventPlayer.HookWindowEndTime = 0
    eventPlayer.BobberVelocity = vect(0, 0, 0)
    eventPlayer.setFishInteractionState(FishInteractionState.NONE)


rule "Bite Bobber Animation":
    @Event eachPlayer
    @Condition eventPlayer.FishInteractionState == FishInteractionState.BITE

    eventPlayer.BobberPosition = (
        eventPlayer.BiteStartPosition
        + Vector.DOWN
        * BITE_DIP_DISTANCE
        * smoothstep(
            min(
                (
                    getTotalTimeElapsed()
                    - eventPlayer.FishInteractionStateEntryTimes[FishInteractionState.BITE]
                ) / BITE_DIP_TIME,
                1
            )
        )
    )

    wait(BOBBER_TICK)

    if ruleCondition:
        loop()


rule "Fishing Hook Missed":
    @Event eachPlayer
    @Condition eventPlayer.FishInteractionState == FishInteractionState.BITE
    @Condition getTotalTimeElapsed() > eventPlayer.HookWindowEndTime

    eventPlayer.HookWindowEndTime = 0
    eventPlayer.ScheduledBiteTime = 0
    eventPlayer.BobberVelocity = vect(0, 0, 0)
    eventPlayer.setFishInteractionState(FishInteractionState.NONE)


rule "Reel Fishing Line":
    @Event eachPlayer
    @Condition eventPlayer.FishingLineLength > PRE_RELEASE_LINE_LENGTH
    @Condition eventPlayer.FishInteractionState == FishInteractionState.NONE
    @Condition eventPlayer.FishingActionState != FishingActionState.SWINGING
    @Condition eventPlayer.FishingActionState != FishingActionState.CASTING
    @Condition eventPlayer.isHoldingButton(Button.RELOAD)

    eventPlayer.FishingLineLength = max(
        eventPlayer.FishingLineLength
        - REEL_SPEED * BOBBER_TICK,
        PRE_RELEASE_LINE_LENGTH
    )

    wait(BOBBER_TICK)

    if ruleCondition:
        loop()


rule "Set Bobber State To Water":
    @Event eachPlayer

    @Condition eventPlayer.BobberState != BobberState.WATER
    @Condition eventPlayer.isBobberInWater() == true

    eventPlayer.BobberSurfacePosition = vect(
        eventPlayer.BobberPosition.x,
        0,
        eventPlayer.BobberPosition.z
    )

    eventPlayer.BobberVelocity = vect(
        0,
        eventPlayer.BobberVelocity.y,
        0
    )

    eventPlayer.BobberState = BobberState.WATER


rule "Set Bobber State To Airborne":
    @Event eachPlayer
    @Condition eventPlayer.BobberState != BobberState.AIRBORNE
    @Condition eventPlayer.BobberPosition.y > BOBBER_RADIUS

    eventPlayer.BobberState = BobberState.AIRBORNE


rule "Set Bobber State To Land":
    @Event eachPlayer
    @Condition eventPlayer.BobberState != BobberState.LAND
    @Condition eventPlayer.isBobberInWater() == false
    @Condition eventPlayer.BobberPosition.y <= 0

    eventPlayer.BobberPosition = vect(
            eventPlayer.BobberPosition.x,
            0,
            eventPlayer.BobberPosition.z
        )
    eventPlayer.BobberVelocity = vect(0, 0, 0)
    eventPlayer.BobberState = BobberState.LAND


rule "Finish Cast":
    @Event eachPlayer
    @Condition eventPlayer.BobberState != BobberState.AIRBORNE
    @Condition eventPlayer.FishingActionState == FishingActionState.SWINGING or eventPlayer.FishingActionState == FishingActionState.CASTING

    eventPlayer.FishingLineLength = distance(
        eventPlayer.getRodTipPosition(),
        eventPlayer.BobberPosition
    )

    eventPlayer.setFishingActionState(
        FishingActionState.READY
    )


rule "Adjust Rod Offset X/Z":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true

    eventPlayer.RodPivotOffset += vect(
        eventPlayer.getThrottle().x,
        0,
        eventPlayer.getThrottle().z
    ) * 0.05

    wait(0.1)

    if ruleCondition:
        loop()


rule "Adjust Rod Offset Y":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true

    if eventPlayer.isHoldingButton(Button.JUMP):
        eventPlayer.RodPivotOffset += vect(0, 0.05, 0)

    if eventPlayer.isHoldingButton(Button.CROUCH):
        eventPlayer.RodPivotOffset += vect(0, -0.05, 0)

    wait(0.1)

    if ruleCondition:
        loop()