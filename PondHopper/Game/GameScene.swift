import SpriteKit

@MainActor
final class GameScene: SKScene, SKPhysicsContactDelegate {
    override var isUserInteractionEnabled: Bool {
        get { true }
        set { }
    }

    private weak var eventSink: (any GameSceneEventSink)?

    private var tutorialSection: Int?
    private let includesTutorialPath: Bool
    private var scoreOriginRow = 0
    private var lastNearMissTime = -10.0
    private var tutorialTextures: [String: SKTexture] = [:]
    private var pondIsUrgent = false
    private var tutorialStep: TutorialStep?
    private let tutorialTarget = SKShapeNode()
    private let tutorialTrafficWarning = SKNode()
    private var tutorialBlockedMove = false

    private let config: GameConfig
    private let seed: UInt64
    private let generator: WorldGenerator
    private let worldNode = SKNode()
    private let cameraNode = SKCameraNode()
    private let playerNode = SKSpriteNode()

    private var expansionTask: Task<Void, Never>?
    private static var sharedTextures: [String: SKTexture] = [:]
    private var blueprint: WorldBlueprint
    private var movementRules: GridMovementRules
    private var fishTextures: [SKTexture] = []
    private var pondTextures: [SKTexture] = []
    private var drainedPondTexture: SKTexture?
    private var trailNodes: [FishTrailMarkNode] = []
    private var rowNodes: [Int: SKNode] = [:]
    private var pondNodes: [Int: SKSpriteNode] = [:]
    private var vehicleNodes: [VehicleSpawnKey: SKSpriteNode] = [:]
    private var vehiclePassByTracker = VehiclePassByTracker()
    private var previousPlayerCollisionCenter: CGPoint?
    private var previousVehicleCollisionCenters: [VehicleSpawnKey: CGPoint] = [:]
    private var targetRingNode: SKShapeNode?

    private var movementQueue = MovementQueue()
    private var isHopProtected = false
    private var breathMeter: BreathMeter
    private var breathWarningTracker: CriticalBreathWarningTracker
    private var scoreTracker = ScoreTracker()
    private var playerPosition: GridPosition
    private var currentTargetPondID: Int?
    private var fishOrientation = FishSpriteOrientation()
    private var movementStartOrientation = FishSpriteOrientation()
    private var activeRestingAnimationState: FishRestingAnimationState?

    private var tileSize = 1.0
    private var rowHeight = 1.0
    private var rowOriginY = 0.0
    private var furthestCameraY = 0.0
    private var lastUpdateTime = 0.0
    private var simulationElapsed = 0.0
    private var hudPublishAccumulator = 0.0
    private var touchStartPoint: CGPoint?
    private var lastPublishedTargetDirection: MoveDirection?

    private var isWorldReady = false
    private var isSimulationRunning = false
    private var isSimulationPaused = true
    private var didEndRun = false
    private var reduceMotion = false

    init(
        config: GameConfig,
        seed: UInt64,
        eventSink: any GameSceneEventSink,
        tutorialSection: Int? = nil
    ) {
        self.tutorialSection = tutorialSection
        includesTutorialPath = tutorialSection != nil
        self.config = config
        self.seed = seed
        generator = WorldGenerator(config: config)

        let normalWorld = generator.generate(seed: seed, rowCount: 48)
        let generatedBlueprint = tutorialSection != nil
            ? TutorialWorld.prepend(to: normalWorld, columns: config.columns) : normalWorld
        blueprint = generatedBlueprint
        movementRules = GridMovementRules(
            columnCount: config.columns,
            maximumRow: generatedBlueprint.maximumRow,
            obstacles: Set(generatedBlueprint.obstacles.keys)
        )
        playerPosition = GridPosition(column: config.columns / 2, row: 2)
        breathMeter = BreathMeter(maximum: config.maximumBreath)
        breathWarningTracker = CriticalBreathWarningTracker(maximumBreath: config.maximumBreath)

        super.init(size: CGSize(width: 390, height: 844))

        self.eventSink = eventSink

        scaleMode = .resizeFill
        backgroundColor = Self.grassColor
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        isPaused = true

        addChild(worldNode)
        addChild(cameraNode)
        camera = cameraNode
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("GameScene must be created with a game configuration and seed.")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = false
        buildWorldIfNeeded()
        // Presenting into a view can reset SpriteKit's own pause flag.
        applyPauseState()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        guard isWorldReady, oldSize != size else { return }
        rebuildVisualWorld()
    }

    /// Freezes or unfreezes the whole scene.
    ///
    /// `isSimulationPaused` is the authoritative pause flag, not `isPaused`.
    /// `isPaused` belongs to SpriteKit: `SKView` clears it when the app returns
    /// from the background and when the hosting `SpriteView` rebuilds the view,
    /// so it cannot be trusted to keep a pause in place. Keeping our own flag
    /// lets `update()` re-assert the pause if SpriteKit clears it behind us.
    ///
    /// Unpausing deliberately does not resume gameplay. Whether gameplay runs is
    /// owned by `setGameplayRunning(_:)`, so a resume can never promote the
    /// waiting or game-over world into a live run.
    func setSimulationPaused(_ shouldPause: Bool) {
        let didChange = isSimulationPaused != shouldPause
        isSimulationPaused = shouldPause
        applyPauseState()
        guard didChange else { return }
        lastUpdateTime = 0
        touchStartPoint = nil
        resetCollisionHistory()
    }

    func setGameplayRunning(_ isRunning: Bool) {
        let shouldRun = isRunning && !didEndRun
        let didChange = isSimulationRunning != shouldRun || isSimulationPaused
        isSimulationRunning = shouldRun
        isSimulationPaused = false
        applyPauseState()
        // Tutorial instructions sync after each arrival. Preserve a new touch
        // and the frame clock when the simulation is already running.
        guard didChange else { return }
        lastUpdateTime = 0
        touchStartPoint = nil
        resetCollisionHistory()
    }

    /// Pushes `isSimulationPaused` onto the SpriteKit nodes. Safe to call every
    /// frame; assigning the same value is a no-op for SpriteKit.
    private func applyPauseState() {
        isPaused = isSimulationPaused
        worldNode.isPaused = isSimulationPaused
        cameraNode.isPaused = isSimulationPaused
    }

    /// True only while a run is live and not paused. Every gameplay entry point
    /// gates on this so a paused run cannot accept input.
    private var isAcceptingGameplayInput: Bool {
        isSimulationRunning && !isSimulationPaused && !didEndRun
    }

    func setTutorialStep(_ step: TutorialStep) {
        tutorialStep = step
        refreshTutorialTarget()
    }

    func finishTutorial() {
        tutorialSection = nil
        tutorialStep = nil
        tutorialTarget.removeFromParent()
        tutorialTrafficWarning.removeFromParent()
        scoreOriginRow = TutorialWorld.pondRow
        eventSink?.receive(.breathChanged(breathMeter.remaining))
    }

