func == <each Element: Equatable>(lhs: (repeat each Element), rhs: (repeat each Element)) -> Bool {
    for (left, right) in repeat (each lhs, each rhs) {
        guard left == right else { return false }
    }
    return true
}

func aMean(_ numbers: Double..., with op: (Double, Double) -> Double ) -> Double {
    let total = numbers.reduce(0, op)
    return total / Double(numbers.count)
}
