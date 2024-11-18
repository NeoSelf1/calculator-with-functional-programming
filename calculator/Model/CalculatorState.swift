struct CalculatorState {
    let displayNumber: String
    let displayOperator: String
    let storedNumber: Double?
    let operation: String?
    let shouldResetDisplay: Bool
    
    static let initial = CalculatorState(
        displayNumber: "0",
        displayOperator: "",
        storedNumber: nil,
        operation: nil,
        shouldResetDisplay: false
    )
}
