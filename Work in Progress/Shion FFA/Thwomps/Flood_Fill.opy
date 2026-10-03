settings {
    "gamemodes": {
        "ffa": {
            "enabled": true
        }
    }
}


# ============================================================
# SCAN SETTINGS
# ============================================================

macro STEP_DISTANCE = 4
macro MAX_PROJECTION_DISTANCE = 2
macro MIN_POINT_SPACING = 3


# ============================================================
# VISUALIZATION SETTINGS
# ============================================================

macro DISPLAY_COUNT = 128

macro POINT_HEIGHT = 1
macro POINT_RADIUS = 0.2

macro HIDDEN_POSITION = vect(0, -10000, 0)


# ============================================================
# SHARED DATA
# ============================================================

globalvar SpawnPoints
globalvar DiscoveredPoints
globalvar ScanComplete


# ============================================================
# FLOOD FILL VARIABLES
# ============================================================

globalvar ScanDirections

globalvar ScanIndex
globalvar CurrentPoint
globalvar CandidatePoint
globalvar WalkablePoint

globalvar i


# ============================================================
# VISUALIZATION VARIABLES
# ============================================================

globalvar DisplayPage
globalvar DisplayPageCount
globalvar DisplaySlot


# ============================================================
# VISUALIZATION HELPERS
# ============================================================

macro DisplayPointIndex(slot):
    DisplayPage * DISPLAY_COUNT + slot

macro DisplaySlotActive(slot):
    DisplayPointIndex(slot) < len(DiscoveredPoints)

macro DisplayPointPosition(slot):
    (
        DiscoveredPoints[DisplayPointIndex(slot)] + Vector.UP * POINT_HEIGHT
        if DisplaySlotActive(slot)
        else HIDDEN_POSITION
    )


# ============================================================
# SCANNING
# ============================================================

rule "Scan Walkable Positions - Flood Fill":
    SpawnPoints = getSpawnPoints(Team.ALL)
    DiscoveredPoints = []
    ScanComplete = false

    ScanDirections = [
        vect(1, 0, 0),
        vect(-1, 0, 0),
        vect(0, 0, 1),
        vect(0, 0, -1),
        vect(0.707, 0, 0.707),
        vect(0.707, 0, -0.707),
        vect(-0.707, 0, 0.707),
        vect(-0.707, 0, -0.707)
    ]

    # Seed directly from the FFA spawn positions.
    for i in range(len(SpawnPoints)):
        WalkablePoint = SpawnPoints[i].getPosition()

        if len(
            DiscoveredPoints.filter(
                lambda point:
                    distance(point, WalkablePoint)
                    < MIN_POINT_SPACING
            )
        ) == 0:
            DiscoveredPoints.append(WalkablePoint)

    ScanIndex = 0

    while ScanIndex < len(DiscoveredPoints):
        CurrentPoint = DiscoveredPoints[ScanIndex]

        for i in range(len(ScanDirections)):
            CandidatePoint = CurrentPoint + ScanDirections[i] * STEP_DISTANCE
            WalkablePoint = nearestWalkablePosition(CandidatePoint)

            if (
                distance(CandidatePoint, WalkablePoint)
                <= MAX_PROJECTION_DISTANCE
                and len(
                    DiscoveredPoints.filter(
                        lambda point:
                            distance(point, WalkablePoint)
                            < MIN_POINT_SPACING
                    )
                ) == 0
            ):
                DiscoveredPoints.append(WalkablePoint)

            wait()

        ScanIndex++

    ScanComplete = true


# ============================================================
# VISUALIZATION
# ============================================================

rule "Initialize Point Visualization":
    @Condition ScanComplete == true

    DisplayPage = 0
    DisplayPageCount = max(
        1,
        ceil(len(DiscoveredPoints) / DISPLAY_COUNT)
    )

    hudHeader(
        getAllPlayers(),
        "Discovered: {}\nPage: {} / {}".format(
            len(DiscoveredPoints),
            DisplayPage + 1,
            DisplayPageCount
        ),
        color=Color.WHITE
    )

    for DisplaySlot in range(DISPLAY_COUNT):
        createEffect(
            (
                getAllPlayers()
                if DisplaySlotActive(evalOnce(DisplaySlot))
                else []
            ),
            Effect.SPHERE,
            Color.RED,
            DisplayPointPosition(evalOnce(DisplaySlot)),
            POINT_RADIUS,
            EffectReeval.VISIBILITY_POSITION_AND_RADIUS
        )


rule "Next Visualization Page":
    @Event eachPlayer
    @Condition ScanComplete == true
    @Condition eventPlayer.isHoldingButton(Button.INTERACT) == true

    DisplayPage++

    if DisplayPage >= DisplayPageCount:
        DisplayPage = 0