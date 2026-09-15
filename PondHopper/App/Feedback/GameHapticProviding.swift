@MainActor
protocol GameHapticProviding: AnyObject {
    func prepare()
    func play(_ kind: GameHapticKind)
}