    func retryTutorialArea() {
        guard let step = tutorialStep else { return }
        playerNode.removeAllActions()
        movementQueue.reset()
        isHopProtected = false
        didEndRun = false
        tutorialBlockedMove = false
        let row = step == .pond ? 8 : 5
        playerPosition = GridPosition(column: config.columns / 2 + 1, row: row)
        breathMeter = BreathMeter(maximum: config.maximumBreath)
        breathWarningTracker = CriticalBreathWarningTracker(maximumBreath: config.maximumBreath)
        scoreTracker = ScoreTracker()
        _ = scoreTracker.record(row: row)
        furthestCameraY = size.height / 2
        rebuildVisualWorld()
        eventSink?.receive(.breathChanged(breathMeter.remaining))
        refreshTutorialTarget()
    }

    private func refreshTutorialTarget() {
        guard tutorialSection != nil else { return }
        tutorialTarget.removeFromParent()
        tutorialTrafficWarning.removeFromParent()
        tutorialTrafficWarning.removeAllChildren()
        tutorialTrafficWarning.removeAllActions()
        if tutorialStep == .traffic && playerPosition.row <= 6 {
            tutorialTrafficWarning.removeAllChildren()
            for (text, fontSize, y) in [("!", 46.0, 12.0), ("WATCH FOR CARS", 16.0, -20.0)] {
                let shadow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
                shadow.text = text
                shadow.fontSize = fontSize
                shadow.fontColor = .black
                shadow.position = CGPoint(x: 1.5, y: y - 2)
                let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
                label.text = text
                label.fontSize = fontSize
                label.fontColor = .yellow
                label.zPosition = 1
                label.position = CGPoint(x: 0, y: y)
                tutorialTrafficWarning.addChild(shadow)
                tutorialTrafficWarning.addChild(label)
            }
            tutorialTrafficWarning.position = point(for: GridPosition(column: config.columns / 2, row: 8))
            tutorialTrafficWarning.zPosition = 10
            worldNode.addChild(tutorialTrafficWarning)
        }
        if let step = tutorialStep, case .movement = step {
            let gesture = SKNode()
            func addIcon(_ asset: String, width: CGFloat, height: CGFloat, y: CGFloat) {
                let texture: SKTexture
                if let cached = tutorialTextures[asset] {
                    texture = cached
                } else {
                    guard let image = UIImage(named: asset) else { return }
                    texture = SKTexture(image: image)
                    tutorialTextures[asset] = texture
                }
                let icon = SKSpriteNode(texture: texture)
                icon.color = .white
                icon.colorBlendFactor = 1
                icon.size = CGSize(width: width, height: height)
                icon.position.y = y
                gesture.addChild(icon)
            }
            if case .movement = step {
                let isTap = step == .movement(0)
                addIcon(step.gestureAsset, width: isTap ? 78 : 36, height: isTap ? 78 : 36, y: isTap ? 0 : 38)
                if !isTap {
                    addIcon("tutorial-hand-move", width: 68, height: 68, y: -12)
                }
            }
            tutorialTrafficWarning.addChild(gesture)
            let row = 8
            tutorialTrafficWarning.position = point(for: GridPosition(column: config.columns / 2, row: row))
            tutorialTrafficWarning.zPosition = 10
            worldNode.addChild(tutorialTrafficWarning)
            if !reduceMotion {
                let animation: SKAction
                if case .movement(let index) = step, index != 0 {
                    let direction = step.expectedDirection
                    let dx: CGFloat = direction == .left ? -16 : direction == .right ? 16 : 0
                    let dy: CGFloat = direction == .down ? -16 : direction == .up ? 16 : 0
                    animation = .sequence([.moveBy(x: dx, y: dy, duration: 0.5), .moveBy(x: -dx, y: -dy, duration: 0.5)])
                } else {
                    animation = .sequence([.scale(to: 0.85, duration: 0.5), .scale(to: 1, duration: 0.5)])
                }
                gesture.run(.repeatForever(animation))
            }
        }
        guard let step = tutorialStep else { return }
        let destination: GridPosition
        if let direction = step.expectedDirection { destination = playerPosition.moved(direction) }
        else if step == .traffic { destination = playerPosition.moved(.up) }
        else if let pond = blueprint.ponds.first { destination = pond.position }
        else { return }
        tutorialTarget.path = CGPath(roundedRect: CGRect(x: -tileSize * 0.44, y: -rowHeight * 0.44,
            width: tileSize * 0.88, height: rowHeight * 0.88), cornerWidth: 8, cornerHeight: 8, transform: nil)
        tutorialTarget.fillColor = SKColor.yellow.withAlphaComponent(0.20)
        tutorialTarget.strokeColor = .white
        tutorialTarget.lineWidth = 3
        tutorialTarget.zPosition = 9
        tutorialTarget.position = point(for: destination)
        worldNode.addChild(tutorialTarget)
    }

    func setReduceMotion(_ isEnabled: Bool) {
        reduceMotion = isEnabled
        refreshTutorialTarget()
        refreshAmbientAnimations()
        refreshPlayerRestingAnimation(force: true)
    }

    func enqueueMovement(_ direction: MoveDirection) {
        guard isAcceptingGameplayInput else { return }
        if tutorialSection != nil {
            guard movementQueue.activeDirection == nil, tutorialStep != nil else { return }
            if let expected = tutorialStep?.expectedDirection, direction != expected {
                eventSink?.receive(.tutorialWrongInput)
                return
            }
        }
        guard let movement = movementQueue.enqueue(direction) else { return }
        beginMovement(movement)
    }

    override func update(_ currentTime: TimeInterval) {
        // Reaching update() while paused means SpriteKit cleared `isPaused`
        // behind us (foregrounding, or the hosting SpriteView rebuilding its
        // SKView). Re-assert the pause instead of silently resuming.
        guard !isSimulationPaused else {
            applyPauseState()
            lastUpdateTime = 0
            resetCollisionHistory()
            return
        }

        guard lastUpdateTime > 0 else {
            lastUpdateTime = currentTime
            resetCollisionHistory()
            return
        }

        let deltaTime = min(max(0, currentTime - lastUpdateTime), 1.0 / 15.0)
        lastUpdateTime = currentTime
        simulationElapsed += deltaTime
        updateVehicles()

        guard isSimulationRunning, !didEndRun else {
            captureCollisionSample()
            return
        }

        if detectsSweptVehicleCollision() {
            finishRun(reason: .vehicleCollision)
            captureCollisionSample()
            return
        }

        updateVehiclePassFeedback()
        captureCollisionSample()
        updateFishTrail(deltaTime: deltaTime)
        updateBreath(deltaTime: deltaTime)
        publishHUDIfNeeded(deltaTime: deltaTime)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let playerAndVehicle = PhysicsCategory.player | PhysicsCategory.vehicle

        guard categories == playerAndVehicle, !isHopProtected, isAcceptingGameplayInput else { return }
        finishRun(reason: .vehicleCollision)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isAcceptingGameplayInput, touchStartPoint == nil, let touch = touches.first else { return }
        touchStartPoint = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            isAcceptingGameplayInput,
            let startPoint = touchStartPoint,
            let touch = touches.first
        else {
            touchStartPoint = nil
            return
        }

        touchStartPoint = nil
        let endPoint = touch.location(in: self)
        let horizontalDistance = endPoint.x - startPoint.x
        let verticalDistance = endPoint.y - startPoint.y
        enqueueGesture(
            horizontalDistance: horizontalDistance,
            verticalDistance: verticalDistance
        )
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPoint = nil
    }

