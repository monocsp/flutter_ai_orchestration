# AI Orchestration Workbench — 제품 소개서

## 한 줄 요약

기획서를 넣으면 여러 AI가 자동으로 분석 → 비판 → 보강 → 검증 → 최종 계획을 만들어주는 데스크톱 앱입니다.

---

## 왜 만들었나

### 문제

개발팀에서 기획서나 이슈를 받으면, 실행 계획을 만들기까지 이런 과정을 거칩니다:

1. AI CLI에 기획서를 붙여넣고 분석 요청
2. 결과를 읽고, 빠진 부분이 있으면 다시 요청
3. 다른 AI에도 같은 문서를 넣어서 비교
4. 최종 계획서를 직접 정리

**문제점:**
- 매번 수동으로 복사-붙여넣기 반복
- AI마다 다른 CLI 사용법을 외워야 함
- 5단계 오케스트레이션을 수동으로 하면 1~2시간 소요
- 결과물이 파일로 정리되지 않아 추적이 어려움

### 해결

**AI Orchestration Workbench**는 이 전체 과정을 자동화합니다.

- 기획서 드래그 → 버튼 한 번 → 5단계 자동 완료
- 결과는 Markdown 파일로 자동 저장
- 진행 상황을 실시간으로 확인
- 여러 AI의 결과를 한 화면에서 비교

---

## 핵심 기능

### 1. 순차 오케스트레이션

```mermaid
graph LR
    A[기획서] --> B["Step 1<br/>1차 분석<br/><i>Claude</i>"]
    B --> C["Step 2<br/>1차 비판<br/><i>Codex</i>"]
    C --> D["Step 3<br/>분석 보강<br/><i>Claude</i>"]
    D --> E["Step 4<br/>2차 비판<br/><i>Codex</i>"]
    E --> F["Step 5<br/>최종 계획<br/><i>Claude</i>"]
    F --> G[실행 계획서]

    style B fill:#0d9488,color:#fff
    style C fill:#f97316,color:#fff
    style D fill:#0d9488,color:#fff
    style E fill:#f97316,color:#fff
    style F fill:#0d9488,color:#fff
```

- 분석 AI와 검토 AI가 번갈아 5단계를 수행
- 각 단계가 이전 단계의 결과를 입력으로 받아 품질을 높임
- **비판 검토**가 포함되어 AI의 환각(hallucination)과 누락을 잡아냄

**프리셋 5종:**

| 프리셋 | 용도 |
|--------|------|
| 기본 5단계 비판형 | 일반적인 기술 분석 |
| 빠른 3단계 경량형 | 간단한 작업 |
| QA/버그 대응형 | 버그 분석 → 원인 검증 → 수정 계획 |
| 기능 기획 검증형 | 새 기능 실현 가능성 검토 |
| 리팩터링 계획형 | 구조 개선 설계 |

### 2. 병렬 비교

```mermaid
graph LR
    A[기획서 + 프롬프트] --> B[Claude]
    A --> C[Codex]
    A --> D[Gemini]
    B --> E[결과 비교]
    C --> E
    D --> E

    style B fill:#0d9488,color:#fff
    style C fill:#6366f1,color:#fff
    style D fill:#f97316,color:#fff
```

- 동일한 문서를 여러 AI에 동시 실행
- Agent별 탭으로 결과 비교
- 실행 시간 표시
- 어떤 AI가 더 좋은 분석을 하는지 판단 가능

### 3. 실시간 진행 상황

- 사이드 레일에 진행률 링 표시
- 순차: 원형 프로그레스 (N/M 단계)
- 병렬: Agent 수만큼 분할된 세그먼트 링 (각각 성공/실패 색상)
- 중단 버튼으로 언제든 멈출 수 있음

### 4. 프롬프트 관리

- 5단계 각각의 프롬프트를 앱에서 확인/편집 가능
- 수정한 프롬프트는 저장되어 다음에 자동 사용
- 기본 템플릿으로 되돌리기 가능

