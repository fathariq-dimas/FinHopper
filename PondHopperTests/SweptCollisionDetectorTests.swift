import CoreGraphics
import Testing
@testable import FinHopper

struct SweptCollisionDetectorTests {
    @Test
    func catchesCrossingMotionWithoutFalsePositiveOnAnotherLane() {
        let playerSize = CGSize(width: CollisionGeometry.playerWidthInColumns, height: CollisionGeometry.playerHeightInRows)
        let vehicleSize = CGSize(width: 1.76, height: 0.62)

        #expect(SweptCollisionDetector.intersects(
            firstFrom: CGPoint(x: 0, y: 0),
            firstTo: CGPoint(x: 3, y: 0),
            firstSize: playerSize,
            secondFrom: CGPoint(x: 2, y: 0),
            secondTo: CGPoint(x: -1, y: 0),
            secondSize: vehicleSize
        ))

        #expect(!SweptCollisionDetector.intersects(
            firstFrom: CGPoint(x: 0, y: 2),
            firstTo: CGPoint(x: 3, y: 2),
            firstSize: playerSize,
            secondFrom: CGPoint(x: 2, y: 0),
            secondTo: CGPoint(x: -1, y: 0),
            secondSize: vehicleSize
        ))
    }

    @Test
    func smallerFishAllowsEdgeNearMissButStillDetectsCenterHit() {
        let fishSize = CGSize(width: CollisionGeometry.playerWidthInColumns, height: CollisionGeometry.playerHeightInRows)
        let vehicleSize = CGSize(width: 1.76, height: CollisionGeometry.vehicleHeightInRows)
        for offset in [CGPoint(x: 1.18, y: 0), CGPoint(x: 0, y: 0.57)] {
            #expect(!SweptCollisionDetector.intersects(
                firstFrom: offset, firstTo: offset, firstSize: fishSize,
                secondFrom: .zero, secondTo: .zero, secondSize: vehicleSize
            ))
        }
        #expect(SweptCollisionDetector.intersects(
            firstFrom: .zero, firstTo: .zero, firstSize: fishSize,
            secondFrom: .zero, secondTo: .zero, secondSize: vehicleSize
        ))
    }

}