    func enqueueGesture(horizontalDistance: Double, verticalDistance: Double) {
        let swipeThreshold = max(24, tileSize * 0.35)

        if hypot(horizontalDistance, verticalDistance) < swipeThreshold {
            enqueueMovement(.up)
        } else if abs(horizontalDistance) > abs(verticalDistance) {
            enqueueMovement(horizontalDistance > 0 ? .right : .left)
        } else {
            enqueueMovement(verticalDistance > 0 ? .up : .down)
        }
    }

    private func buildWorldIfNeeded() {
        guard !isWorldReady else { return }

        isWorldReady = true
        if let pond = blueprint.pond(at: playerPosition) {
            _ = breathMeter.visitPond(id: pond.id, adding: 0)
        }
        currentTargetPondID = selectTargetPondID()
        loadTextures()
        rebuildVisualWorld()
        publishInitialSnapshot()
        ensureBlueprintAhead()
    }

    private func loadTextures() {
        fishTextures = (1...FishAnimationContract.frameCount).map {
            texture(named: "fish-flop-\($0)")
        }

        drainedPondTexture = texture(named: "pond-drained")
        pondTextures = (0..<4).map {
            texture(named: "pond-idle-\($0)")
        }
    }

    private func rebuildVisualWorld() {
        worldNode.removeAllChildren()
        trailNodes.removeAll()
        playerNode.removeAllActions()
        rowNodes.removeAll()
        pondNodes.removeAll()
        vehicleNodes.removeAll()
        targetRingNode = nil
        movementQueue.reset()
        isHopProtected = false
        activeRestingAnimationState = nil

        tileSize = size.width / Double(config.columns)
        rowHeight = tileSize * 1.2
        rowOriginY = rowHeight * 1.35

        updateRenderedRows(force: true)
        configurePlayerNode()
        playerNode.position = point(for: playerPosition)
        worldNode.addChild(playerNode)

        cameraNode.removeAllActions()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        furthestCameraY = max(furthestCameraY, cameraNode.position.y)
        updateCamera(animated: false)
        updateVehicles()
        resetCollisionHistory()
        refreshTargetRing()
        refreshTutorialTarget()
        publishTargetDirection(force: true)
    }

    private func updateRenderedRows(force: Bool = false) {
        let rowsPerScreen = max(1, Int(ceil(size.height / rowHeight)))
        let lowerRow = max(-2, scoreTracker.highestRow - rowsPerScreen - 2)
        let upperRow = min(
            blueprint.maximumRow,
            scoreTracker.highestRow + (rowsPerScreen * 2) + 4
        )
        let desiredRows = Set(lowerRow...upperRow)

        if force {
            rowNodes.values.forEach { $0.removeFromParent() }
            rowNodes.removeAll()
            pondNodes.removeAll()
        }

        for row in Array(rowNodes.keys) where !desiredRows.contains(row) {
            guard let node = rowNodes.removeValue(forKey: row) else { continue }
            let removedPondIDs = pondNodes.compactMap { pondID, pondNode in
                pondNode.parent === node ? pondID : nil
            }
            for pondID in removedPondIDs {
                pondNodes[pondID] = nil
            }
            node.removeFromParent()
        }

        for row in desiredRows.sorted() where rowNodes[row] == nil {
            let node = makeRowNode(for: row)
            rowNodes[row] = node
            worldNode.addChild(node)
        }
    }

