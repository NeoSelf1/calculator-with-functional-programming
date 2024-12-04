iOS 함수형 계산기 앱
UIKit과 MVC 아키텍처를 기반으로 한 함수형 프로그래밍 방식의 계산기 애플리케이션입니다.

💡 주요 특징
1. 함수형 프로그래밍 원칙 적용
- 불변성 (Immutability)
- 순수 함수 (Pure Functions)
- 타입 안전성 (Type Safety)
- 상태 관리 (State Management)

2. 기본적인 사칙연산 구현

🏗 프로젝트 구조
핵심 컴포넌트
```
// 계산기의 상태를 표현하는 불변 구조체
struct CalculatorState {
    let displayNumber: String
    let storedNumber: Double?
    let operation: String?
    let shouldResetDisplay: Bool
}
```
```
// 계산기 동작을 정의하는 열거형
enum CalculatorAction {
    case number(String)
    case operation(String)
    case clear
    case equals
}
```

주요 순수 함수들
```
// 숫자 포매팅
func formatNumber(_ number: Double) -> String

// 연산 수행
func perform(operation: String, first: Double, second: Double) -> Double

// 상태 변환
func reduce(state: CalculatorState, action: CalculatorAction) -> CalculatorState
```

📝 구현 설명

1. 불변성 원칙
- 모든 상태 변경은 새로운 상태 객체 생성으로 이루어지기 때문에, 직접적인 값 수정은 없습니다.

2. 순수 함수 사용
- 동일 입력에 대해 항상 동일 출력 보장하게 설계하였습니다.
- 부수 효과(Side Effects) 최소화하였습니다.

3. 타입 안전성
- 모든 동작을 열거형으로 정의하였습니다.
