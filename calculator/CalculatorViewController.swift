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
    private var commands = [String]()
    
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
    
    // 프로젝트 내부 연산로직은 currentState 구조체가 바로 이전 자기자신의 상태값에 따라 갱신이 반복되며 이루어진다.
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
            // 연산자가 이미 추가되어 있는 상황의 경우, 두번째 피연산자 입력을 생략하고 바로 연산 및 결과값 갱신
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
    
    @objc private func numberButtonTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        // 데이터 상태(currentState)를 변화시키기 위해 수행하는 작업의 단위(Transaction) 자체를 commands 배열에 저장
        commands.append(title)
        // 트랜젝션의 배열을 통째로 인자로 넘겨 매 이벤트 호출마다 앱 시작 시점부터 발생한 모든 트랜잭션을 모두 누적연산
        // 이는 CRUD 중 U와 D가 이벤트 호출 간에 발생하지 않음을 의미, 동시 업데이트 문제 사전에 완전 방지 -> 완전한 불변성 가질 수 있게 됨.
        refreshState(commands)
    }
    
    private func refreshState(_ commands: [String]){
        // 초기화
        currentState = .initial
        
        // 고차함수 reduce의 로직과 동일하게 첫번째 커멘드부터 모든 연산을 시작
        commands.forEach{
            switch $0 {
            case "+", "-", "*", "/":
                currentState = reduce(state: currentState, action: .operation($0))
            case "AC":
                currentState = reduce(state: currentState, action: .clear)
            case "=":
                currentState = reduce(state: currentState, action: .equals)
            default:
                currentState = reduce(state: currentState, action: .number($0))
            }
        }
        
        // 트랜잭션이 모두 완료된 이후에서야 가변변수 numberLabel과 operatorLabel을 갱신
        // 경합조건, 교착상태 조건, 동시업데이트가 발생하는 원인을 최후 한번만 제어
        numberLabel.text = currentState.displayNumber
        operatorLabel.text = currentState.displayOperator
        
        // 완전한 불변성을 준수하기 위해선 currentState 구조체로 다수 상태값을 한번에 관리하는 것이 아닌, 상태값 하나당 고차함수를 삽입해 구조체 내부 다른 상태값에 영향받지 않도록 해야하지 않을까.
        // 은행 입금, 출금과 달리 계산기에는 연산자, 저장되어있는 값, 화면 리셋필요여부 등 다음 라벨값을 구하기 위해 동시에 확인해야하는 값이 여럿 존재.
        // 만약 currentState 내부 변수들을 제어하는 시점이 동일하다면, 문제가 없나?
    }
}