---

## 대상 사용자

```mermaid
mindmap
  root((AI Orchestration<br/>Workbench))
    개발자
      기획서 → 실행 계획
      AI별 분석 비교
    기획자
      기술 실현 가능성 검증
      리스크 사전 파악
    QA
      버그 원인 분석
      수정 계획 자동 생성
    테크 리드
      리팩터링 영향 범위
      아키텍처 변경 검토
```

---

## 동작 흐름

### 순차 오케스트레이션

```mermaid
sequenceDiagram
    actor User as 사용자
    participant App as Workbench
    participant CLI as AI CLI

    User->>App: 기획서 드래그
    User->>App: 설정 (Agent, 프리셋)
    User->>App: [오케스트레이션 시작]

    App->>CLI: Agent 설치 확인
    CLI-->>App: 확인 완료

    loop 5단계 자동 반복
        App->>CLI: Step N 프롬프트 전달
        Note over App: 진행 상황 실시간 표시
        CLI-->>App: Step N 결과
        App->>App: 결과 파일 저장
    end

    App-->>User: 전체 완료 알림
    User->>App: 결과 확인 / 복사
```

### 병렬 비교

```mermaid
sequenceDiagram
    actor User as 사용자
    participant App as Workbench
    participant C as Claude
    participant X as Codex
    participant G as Gemini

    User->>App: 기획서 + 프롬프트
    User->>App: Agent 3개 선택
    User->>App: [병렬 실행 시작]

    par 동시 실행
        App->>C: 프롬프트 전달
        App->>X: 프롬프트 전달
        App->>G: 프롬프트 전달
    end

    C-->>App: Claude 결과
    Note over App: 세그먼트 링 업데이트
    X-->>App: Codex 결과
    G-->>App: Gemini 결과

    App-->>User: Agent별 탭으로 비교
```

---

## 기술 아키텍처

```mermaid
graph TB
    subgraph Flutter["Flutter Desktop App"]
        subgraph Features["Features (UI)"]
            WB[Workbench]
            SS[Session Setup]
            SE[Stage Editor]
            TV[Thread View]
            PV[Parallel View]
            DC[Documents]
            TU[Tutorial]
        end

        subgraph Providers["Providers (Riverpod)"]
            SN[SessionNotifier]
            TN[ThreadNotifier]
            AP[AgentStatusProvider]
        end

        subgraph Core["Core (Services)"]
            AR[AgentRunner]
            SB[SessionBuilder]
            TR[TemplateRenderer]
            AD[AgentDetection]
            CL[ConfigLoader]
            EL[ErrorLog]
        end
    end

    subgraph CLI["AI CLI Layer"]
        Claude
        Codex
        Gemini
        Copilot
    end

    Features --> Providers
    Providers --> Core
    Core -->|Process.run| CLI

    style Flutter fill:#f8fafc,stroke:#e2e8f0
    style Features fill:#f0fdfa,stroke:#0d9488
    style Providers fill:#eef2ff,stroke:#6366f1
    style Core fill:#fff7ed,stroke:#f97316
    style CLI fill:#1e293b,color:#fff,stroke:#475569
```

### 상태 관리

```mermaid
stateDiagram-v2
    [*] --> Setup: 앱 시작
    Setup --> AgentCheck: 오케스트레이션 시작
    AgentCheck --> Running: Agent 확인 통과
    AgentCheck --> Failed: Agent 미설치
    Running --> Running: 단계 진행
    Running --> Completed: 모든 단계 완료
    Running --> Failed: 단계 실행 실패
    Running --> Failed: 사용자 중단

    state Running {
        [*] --> Step1
        Step1 --> Step2: 결과 수신
        Step2 --> Step3
        Step3 --> Step4
        Step4 --> Step5
        Step5 --> [*]
    }
```

### AI CLI 실행 방식

