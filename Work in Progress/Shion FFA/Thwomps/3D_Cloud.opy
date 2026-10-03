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

    macro HORIZONTAL_PADDING = 25
    macro VERTICAL_PADDING = 10

    macro CLOUD_SPACING = 5
    macro MIN_POINT_SPACING = 4


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
    # CLOUD SCAN VARIABLES
    # ============================================================

    globalvar MinBounds
    globalvar MaxBounds

    globalvar SpawnPosition
    globalvar CloudPoint
    globalvar WalkablePoint

    globalvar ScanX
    globalvar ScanY
    globalvar ScanZ

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

    rule "Scan Walkable Positions - 3D Cloud":
        SpawnPoints = getSpawnPoints(Team.ALL)
        DiscoveredPoints = []
        ScanComplete = false

        MinBounds = SpawnPoints[0].getPosition()
        MaxBounds = SpawnPoints[0].getPosition()

        for i in range(len(SpawnPoints)):
            SpawnPosition = SpawnPoints[i].getPosition()

            MinBounds = vect(
                min(MinBounds.x, SpawnPosition.x),
                min(MinBounds.y, SpawnPosition.y),
                min(MinBounds.z, SpawnPosition.z)
            )

            MaxBounds = vect(
                max(MaxBounds.x, SpawnPosition.x),
                max(MaxBounds.y, SpawnPosition.y),
                max(MaxBounds.z, SpawnPosition.z)
            )

        MinBounds -= vect(
            HORIZONTAL_PADDING,
            VERTICAL_PADDING,
            HORIZONTAL_PADDING
        )

        MaxBounds += vect(
            HORIZONTAL_PADDING,
            VERTICAL_PADDING,
            HORIZONTAL_PADDING
        )

        ScanX = MinBounds.x

        while ScanX <= MaxBounds.x:
            ScanY = MinBounds.y

            while ScanY <= MaxBounds.y:
                ScanZ = MinBounds.z

                while ScanZ <= MaxBounds.z:
                    CloudPoint = vect(ScanX, ScanY, ScanZ)
                    WalkablePoint = nearestWalkablePosition(CloudPoint)

                    if len(
                        DiscoveredPoints.filter(
                            lambda point:
                                distance(point, WalkablePoint)
                                < MIN_POINT_SPACING
                        )
                    ) == 0:
                        DiscoveredPoints.append(WalkablePoint)

                    ScanZ += CLOUD_SPACING
                    wait()

                ScanY += CLOUD_SPACING

            ScanX += CLOUD_SPACING

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