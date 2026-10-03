settings {
    "lobby": {
        "ffaSlots": 11
    },
    "gamemodes": {
        "ffa": {}
    }
}

#Global variables

globalvar SpawnPoints 0
globalvar DiscoveredPoints 1
globalvar MinBounds 2
globalvar MaxBounds 3
globalvar SpawnPosition 4
globalvar CloudPoint 5
globalvar WalkablePoint 6
globalvar i 7
globalvar ScanX 8
globalvar ScanY 9
globalvar ScanZ 10

#Activated extensions

#!extension playMoreEffects


#Only remove the following directive if the gamemode does not use tricks such as A+0, A*0, A or "", "am" == "**", etc which would otherwise be optimized out.
#!optimizeStrict

rule "Scan Walkable Positions":
    SpawnPoints = getSpawnPoints(Team.ALL)
    DiscoveredPoints = []
    MinBounds = SpawnPoints[0].getPosition()
    MaxBounds = SpawnPoints[0].getPosition()
    #Find the bounding box containing all spawn points.
    for i in range(len(SpawnPoints)):
        SpawnPosition = SpawnPoints[i].getPosition()
        MinBounds = vect(min(MinBounds.x, SpawnPosition.x), min(MinBounds.y, SpawnPosition.y), min(MinBounds.z, SpawnPosition.z))
        MaxBounds = vect(max(MaxBounds.x, SpawnPosition.x), max(MaxBounds.y, SpawnPosition.y), max(MaxBounds.z, SpawnPosition.z))
    #Expand the box beyond the outermost spawn points.
    MinBounds -= vect(25, 10, 25)
    MaxBounds += vect(25, 10, 25)
    #This should reevaluate as DiscoveredPoints grows.
    hudHeader(getAllPlayers(), "Discovered points: {0}".format(len(DiscoveredPoints)))
    ScanX = MinBounds.x
    while ScanX <= MaxBounds.x:
        ScanY = MinBounds.y
        while ScanY <= MaxBounds.y:
            ScanZ = MinBounds.z
            while ScanZ <= MaxBounds.z:
                CloudPoint = vect(ScanX, ScanY, ScanZ)
                WalkablePoint = nearestWalkablePosition(CloudPoint)
                if WalkablePoint != null and len(DiscoveredPoints.filter(lambda x: distance(x, WalkablePoint) < 4)) == 0:
                    DiscoveredPoints.append(WalkablePoint)
                    createEffect(getAllPlayers(), Effect.SPHERE, Color.RED, WalkablePoint + Vector.UP, 0.2, EffectReeval.VISIBILITY)
                ScanZ += 5
                wait()
            ScanY += 5
        ScanX += 5


