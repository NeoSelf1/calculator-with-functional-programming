import UIKit

class CalculatorViewController: UIViewController {
    // MARK: - UI 설정 메서드
    private let operatorLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .gray
        label.backgroundColor = .black
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.textColor = .white
        label.backgroundColor = .black
        label.font = .systemFont(ofSize: 60)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.backgroundColor = .black
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private func createHorizontalStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.backgroundColor = .black
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    
    private func makeButton(titleValue: String, action: Selector, backgroundColor: UIColor = .gray2) -> UIButton {
        let button = UIButton()
        let size: CGFloat = 80
        
        button.setTitle(titleValue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = size / 2
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        return button
    }
    
    private func setupUI() {
        let data = "789+456-123*a0=/".map{String($0)}
        view.backgroundColor = .black
        view.addSubview(operatorLabel)
        view.addSubview(numberLabel)
        view.addSubview(verticalStackView)
        
        for i in 0..<4{
            let row = createHorizontalStackView()
            data[i*4..<(i+1)*4].forEach{ title in
                let backgroundColor = Int(title) == nil ? UIColor.orange : .gray2
                row.addArrangedSubview(makeButton(titleValue: title == "a" ? "AC" : title, action: #selector(numberButtonTapped), backgroundColor: backgroundColor))
            }
            verticalStackView.addArrangedSubview(row)
        }
        
        NSLayoutConstraint.activate([
            operatorLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            operatorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            operatorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            operatorLabel.heightAnchor.constraint(equalToConstant: 40),
            
            numberLabel.topAnchor.constraint(equalTo: operatorLabel.bottomAnchor, constant: 80),
            numberLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            numberLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            numberLabel.heightAnchor.constraint(equalToConstant: 100),
            
            verticalStackView.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 60),
            verticalStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verticalStackView.widthAnchor.constraint(equalToConstant: 350)
        ])
    }
    // MARK: - 생명주기 관련 메서드
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - 계산기 핵심 로직
    private var currentState: CalculatorState = .initial
    
    // 연산을 위해 치환했던 Double값을 표시를 위한 String값으로 변환 및 포맷하는 메서드
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        // 끝 소수점이 0이면 자동 생략 및 최대 보이는 소수점 개수 8개로 제한
        return formatter.string(from: NSNumber(value: number)) ?? "Error"
    }
    
    // 연산에 사용되는 메서드 -> 이때 divided by Zero 문제에 대한 고려가 필요함 -> 사전에 해당 조건 확인 후, 수동으로 infinity 반환
    private func perform(operation: String, first: Double, second: Double) -> Double {
        switch operation {
        case "+": return first + second
        case "-": return first - second
        case "*": return first * second
        case "/": return second != 0 ? first / second : .infinity
        default: return second
        }
    }
    
    // 전체 프로젝트에서의 로직틀은 순수히 CalculatorState 객체 내부 상태값이 변경되는 과정만 존재한다. 동시성프로그래밍 혹은
    private func reduce(state: CalculatorState, action: CalculatorAction) -> CalculatorState {
        switch action {
        case .number(let digit):
            if state.shouldResetDisplay {
                return CalculatorState(
                    displayNumber: digit,
                    displayOperator: state.displayOperator,
                    storedNumber: state.storedNumber,
                    operation: state.operation,
                    shouldResetDisplay: false
                )
            } else {
                let newDisplay = state.displayNumber == "0" ? digit : state.displayNumber + digit
                return CalculatorState(
                    displayNumber: newDisplay,
                    displayOperator: state.displayOperator,
                    storedNumber: state.storedNumber,
                    operation: state.operation,
                    shouldResetDisplay: false
                )
            }
            
        case .operation(let op):
            guard let currentNumber = Double(state.displayNumber) else { return state }
            if let storedNumber = state.storedNumber, let currentOp = state.operation {
                let result = perform(operation: currentOp, first: storedNumber, second: currentNumber)
                return CalculatorState(
                    displayNumber: formatNumber(result),
                    displayOperator: "",
                    storedNumber: result,
                    operation: op,
                    shouldResetDisplay: true
                )
            } else {
                return CalculatorState(
                    displayNumber: state.displayNumber,
                    displayOperator: op,
                    storedNumber: currentNumber,
                    operation: op,
                    shouldResetDisplay: true
                )
            }
            
        case .equals:
            guard let currentNumber = Double(state.displayNumber),
                  let storedNumber = state.storedNumber,
                  let operation = state.operation else { return state }
            
            let result = perform(operation: operation, first: storedNumber, second: currentNumber)
            return CalculatorState(
                displayNumber: formatNumber(result),
                displayOperator: "",
                storedNumber: nil,
                operation: nil,
                shouldResetDisplay: true
            )
            
        case .clear:
            return .initial
        }
    }
    // 사용자로의 이벤트가 호출되면, 프로젝트 내부에서 관리되는 데이터(currentState)는 삭제되지 않고, reduce 메서드를 통해 기존 데이터에서 덧붙여지는 과정만을 반복한다.
    // 때문에,  동시 업데이트 문제가 발생하지 않으며,
    @objc private func numberButtonTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        
        switch title {
        case "+", "-", "*", "/":
            currentState = reduce(state: currentState, action: .operation(title))
        case "AC":
            currentState = reduce(state: currentState, action: .clear)
        case "=":
            currentState = reduce(state: currentState, action: .equals)
        default:
            currentState = reduce(state: currentState, action: .number(title))
        }
        
        numberLabel.text = currentState.displayNumber
        operatorLabel.text = currentState.displayOperator
    }
}