```mermaid
flowchart LR
    A[프롬프트] --> B[임시 파일 저장]
    B --> C["zsh -l -c<br/>(유저 PATH)"]
    C --> D{Agent}
    D -->|Claude| E["claude -p<br/>--dangerously-skip-permissions"]
    D -->|Codex| F["codex exec<br/>$(cat file)"]
    D -->|Gemini| G["gemini -p<br/>$(cat file)"]
    E --> H[stdout 수신]
    F --> H
    G --> H
    H --> I[Markdown 파일 저장]
    I --> J[임시 파일 삭제]

    style D fill:#6366f1,color:#fff
```

---

## 결과물 구조

```mermaid
graph TD
    S["session_20260327_143000_기획서명/"]
    S --> A[00_session_summary.md]
    S --> B["01_analysis_prompt.md"]
    S --> C["02_critical_review_prompt.md"]
    S --> D["03_reinforced_analysis_prompt.md"]
    S --> E["04_second_review_prompt.md"]
    S --> F["05_final_plan_prompt.md"]
    S --> G["04_execution_guide.md"]
    S --> H["11_analysis_result.md"]
    S --> I["12_critical_review_result.md"]
    S --> J["13_reinforced_analysis_result.md"]
    S --> K["14_second_review_result.md"]
    S --> L["15_final_plan_result.md"]

    style A fill:#f1f5f9,stroke:#94a3b8
    style B fill:#f0fdfa,stroke:#0d9488
    style C fill:#f0fdfa,stroke:#0d9488
    style D fill:#f0fdfa,stroke:#0d9488
    style E fill:#f0fdfa,stroke:#0d9488
    style F fill:#f0fdfa,stroke:#0d9488
    style G fill:#fef3c7,stroke:#f59e0b
    style H fill:#dcfce7,stroke:#22c55e
    style I fill:#dcfce7,stroke:#22c55e
    style J fill:#dcfce7,stroke:#22c55e
    style K fill:#dcfce7,stroke:#22c55e
    style L fill:#dcfce7,stroke:#22c55e
```

| 색상 | 의미 |
|------|------|
| 회색 | 세션 메타 |
| 청록 | 프롬프트 (입력) |
| 노란 | 실행 가이드 |
| 녹색 | AI 결과 (출력) |

---

## 향후 로드맵

```mermaid
timeline
    title AI Orchestration Workbench 로드맵
    section Phase 1 — 안정화
        Windows 지원 : Flutter 멀티플랫폼 빌드
        에러 복구 : 실패 단계 재시도 기능
    section Phase 2 — 확장
        결과 Diff 비교 : 병렬 비교 결과를 나란히 비교
        세션 이력 관리 : 이전 세션 불러오기, 검색
        API 직접 호출 : CLI 대신 API 키로 직접 호출
    section Phase 3 — 협업
        팀 공유 : Slack / Notion 연동
        커스텀 단계 : 사용자 정의 단계 추가
        대시보드 : AI별 성능/비용 통계
```

---

## 요약

**AI Orchestration Workbench**는 "기획서 하나 넣으면 AI가 알아서 분석-검증-계획까지 만들어주는 도구"입니다.

```mermaid
graph LR
    A["수동 복붙<br/>❌"] -->|자동화| B["자동 실행<br/>✅"]
    C["단일 AI<br/>❌"] -->|교차 검증| D["다중 AI<br/>✅"]
    E["결과 흩어짐<br/>❌"] -->|파일 기반| F["추적 가능<br/>✅"]
    G["숙련자만<br/>❌"] -->|버튼 하나| H["누구나<br/>✅"]

    style A fill:#fef2f2,stroke:#ef4444
    style C fill:#fef2f2,stroke:#ef4444
    style E fill:#fef2f2,stroke:#ef4444
    style G fill:#fef2f2,stroke:#ef4444
    style B fill:#dcfce7,stroke:#22c55e
    style D fill:#dcfce7,stroke:#22c55e
    style F fill:#dcfce7,stroke:#22c55e
    style H fill:#dcfce7,stroke:#22c55e
```