    private func makeRowNode(for row: Int) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: point(forRow: row))
        let terrain = blueprint.row(at: row)?.terrain ?? .grass

        let background = SKSpriteNode(
            color: color(for: terrain, row: row),
            size: CGSize(width: size.width, height: rowHeight + 1)
        )
        background.position = CGPoint(x: size.width / 2, y: 0)
        background.zPosition = -10
        container.addChild(background)

        if terrain == .road {
            addRoadDetails(to: container, atRow: row)
        } else {
            addGrassDetails(to: container, atRow: row)
        }

        addStaticObstacles(to: container, atRow: row)
        addPonds(to: container, atRow: row)
        return container
    }

    private func addRoadDetails(to container: SKNode, atRow row: Int) {
        let borderHeight = max(3, tileSize * 0.06)
        let hasRoadBelow = blueprint.row(at: row - 1)?.terrain == .road
        let hasRoadAbove = blueprint.row(at: row + 1)?.terrain == .road

        if !hasRoadBelow {
            let border = SKSpriteNode(
                color: Self.roadBorderColor,
                size: CGSize(width: size.width, height: borderHeight)
            )
            border.position = CGPoint(x: size.width / 2, y: -rowHeight * 0.47)
            border.zPosition = -8
            container.addChild(border)
        }

        if !hasRoadAbove {
            let border = SKSpriteNode(
                color: Self.roadBorderColor,
                size: CGSize(width: size.width, height: borderHeight)
            )
            border.position = CGPoint(x: size.width / 2, y: rowHeight * 0.47)
            border.zPosition = -8
            container.addChild(border)
        } else {
            for column in 0..<config.columns {
                let dash = SKSpriteNode(
                    color: Self.laneMarkColor,
                    size: CGSize(width: tileSize * 0.48, height: max(2, tileSize * 0.045))
                )
                dash.position = CGPoint(
                    x: (Double(column) + 0.5) * tileSize,
                    y: rowHeight * 0.49
                )
                dash.zPosition = -8
                container.addChild(dash)
            }
        }
    }

    private func addGrassDetails(to container: SKNode, atRow row: Int) {
        for column in 0..<config.columns {
            let position = GridPosition(column: column, row: row)
            guard blueprint.obstacles[position] == nil,
                  blueprint.pond(at: position) == nil,
                  let variant = GardenDecoration.variant(row: row, column: column) else { continue }
            let node = SKSpriteNode(texture: GardenDecoration.textures[variant])
            let extent = tileSize * GardenDecoration.scale(for: variant)
            node.size = CGSize(width: extent, height: extent)
            let offset = GardenDecoration.offset(row: row, column: column)
            node.position = CGPoint(x: (Double(column) + 0.5 + offset.x) * tileSize,
                y: rowHeight * (-0.12 + offset.y))
            node.zPosition = -8
            container.addChild(node)
        }
    }

    private func addStaticObstacles(to container: SKNode, atRow row: Int) {
        for (position, kind) in blueprint.obstacles where position.row == row {
            let textureName: String
            let nodeScale: Double

            switch kind {
            case .tree:
                textureName = "tree"
                nodeScale = 1.28
            case .log:
                textureName = "log"
                nodeScale = 1.48
            }

            let node = SKSpriteNode(texture: texture(named: textureName))
            node.size = CGSize(width: tileSize * nodeScale, height: tileSize * nodeScale)
            node.position = CGPoint(x: point(for: position).x, y: 0)
            node.zPosition = 3
            container.addChild(node)
        }
    }

    private func addPonds(to container: SKNode, atRow row: Int) {
        for pond in blueprint.ponds where pond.position.row == row {
            guard let firstTexture = pondTextures.first else { continue }

            let node = SKSpriteNode(texture: firstTexture)
            node.size = CGSize(width: tileSize * pond.kind.visualScale, height: rowHeight * pond.kind.visualScale)
            node.position = CGPoint(x: point(for: pond.position).x, y: 0)
            node.zPosition = 2
            pondNodes[pond.id] = node
            container.addChild(node)
            refreshPondPresentation(id: pond.id)
            guard !breathMeter.visitedPondIDs.contains(pond.id) else { continue }
            let badge = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            badge.text = "+\(Int(pond.kind.addedSeconds))s"
            badge.fontSize = tileSize * 0.24
            badge.fontColor = pond.kind == .large ? .yellow : .white
            badge.position = CGPoint(x: 0, y: rowHeight * 0.22)
            badge.zPosition = 1
            badge.name = "pond-reward"
            node.addChild(badge)
        }
    }

    private func configurePlayerNode() {
        playerNode.size = CGSize(
            width: tileSize * Self.playerVisualScale,
            height: rowHeight * Self.playerVisualScale
        )
        playerNode.zPosition = 6

        let body = SKPhysicsBody(
            rectangleOf: CGSize(
                width: tileSize * CollisionGeometry.playerWidthInColumns,
                height: rowHeight * CollisionGeometry.playerHeightInRows
            )
        )
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.vehicle
        body.collisionBitMask = 0
        body.usesPreciseCollisionDetection = true
        playerNode.physicsBody = body
        applyPlayerOrientation()
        refreshPlayerRestingAnimation(force: true)
    }

    private func applyPondAnimation(to node: SKSpriteNode) {
        node.removeAction(forKey: "pond-idle")

        guard !reduceMotion, !pondTextures.isEmpty else {
            node.texture = pondTextures.first
            return
        }

        let animation = SKAction.animate(
            with: pondTextures,
            timePerFrame: 0.2,
            resize: false,
            restore: false
        )
        node.run(.repeatForever(animation), withKey: "pond-idle")
    }

    private func refreshTargetRing() {
        targetRingNode?.removeFromParent()
        targetRingNode = nil

        guard
            let targetID = currentTargetPondID,
            let targetPond = blueprint.pond(id: targetID),
            pondNodes[targetID] != nil
        else { return }

        let pondScale = targetPond.kind.visualScale / 2.1
        let ring = SKShapeNode(
            ellipseOf: CGSize(width: tileSize * 1.85 * pondScale, height: rowHeight * 0.92 * pondScale)
        )
        ring.strokeColor = Self.targetColor
        ring.lineWidth = max(3, tileSize * 0.07)
        ring.glowWidth = reduceMotion ? 0 : tileSize * 0.08
        ring.position = point(for: targetPond.position)
        ring.zPosition = 1
        targetRingNode = ring
        worldNode.addChild(ring)

        guard !reduceMotion else { return }

        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.45, duration: 0.55),
            .fadeAlpha(to: 1, duration: 0.55)
        ])
        ring.run(.repeatForever(pulse), withKey: "target-pulse")
        if pondIsUrgent {
            ring.run(.repeatForever(.sequence([
                .scale(to: 1.12, duration: 0.35), .scale(to: 1, duration: 0.35)
            ])), withKey: "urgent-pond")
        }
    }

    private func refreshAmbientAnimations() {
        for pondID in pondNodes.keys {
            refreshPondPresentation(id: pondID)
        }
        refreshTargetRing()
    }

    private func refreshPlayerRestingAnimation(force: Bool = false) {
        guard movementQueue.activeDirection == nil else { return }

        let state = FishRestingAnimationState.resolve(
            remainingBreath: breathMeter.remaining,
            maximumBreath: breathMeter.maximum,
            isOnActivePond: playerIsOnActivePond
        )
        activeRestingAnimationState = state
        guard force || playerNode.action(forKey: "fish-resting") == nil else { return }

        playerNode.removeAction(forKey: "fish-resting")

        guard let firstTexture = fishTextures.first else { return }

        playerNode.texture = firstTexture
        applyPlayerOrientation()
        guard !reduceMotion, fishTextures.count > 1 else { return }

        let animation = SKAction.animate(
            with: fishTextures,
            timePerFrame: FishAnimationContract.frameDuration,
            resize: false,
            restore: false
        )
        let animateThreeTimes = SKAction.repeat(
            animation,
            count: FishAnimationContract.idleLoopsPerOrientation
        )
        let flipAndHold = SKAction.sequence([
            .run { [weak self] in
                guard let self else { return }
                fishOrientation.toggleVertically()
                applyPlayerOrientation()
                playerNode.texture = fishTextures.first
            },
            .wait(forDuration: FishAnimationContract.idleHoldDuration)
        ])
        let orientationBlock = SKAction.sequence([animateThreeTimes, flipAndHold])
        playerNode.run(.repeatForever(orientationBlock), withKey: "fish-resting")
    }

    private var playerIsOnActivePond: Bool {
        blueprint.pond(at: playerPosition).map {
            !breathMeter.visitedPondIDs.contains($0.id)
        } ?? false
    }

    private func applyPlayerOrientation() {
        playerNode.xScale = fishOrientation.horizontalScale
        playerNode.yScale = fishOrientation.verticalScale
    }

    private func beginMovement(_ direction: MoveDirection) {
        playerNode.removeAction(forKey: "landing-juice")
        playerNode.size = CGSize(width: tileSize * Self.playerVisualScale, height: rowHeight * Self.playerVisualScale)
        activeRestingAnimationState = nil
        playerNode.removeAction(forKey: "fish-resting")

        let destination = playerPosition.moved(direction)

        guard canMove(to: destination) else {
            playerNode.texture = fishTextures.first
            eventSink?.receive(.feedback(.blockedMove))
            tutorialBlockedMove = tutorialSection != nil
            playBlockedFeedback(direction: direction)
            return
        }

        isHopProtected = true
        movementStartOrientation = fishOrientation
        fishOrientation.applyMovement(direction, isAccepted: true)
        applyPlayerOrientation()
        playerNode.texture = fishTextures.first
        eventSink?.receive(.feedback(.hop))

        let duration = max(0, config.movementDuration)
        let moveAction = SKAction.move(to: point(for: destination), duration: duration)
        moveAction.timingMode = reduceMotion ? .linear : .easeInEaseOut

        playerNode.removeAction(forKey: "blocked-feedback")
        playerNode.run(moveAction) { [weak self] in
            self?.completeMovement(to: destination)
        }
    }

    private func canMove(to position: GridPosition) -> Bool {
        if tutorialSection != nil && position.row > TutorialWorld.pondRow { return false }
        return movementRules.canMove(to: position, minimumRow: minimumAccessibleRow)
    }

    /// The lowest row the player may occupy: the first row whose tile is fully
    /// visible above the camera's bottom edge. Because the camera only ever
    /// scrolls up (`furthestCameraY` is monotonic), this keeps the reachable
    /// floor aligned with what the player can actually see, both at the start
    /// and after progressing. A row that renders only half on screen at the
    /// bottom is never reachable.
    private var minimumAccessibleRow: Int {
        guard rowHeight > 0 else { return 0 }

        let bottomEdgeY = furthestCameraY - size.height / 2
        // Solve point(forRow:) - rowHeight/2 >= bottomEdgeY for the smallest
        // fully-visible integer row.
        let rawRow = (bottomEdgeY - rowOriginY + rowHeight / 2) / rowHeight
        return max(0, Int(ceil(rawRow)))
    }

    private func playBlockedFeedback(direction: MoveDirection) {
        let vector = unitVector(for: direction)

        if reduceMotion {
            let flash = SKAction.sequence([
                .colorize(with: .white, colorBlendFactor: 0.55, duration: 0.04),
                .colorize(withColorBlendFactor: 0, duration: 0.06)
            ])
            playerNode.run(flash) { [weak self] in
                self?.finishMovementCycle()
            }
        } else {
            let distance = tileSize * 0.09
            let bump = SKAction.sequence([
                .moveBy(x: vector.dx * distance, y: vector.dy * distance, duration: 0.045),
                .moveBy(x: -vector.dx * distance, y: -vector.dy * distance, duration: 0.06)
            ])
            bump.timingMode = .easeOut
            playerNode.run(bump) { [weak self] in
                self?.finishMovementCycle()
            }
        }
    }

    private func completeMovement(to destination: GridPosition) {
        guard !didEndRun else { return }

        isHopProtected = false
        resetCollisionHistory()
        if detectsSweptVehicleCollision() {
            finishRun(reason: .vehicleCollision)
            return
        }

        let previousPosition = playerPosition
        playerPosition = destination
        leaveFishTrail(at: previousPosition)

        if scoreTracker.record(row: destination.row) {
            eventSink?.receive(.scoreChanged(max(0, scoreTracker.highestRow - scoreOriginRow)))
            ensureBlueprintAhead()
            updateRenderedRows()
            updateCamera(animated: true)
        }

        handlePondVisit()
        currentTargetPondID = selectTargetPondID()
        refreshTargetRing()
        publishTargetDirection(force: true)
        finishMovementCycle()
        if movementQueue.activeDirection == nil && !reduceMotion {
            let width = tileSize * Self.playerVisualScale
            let height = rowHeight * Self.playerVisualScale
            playerNode.run(.sequence([
                .resize(toWidth: width * 1.08, height: height * 0.92, duration: 0.045),
                .resize(toWidth: width, height: height, duration: 0.10)
            ]), withKey: "landing-juice")
        }
        if tutorialSection != nil { eventSink?.receive(.movementCompleted(destination)) }
    }

    private func leaveFishTrail(at position: GridPosition) {
        // Revisiting a tile replaces its mark, and the occupied tile stays clear.
        trailNodes.removeAll { node in
            if node.gridPosition == position || node.gridPosition == playerPosition {
                node.removeFromParent()
                return true
            }
            return false
        }
        let mark = FishTrailMarkNode(position: position, orientation: movementStartOrientation, tileSize: tileSize)
        mark.position = point(for: position)
        worldNode.addChild(mark)
        trailNodes.append(mark)
        while trailNodes.count > 4 {
            trailNodes.removeFirst().removeFromParent()
        }
        updateFishTrail(deltaTime: 0)
    }

    private func updateFishTrail(deltaTime: Double) {
        for mark in trailNodes {
            let distance = abs(mark.gridPosition.column - playerPosition.column)
                + abs(mark.gridPosition.row - playerPosition.row)
            mark.advance(by: deltaTime, distanceFromFish: distance)
        }
        trailNodes.removeAll { mark in
            guard mark.age >= FishTrailMarkNode.lifetime else { return false }
            mark.removeFromParent()
            return true
        }
    }

    private func finishMovementCycle() {
        guard !didEndRun else { return }
        let reportBlocked = tutorialBlockedMove
        tutorialBlockedMove = false
        defer { if reportBlocked { eventSink?.receive(.movementBlocked) } }

        if let bufferedMovement = movementQueue.completeActiveMovement() {
            beginMovement(bufferedMovement)
        } else {
            refreshPlayerRestingAnimation(force: true)
        }
    }

    private func handlePondVisit() {
        guard let pond = blueprint.pond(at: playerPosition) else { return }
        let before = breathMeter.remaining
        guard breathMeter.visitPond(id: pond.id, adding: pond.kind.addedSeconds) else { return }
        showPondJuice(at: playerPosition, added: breathMeter.remaining - before)

        refreshPondPresentation(id: pond.id)
        breathWarningTracker.reset()
        eventSink?.receive(.breathChanged(breathMeter.remaining))
        eventSink?.receive(.feedback(.splash))
        if tutorialSection != nil { eventSink?.receive(.pondAbsorbed) }
    }

    private func showPondJuice(at position: GridPosition, added: Double) {
        let center = point(for: position)
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = added < 0.05 ? "FULL" : "+\(added.formatted(.number.precision(.fractionLength(0...1))))s"
        label.fontSize = tileSize * 0.4
        label.fontColor = .cyan
        label.position = CGPoint(x: center.x, y: center.y + rowHeight * 0.6)
        label.zPosition = 15
        worldNode.addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: reduceMotion ? 0 : rowHeight * 0.5, duration: 0.65),
                .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.35)])]),
            .removeFromParent()
        ]))
        guard !reduceMotion else { return }
        for index in 0..<8 {
            let angle = Double(index) * .pi / 4
            let drop = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.08, height: tileSize * 0.13))
            drop.fillColor = .cyan
            drop.strokeColor = .white
            drop.lineWidth = 1
            drop.position = center
            drop.zPosition = 12
            worldNode.addChild(drop)
            drop.run(.sequence([.group([
                .moveBy(x: cos(angle) * tileSize * 0.8, y: sin(angle) * rowHeight * 0.5, duration: 0.3),
                .fadeOut(withDuration: 0.3)
            ]), .removeFromParent()]))
        }
    }

    private func showNearMissJuice(vehicle: SKSpriteNode, movingRight: Bool) {
        let direction: CGFloat = movingRight ? 1 : -1
        // Keep the wake in world space, spanning the road and the nearby fish.
        let centerY = (vehicle.position.y + playerNode.position.y) / 2
        for index in 0..<5 {
            let width = tileSize * (1.4 + Double(index % 3) * 0.4)
            let streak = SKShapeNode(rectOf: CGSize(width: width, height: 4), cornerRadius: 2)
            streak.fillColor = SKColor(red: 0.15, green: 1, blue: 1, alpha: 1)
            streak.strokeColor = SKColor(red: 0.02, green: 0.22, blue: 0.28, alpha: 0.9)
            streak.lineWidth = 1.5
            streak.alpha = 1
            streak.position = CGPoint(
                x: vehicle.position.x - direction * tileSize * (0.35 + Double(index % 2) * 0.4),
                y: centerY + Double(index - 2) * rowHeight * 0.24
            )
            streak.zPosition = 8
            worldNode.addChild(streak)
            streak.run(.sequence([.group([
                .moveBy(x: direction * tileSize * 1.2, y: 0, duration: 0.38),
                .fadeOut(withDuration: 0.38)
            ]), .removeFromParent()]))
        }
    }

    private func selectTargetPondID() -> Int? {
        let unvisitedPonds = blueprint.ponds.filter {
            !breathMeter.visitedPondIDs.contains($0.id)
        }
        let ahead = unvisitedPonds.filter { $0.position.row >= playerPosition.row }
        let candidates = ahead.isEmpty ? unvisitedPonds : ahead

        return candidates.min { lhs, rhs in
            let lhsDistance = abs(lhs.position.row - playerPosition.row)
                + abs(lhs.position.column - playerPosition.column)
            let rhsDistance = abs(rhs.position.row - playerPosition.row)
                + abs(rhs.position.column - playerPosition.column)

            if lhsDistance == rhsDistance {
                return lhs.position.row < rhs.position.row
            }
            return lhsDistance < rhsDistance
        }?.id
    }

    private func updateBreath(deltaTime: Double) {
        if tutorialSection != nil && tutorialStep != .pond { return }
        let didExpire = breathMeter.advance(by: deltaTime, isSafe: playerIsOnActivePond)
        let urgent = breathMeter.remaining <= config.maximumBreath * 0.4
        if urgent != pondIsUrgent { pondIsUrgent = urgent; refreshTargetRing() }
        refreshPlayerRestingAnimation()

        if breathWarningTracker.shouldWarn(for: breathMeter.remaining) {
            eventSink?.receive(.feedback(.criticalBreath))
        }

        if didExpire {
            eventSink?.receive(.breathChanged(0))
            finishRun(reason: .outOfBreath)
        }
    }

    private func updateVehicles() {
        let lowerY = cameraNode.position.y - size.height / 2 - rowHeight
        let upperY = cameraNode.position.y + size.height / 2 + rowHeight
        let visibleRoadRows = rowNodes.keys.filter {
            blueprint.roadLanes[$0] != nil && point(forRow: $0) >= lowerY && point(forRow: $0) <= upperY
        }
        var desiredKeys: Set<VehicleSpawnKey> = []

        for row in visibleRoadRows {
            guard let lane = blueprint.roadLanes[row] else { continue }

            for spawnIndex in lane.activeSpawnIndices(
                at: simulationElapsed,
                columnCount: config.columns
            ) {
                let centerColumn = lane.centerColumn(
                    forSpawnIndex: spawnIndex,
                    at: simulationElapsed,
                    columnCount: config.columns
                )
                let margin = lane.vehicleKind.lengthInColumns
                guard centerColumn >= -margin, centerColumn <= Double(config.columns) + margin else { continue }

                let key = VehicleSpawnKey(row: row, spawnIndex: spawnIndex)
                desiredKeys.insert(key)

                let node = vehicleNodes[key] ?? makeVehicleNode(for: lane, key: key)
                node.position = CGPoint(
                    x: centerColumn * tileSize,
                    y: point(forRow: row)
                )
            }
        }

        for key in Array(vehicleNodes.keys) where !desiredKeys.contains(key) {
            vehicleNodes.removeValue(forKey: key)?.removeFromParent()
        }
    }

    private func updateVehiclePassFeedback() {
        if !reduceMotion, simulationElapsed - lastNearMissTime > 1,
           let previousPlayer = previousPlayerCollisionCenter {
            for (key, vehicle) in vehicleNodes {
                guard let previousVehicle = previousVehicleCollisionCenters[key] else { continue }
                let before = previousVehicle.x - previousPlayer.x
                let after = vehicle.position.x - playerNode.position.x
                let verticalGap = abs(vehicle.position.y - playerNode.position.y) / rowHeight
                if before * after <= 0 && verticalGap >= 0.65 && verticalGap <= 1.05 {
                    showNearMissJuice(vehicle: vehicle, movingRight: vehicle.position.x > previousVehicle.x)
                    lastNearMissTime = simulationElapsed
                    break
                }
            }
        }
        let nearbyKeys = Set(vehicleNodes.compactMap { key, node in
            VehiclePassByTracker.isNearby(
                horizontalTiles: (node.position.x - playerNode.position.x) / tileSize,
                verticalRows: (node.position.y - playerNode.position.y) / rowHeight
            ) ? key : nil
        })
        if vehiclePassByTracker.shouldPlay(
            nearbyKeys: nearbyKeys,
            activeKeys: Set(vehicleNodes.keys),
            at: simulationElapsed
        ) {
            eventSink?.receive(.feedback(.vehiclePass))
        }
    }

    private func makeVehicleNode(
        for lane: RoadLaneDefinition,
        key: VehicleSpawnKey
    ) -> SKSpriteNode {
        let textureName = lane.vehicleKind == .car ? "car-orange" : "truck-blue"
        let node = SKSpriteNode(texture: texture(named: textureName))
        let scale = lane.vehicleKind == .car ? 2.45 : 2.8
        node.size = CGSize(width: tileSize * scale, height: rowHeight * scale)
        node.xScale = lane.direction == .right ? 1 : -1
        node.zPosition = 7

        let body = SKPhysicsBody(
            rectangleOf: CGSize(
                width: tileSize * lane.vehicleKind.lengthInColumns,
                height: rowHeight * CollisionGeometry.vehicleHeightInRows
            )
        )
        body.affectedByGravity = false
        body.allowsRotation = false
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.vehicle
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        node.physicsBody = body

        vehicleNodes[key] = node
        worldNode.addChild(node)
        return node
    }

    private func detectsSweptVehicleCollision() -> Bool {
        guard !isHopProtected else { return false }
        let playerCurrentCenter = playerNode.position
        let playerPreviousCenter = previousPlayerCollisionCenter ?? playerCurrentCenter
        let playerSize = CGSize(
            width: tileSize * CollisionGeometry.playerWidthInColumns,
            height: rowHeight * CollisionGeometry.playerHeightInRows
        )

        for (key, node) in vehicleNodes {
            guard let lane = blueprint.roadLanes[key.row] else { continue }

            let vehicleCurrentCenter = node.position
            let vehiclePreviousCenter = previousVehicleCollisionCenters[key] ?? vehicleCurrentCenter
            let vehicleSize = CGSize(
                width: tileSize * lane.vehicleKind.lengthInColumns,
                height: rowHeight * CollisionGeometry.vehicleHeightInRows
            )

            if SweptCollisionDetector.intersects(
                firstFrom: playerPreviousCenter,
                firstTo: playerCurrentCenter,
                firstSize: playerSize,
                secondFrom: vehiclePreviousCenter,
                secondTo: vehicleCurrentCenter,
                secondSize: vehicleSize
            ) {
                return true
            }
        }

        return false
    }

    private func captureCollisionSample() {
        previousPlayerCollisionCenter = playerNode.position
        previousVehicleCollisionCenters = vehicleNodes.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value.position
        }
    }

    private func resetCollisionHistory() {
        previousPlayerCollisionCenter = nil
        previousVehicleCollisionCenters.removeAll(keepingCapacity: true)
        captureCollisionSample()
    }

    private func ensureBlueprintAhead() {
        let rowsPerScreen = max(1, Int(ceil(size.height / rowHeight)))
        guard !didEndRun, expansionTask == nil,
              scoreTracker.highestRow + (rowsPerScreen * 4) >= blueprint.maximumRow else { return }

        let expandedRowCount = blueprint.rows.count * 2
        let generator = generator
        let seed = seed
        let worker = Task.detached(priority: .userInitiated) {
            generator.generate(seed: seed, rowCount: expandedRowCount)
        }
        expansionTask = Task { [weak self] in
            let normalWorld = await withTaskCancellationHandler {
                await worker.value
            } onCancel: {
                worker.cancel()
            }
            guard !Task.isCancelled, let self, !didEndRun else { return }
            installExpandedWorld(normalWorld)
            expansionTask = nil
        }
    }

    private func installExpandedWorld(_ normalWorld: WorldBlueprint) {
        blueprint = includesTutorialPath ? TutorialWorld.prepend(to: normalWorld, columns: config.columns) : normalWorld
        movementRules = GridMovementRules(
            columnCount: config.columns,
            maximumRow: blueprint.maximumRow,
            obstacles: Set(blueprint.obstacles.keys)
        )
        currentTargetPondID = selectTargetPondID()
        if isWorldReady { updateRenderedRows() }
    }

    deinit {
        expansionTask?.cancel()
    }

    private func updateCamera(animated: Bool) {
        // Camera starts scrolling once the player passes `cameraScrollThresholdRow`,
        // regardless of the score tracker (which starts at 0).
        let referenceRow = max(scoreTracker.highestRow, playerPosition.row)
        let highestPosition = GridPosition(column: playerPosition.column, row: referenceRow)
        let anchorY = rowOriginY + rowHeight * Double(Self.cameraScrollThresholdRow - 1)
        let desiredY = point(for: highestPosition).y + size.height / 2 - anchorY
        let targetY = max(size.height / 2, desiredY)
        furthestCameraY = max(furthestCameraY, targetY)

        let targetPoint = CGPoint(x: size.width / 2, y: furthestCameraY)
        guard animated, !reduceMotion else {
            cameraNode.position = targetPoint
            return
        }

        let action = SKAction.move(to: targetPoint, duration: 0.16)
        action.timingMode = .easeOut
        cameraNode.run(action, withKey: "camera-follow")
    }

    private func publishInitialSnapshot() {
        eventSink?.receive(.scoreChanged(max(0, scoreTracker.highestRow - scoreOriginRow)))
        eventSink?.receive(.breathChanged(breathMeter.remaining))
        publishTargetDirection(force: true)
    }

    private func publishHUDIfNeeded(deltaTime: Double) {
        hudPublishAccumulator += deltaTime
        guard hudPublishAccumulator >= 0.05 else { return }

        hudPublishAccumulator = 0
        eventSink?.receive(.breathChanged(breathMeter.remaining))
        publishTargetDirection(force: false)
    }

    private func publishTargetDirection(force: Bool) {
        let direction: MoveDirection?

        if let targetID = currentTargetPondID, let targetPond = blueprint.pond(id: targetID) {
            let target = point(for: targetPond.position)
            let visibleLeft = cameraNode.position.x - size.width / 2
            let visibleRight = cameraNode.position.x + size.width / 2
            let visibleBottom = cameraNode.position.y - size.height / 2
            let visibleTop = cameraNode.position.y + size.height / 2 - 110

            if target.y > visibleTop {
                direction = .up
            } else if target.y < visibleBottom {
                direction = .down
            } else if target.x < visibleLeft {
                direction = .left
            } else if target.x > visibleRight {
                direction = .right
            } else {
                direction = nil
            }
        } else {
            direction = nil
        }

        guard force || direction != lastPublishedTargetDirection else { return }
        lastPublishedTargetDirection = direction
        eventSink?.receive(.targetDirectionChanged(direction))
    }

    private func finishRun(reason: GameOverReason) {
        expansionTask?.cancel()
        expansionTask = nil
        guard isSimulationRunning, !didEndRun else { return }

        didEndRun = true
        isSimulationRunning = false
        touchStartPoint = nil
        movementQueue.reset()
        isHopProtected = false

        if reason == .vehicleCollision {
            eventSink?.receive(.feedback(.vehicleCollision))
            playerNode.removeAllActions()
            if !reduceMotion {
                playerNode.run(.sequence([
                    .colorize(with: .white, colorBlendFactor: 0.8, duration: 0.04),
                    .group([.rotate(byAngle: .pi / 8, duration: 0.12),
                        .colorize(withColorBlendFactor: 0, duration: 0.16)])
                ]))
            }
        }
        eventSink?.receive(.gameOver(reason))
    }

    private func color(for terrain: TerrainKind, row: Int) -> SKColor {
        switch terrain {
        case .grass:
            row.isMultiple(of: 2) ? Self.grassColor : Self.alternateGrassColor
        case .meadow:
            Self.meadowColor
        case .pondClearing:
            Self.pondClearingColor
        case .road:
            Self.roadColor
        }
    }

    private func point(for position: GridPosition) -> CGPoint {
        CGPoint(
            x: (Double(position.column) + 0.5) * tileSize,
            y: point(forRow: position.row)
        )
    }

    private func point(forRow row: Int) -> Double {
        rowOriginY + Double(row) * rowHeight
    }

    private func refreshPondPresentation(id pondID: Int) {
        guard let node = pondNodes[pondID] else { return }

        node.alpha = 1
        if breathMeter.visitedPondIDs.contains(pondID) {
            node.childNode(withName: "pond-reward")?.removeFromParent()
            node.removeAction(forKey: "pond-idle")
            node.texture = drainedPondTexture
            node.colorBlendFactor = 0
        } else {
            node.color = Self.unvisitedPondColor
            node.colorBlendFactor = Self.unvisitedPondColorBlendFactor
            applyPondAnimation(to: node)
        }
    }

    private func unitVector(for direction: MoveDirection) -> CGVector {
        switch direction {
        case .up:
            CGVector(dx: 0, dy: 1)
        case .down:
            CGVector(dx: 0, dy: -1)
        case .left:
            CGVector(dx: -1, dy: 0)
        case .right:
            CGVector(dx: 1, dy: 0)
        }
    }

    private func texture(named name: String) -> SKTexture {
        if let cached = Self.sharedTextures[name] { return cached }
        let texture = SKTexture(imageNamed: name)
        texture.filteringMode = .linear
        Self.sharedTextures[name] = texture
        return texture
    }

    #if DEBUG
    func debugBeginPendingTouch() {
        touchStartPoint = playerNode.position
    }

    var debugHasPendingTouch: Bool { touchStartPoint != nil }
    var debugFrameTime: TimeInterval { lastUpdateTime }

    var debugDiagnostics: GameSceneDiagnostics {
        GameSceneDiagnostics(
            renderedRowCount: rowNodes.count,
            vehicleNodeCount: vehicleNodes.count,
            worldChildCount: worldNode.children.count,
            blueprintRowCount: blueprint.rows.count
        )
    }

    func debugWaitForExpansion() async {
        await expansionTask?.value
    }

    func debugSetProgress(row: Int) {
        // Test teleports can jump beyond the streamed world in one call.
        if row > blueprint.maximumRow {
            expansionTask?.cancel()
            expansionTask = nil
            installExpandedWorld(generator.generate(seed: seed, rowCount: row + 64))
        }
        let safeRow = min(max(0, row), blueprint.maximumRow)
        playerPosition = GridPosition(column: playerPosition.column, row: safeRow)
        _ = scoreTracker.record(row: safeRow)
        ensureBlueprintAhead()
        updateRenderedRows(force: true)
        playerNode.position = point(for: playerPosition)
        updateCamera(animated: false)
        updateVehicles()
        resetCollisionHistory()
    }

    func debugSetSimulationElapsed(_ elapsed: Double) {
        simulationElapsed = max(0, elapsed)
        updateVehicles()
        resetCollisionHistory()
    }

    var debugPlayerVisualScaleInTiles: Double {
        guard tileSize > 0 else { return 0 }
        return playerNode.size.width / tileSize
    }

    var debugPlayerCollisionSizeInTiles: CGSize {
        CGSize(
            width: CollisionGeometry.playerWidthInColumns,
            height: CollisionGeometry.playerHeightInRows
        )
    }

    var debugPlayerGridPosition: GridPosition {
        playerPosition
    }

    var debugIsSimulationPaused: Bool {
        isSimulationPaused
    }

    var debugIsAcceptingGameplayInput: Bool {
        isAcceptingGameplayInput
    }

    /// Simulates SpriteKit clearing its own pause flag, which happens when the
    /// app returns from the background or the hosting SpriteView rebuilds.
    func debugSimulateExternalUnpause() {
        isPaused = false
        worldNode.isPaused = false
        cameraNode.isPaused = false
    }

    var debugPlayerRestingAnimationState: FishRestingAnimationState? {
        activeRestingAnimationState
    }

    var debugFishTextureCount: Int {
        fishTextures.count
    }

    var debugFishOrientation: FishSpriteOrientation {
        fishOrientation
    }

    var debugHasFishRestingAnimation: Bool {
        playerNode.action(forKey: "fish-resting") != nil
    }

    var debugRenderedPondIDs: [Int] {
        pondNodes.keys.sorted()
    }

    var debugTrailPositions: [GridPosition] { trailNodes.map(\.gridPosition) }
    var debugTrailOpacities: [Double] { trailNodes.map { Double($0.alpha) } }
    var debugTrailScales: [CGSize] { trailNodes.map { CGSize(width: $0.xScale, height: $0.yScale) } }
    var debugIsHopProtected: Bool { isHopProtected }
    var debugDidEndRun: Bool { didEndRun }
    func debugOverlapVehicleWithPlayer() {
        guard let node = vehicleNodes.values.first else { preconditionFailure("Test requires a vehicle") }
        node.position = playerNode.position
    }
    func debugCheckVehicleCollision() {
        if detectsSweptVehicleCollision() { finishRun(reason: .vehicleCollision) }
    }

    var debugFirstRoadRow: Int? { blueprint.roadLanes.keys.min() }

    func debugFinishActiveMovement(overlappingVehicle: Bool = false) {
        guard let direction = movementQueue.activeDirection else { return }
        let destination = playerPosition.moved(direction)
        playerNode.removeAllActions()
        guard canMove(to: destination) else {
            finishMovementCycle()
            return
        }
        playerNode.position = point(for: destination)
        if overlappingVehicle { debugOverlapVehicleWithPlayer() }
        completeMovement(to: destination)
    }

    var debugRemainingBreath: Double { breathMeter.remaining }

    func debugPondVisualScale(id: Int) -> Double? { pondNodes[id].map { $0.size.width / tileSize } }

    func debugVisitPond(id pondID: Int) {
        guard let pond = blueprint.pond(id: pondID) else { return }
        playerPosition = pond.position
        playerNode.position = point(for: playerPosition)
        handlePondVisit()
        refreshPlayerRestingAnimation(force: true)
    }

    func debugPondIsVisited(id pondID: Int) -> Bool {
        breathMeter.visitedPondIDs.contains(pondID)
    }

    func debugPondIsDrained(id pondID: Int) -> Bool {
        guard let node = pondNodes[pondID] else { return false }
        return node.texture === drainedPondTexture
            && node.action(forKey: "pond-idle") == nil
            && node.alpha == 1
            && node.children.isEmpty
    }
    #endif

    // Nine columns make each tile narrower; 1.50 keeps the fish 1.3x larger on screen
    // than the former 0.90-scale fish on the seven-column board.
    private static let playerVisualScale = 1.50
    // Row at which the camera begins scrolling upward. Decoupled from the score
    // tracker so the starting scroll threshold can differ from the player's
    // starting row without affecting the displayed score.
    private static let cameraScrollThresholdRow = 4
    private static let unvisitedPondColor = SKColor(red: 0.24, green: 0.78, blue: 1, alpha: 1)
    private static let unvisitedPondColorBlendFactor = 0.10
    private static let grassColor = SKColor(red: 0.34, green: 0.78, blue: 0.31, alpha: 1)
    private static let alternateGrassColor = SKColor(red: 0.30, green: 0.72, blue: 0.27, alpha: 1)
    private static let meadowColor = SKColor(red: 0.43, green: 0.82, blue: 0.35, alpha: 1)
    private static let pondClearingColor = SKColor(red: 0.52, green: 0.84, blue: 0.38, alpha: 1)
    private static let roadColor = SKColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1)
    private static let roadBorderColor = SKColor(red: 0.04, green: 0.25, blue: 0.30, alpha: 1)
    private static let laneMarkColor = SKColor(red: 1, green: 0.94, blue: 0.76, alpha: 1)
    private static let targetColor = SKColor(red: 1, green: 0.88, blue: 0.28, alpha: 1)
    private static let flowerYellow = SKColor(red: 1, green: 0.77, blue: 0.20, alpha: 0.85)
    private static let flowerBlue = SKColor(red: 0.40, green: 0.83, blue: 0.95, alpha: 0.85)
}
