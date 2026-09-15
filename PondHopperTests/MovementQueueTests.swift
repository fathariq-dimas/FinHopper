import Testing
@testable import FinHopper

struct MovementQueueTests {
    @Test
    func buffersAtMostOneFutureDirection() {
        var queue = MovementQueue()

        let immediate = queue.enqueue(.up)
        let buffered = queue.enqueue(.left)
        let ignored = queue.enqueue(.right)

        #expect(immediate == .up)
        #expect(buffered == nil)
        #expect(ignored == nil)
        #expect(queue.bufferedDirection == .left)

        let released = queue.completeActiveMovement()
        let finished = queue.completeActiveMovement()

        #expect(released == .left)
        #expect(finished == nil)
    }

    @Test
    func blockedMovementCanCompleteAndReleaseBufferedInput() {
        var queue = MovementQueue()

        _ = queue.enqueue(.left)
        _ = queue.enqueue(.up)

        let released = queue.completeActiveMovement()

        #expect(released == .up)
        #expect(queue.activeDirection == .up)
        #expect(queue.bufferedDirection == nil)
    }
}
