param(
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateRoot = Join-Path $ScriptRoot 'templates'
$ConfigRoot = Join-Path $ScriptRoot 'config'

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $ScriptRoot 'output'
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Read-RequiredText {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt
    )

    while ($true) {
        $value = Read-Host $Prompt
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }

        Write-Host '값이 필요합니다. 다시 입력하세요.' -ForegroundColor Yellow
    }
}

function Read-ExistingPath {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt
    )

    while ($true) {
        $value = Read-RequiredText -Prompt $Prompt
        if (Test-Path -LiteralPath $value) {
            return (Resolve-Path -LiteralPath $value).Path
        }

        Write-Host '존재하는 파일 경로를 입력하세요.' -ForegroundColor Yellow
    }
}

function Read-FreeTextWithDefault {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)][string]$DefaultValue
    )

    $value = Read-Host "$Prompt [기본값: $DefaultValue]"
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $DefaultValue
    }

    return $value.Trim()
}

function Read-Choice {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][array]$Choices,
        [int]$DefaultIndex = 0
    )

    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan

    for ($i = 0; $i -lt $Choices.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $Choices[$i])
    }

    while ($true) {
        $raw = Read-Host ("선택하세요 [1-{0}] (기본값: {1})" -f $Choices.Count, ($DefaultIndex + 1))

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $Choices[$DefaultIndex]
        }

        $raw = $raw.Trim()
        [int]$selectedNumber = 0
        if ([int]::TryParse($raw, [ref]$selectedNumber)) {
            if ($selectedNumber -ge 1 -and $selectedNumber -le $Choices.Count) {
                return $Choices[$selectedNumber - 1]
            }
        }

        foreach ($choice in $Choices) {
            if ($choice -eq $raw) {
                return $choice
            }
        }

        Write-Host '지원하지 않는 선택입니다. 번호 또는 표시된 값을 사용하세요.' -ForegroundColor Yellow
    }
}

function Convert-ListToBulletText {
    param(
        [Parameter(Mandatory = $true)][array]$Items
    )

    return (($Items | ForEach-Object { "- $_" }) -join "`r`n")
}

function Render-Template {
    param(
        [Parameter(Mandatory = $true)][string]$TemplatePath,
        [Parameter(Mandatory = $true)][hashtable]$Variables
    )

    $content = Get-Content -LiteralPath $TemplatePath -Raw
    foreach ($key in $Variables.Keys) {
        $content = $content.Replace("{{${key}}}", [string]$Variables[$key])
    }

    return $content
}

function New-ResultPlaceholder {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Path
    )

$content = @"
# $Title

이 파일에는 AI CLI에서 받은 결과를 붙여넣으세요.

- 생성 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- 저장 파일: $(Split-Path -Leaf $Path)
"@

    Write-Utf8File -Path $Path -Content $content.TrimStart()
}

$providerConfigs = @{}
$providerFiles = Get-ChildItem -LiteralPath $ConfigRoot -Filter '*.json' | Sort-Object Name
foreach ($file in $providerFiles) {
    $config = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
    $providerConfigs[$config.id] = $config
}

$providerOptions = @(
    @{ Id = 'codex'; Label = 'Codex CLI' },
    @{ Id = 'claude'; Label = 'Claude CLI' },
    @{ Id = 'gemini'; Label = 'Gemini CLI' },
    @{ Id = 'other'; Label = '기타 AI CLI' }
)

$objectiveOptions = @(
    '비판 검토 포함 실행 계획',
    'QA/버그 대응 분석',
    '기능 기획 검증',
    '리팩터링 계획',
    '기타'
)

$criticismOptions = @(
    '낮음',
    '보통',
    '높음',
    '매우 높음'
)

$outputOptions = @(
    '간결한 실행 계획',
    '상세 실행 계획',
    '리스크 중심 검토서',
    'QA 체크리스트 포함 결과',
    '의사결정 로그 포함 결과'
)

Write-Host 'AI 오케스트레이션 전달용 프롬프트 생성기를 시작합니다.' -ForegroundColor Green
Write-Host '질문에 답하면 어떤 AI CLI에서도 재사용 가능한 라운드별 프롬프트와 실행 가이드를 만들어 줍니다.' -ForegroundColor Green

$sourceDocumentPath = Read-ExistingPath -Prompt '1) 기준 문서 파일 경로를 입력하세요'
$selectedProviderLabel = Read-Choice -Title '2) 사용할 AI를 선택하세요' -Choices ($providerOptions | ForEach-Object { $_.Label }) -DefaultIndex 0
$selectedProvider = ($providerOptions | Where-Object { $_.Label -eq $selectedProviderLabel } | Select-Object -First 1).Id

$runObjective = Read-Choice -Title '3) 이번 실행 목적을 선택하세요' -Choices $objectiveOptions -DefaultIndex 0
if ($runObjective -eq '기타') {
    $runObjective = Read-RequiredText -Prompt '실제 실행 목적을 입력하세요'
}

$criticismLevel = Read-Choice -Title '4) 비판 검토 강도를 선택하세요' -Choices $criticismOptions -DefaultIndex 2
$riskFocus = Read-FreeTextWithDefault -Prompt '5) 꼭 확인해야 하는 리스크를 입력하세요(쉼표 구분 가능)' -DefaultValue '공통 컴포넌트 영향, 상태 관리, 라이프사이클, 회귀 위험'
$outputFormat = Read-Choice -Title '6) 원하는 결과 형식을 선택하세요' -Choices $outputOptions -DefaultIndex 1

$providerConfig = $providerConfigs[$selectedProvider]
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$createdAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$sourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($sourceDocumentPath)
$safeSourceBaseName = [System.Text.RegularExpressions.Regex]::Replace($sourceBaseName, '[^a-zA-Z0-9가-힣_-]', '_')
$sessionDir = Join-Path $OutputRoot ("session_{0}_{1}" -f $timestamp, $safeSourceBaseName)

New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null

$sessionSummaryPath = Join-Path $sessionDir '00_session_summary.md'
$analysisPromptPath = Join-Path $sessionDir '01_analysis_prompt.md'
$criticalReviewPromptPath = Join-Path $sessionDir '02_critical_review_prompt.md'
$finalPlanPromptPath = Join-Path $sessionDir '03_final_plan_prompt.md'
$executionGuidePath = Join-Path $sessionDir '04_execution_guide.md'
$analysisResultPath = Join-Path $sessionDir '11_analysis_result.md'
$criticalReviewResultPath = Join-Path $sessionDir '12_critical_review_result.md'
$finalResultPath = Join-Path $sessionDir '13_final_plan_result.md'

$variables = @{
    SOURCE_DOCUMENT_PATH = $sourceDocumentPath
    PROVIDER_NAME = $providerConfig.displayName
    RUN_OBJECTIVE = $runObjective
    CRITICISM_LEVEL = $criticismLevel
    RISK_FOCUS = $riskFocus
    OUTPUT_FORMAT = $outputFormat
    SESSION_CREATED_AT = $createdAt
    ANALYSIS_RESULT_PATH = $analysisResultPath
    CRITICAL_REVIEW_RESULT_PATH = $criticalReviewResultPath
    FINAL_RESULT_PATH = $finalResultPath
}

$analysisPrompt = Render-Template -TemplatePath (Join-Path $TemplateRoot 'analysis_prompt.md') -Variables $variables
$criticalReviewPrompt = Render-Template -TemplatePath (Join-Path $TemplateRoot 'critical_review_prompt.md') -Variables $variables
$finalPlanPrompt = Render-Template -TemplatePath (Join-Path $TemplateRoot 'final_plan_prompt.md') -Variables $variables

$sessionSummary = @"
# 세션 요약

- 생성 시각: $createdAt
- 기준 문서: $sourceDocumentPath
- 사용 AI: $($providerConfig.displayName)
- 실행 목적: $runObjective
- 비판 검토 강도: $criticismLevel
- 리스크 포커스: $riskFocus
- 결과 형식: $outputFormat

## 생성 파일
- 01_analysis_prompt.md
- 02_critical_review_prompt.md
- 03_final_plan_prompt.md
- 04_execution_guide.md
- 11_analysis_result.md
- 12_critical_review_result.md
- 13_final_plan_result.md
"@

$providerSetupText = Convert-ListToBulletText -Items $providerConfig.sessionSetup
$providerPasteText = Convert-ListToBulletText -Items $providerConfig.pasteAdvice
$providerFollowUpText = Convert-ListToBulletText -Items $providerConfig.followUpAdvice

$executionGuide = @"
# 실행 가이드

## 1. 이번 세션 설정
- 기준 문서: $sourceDocumentPath
- 사용 AI: $($providerConfig.displayName)
- 실행 목적: $runObjective
- 비판 검토 강도: $criticismLevel
- 꼭 확인할 리스크: $riskFocus
- 원하는 결과 형식: $outputFormat

## 2. 세션 시작 전 준비
$providerSetupText

## 3. 라운드별 실행 순서
1. AI CLI에서 대상 프로젝트를 열거나, 최소한 기준 문서와 관련 코드에 접근 가능한 상태를 만듭니다.
2. 01_analysis_prompt.md와 기준 문서를 함께 넣어 초기 분석을 받습니다.
3. 받은 답변을 11_analysis_result.md에 저장합니다.
4. 02_critical_review_prompt.md, 기준 문서, 11_analysis_result.md를 함께 넣어 비판 검토를 받습니다.
5. 받은 답변을 12_critical_review_result.md에 저장합니다.
6. 03_final_plan_prompt.md, 기준 문서, 11_analysis_result.md, 12_critical_review_result.md를 함께 넣어 최종 계획을 받습니다.
7. 받은 답변을 13_final_plan_result.md에 저장합니다.

## 4. 대화 중 반드시 지킬 운영 규칙
- 파일 경로를 추측으로 쓰지 말고 실제 경로인지 후보 경로인지 구분하게 하세요.
- 사실과 가정을 섞으면 다시 분리해서 작성하게 하세요.
- 공통 컴포넌트, 상태 관리, 라이프사이클, 비동기 타이밍, 회귀 포인트가 빠지면 보완하게 하세요.
- 코드에 직접 접근하지 못한 답변이면 코드 미검증 또는 검증 불가를 명시하게 하세요.
- 최종 결과에는 구현 순서와 검증 순서가 모두 있어야 합니다.

## 5. 답변 품질이 약할 때 바로 쓸 후속 요청
$providerPasteText

$providerFollowUpText

## 6. 저장 규칙
- Round 1 결과 저장: 11_analysis_result.md
- Round 2 결과 저장: 12_critical_review_result.md
- Final 결과 저장: 13_final_plan_result.md
- 원문 요약본을 따로 만들지 말고, AI가 준 원문을 먼저 저장한 뒤 필요하면 사본을 만드세요.
"@

Write-Utf8File -Path $sessionSummaryPath -Content $sessionSummary.TrimStart()
Write-Utf8File -Path $analysisPromptPath -Content $analysisPrompt
Write-Utf8File -Path $criticalReviewPromptPath -Content $criticalReviewPrompt
Write-Utf8File -Path $finalPlanPromptPath -Content $finalPlanPrompt
Write-Utf8File -Path $executionGuidePath -Content $executionGuide.TrimStart()

New-ResultPlaceholder -Title 'Round 1 분석 결과' -Path $analysisResultPath
New-ResultPlaceholder -Title 'Round 2 비판 검토 결과' -Path $criticalReviewResultPath
New-ResultPlaceholder -Title 'Final 종합 계획 결과' -Path $finalResultPath

if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    Set-Clipboard -Value $analysisPrompt
}

Write-Host ''
Write-Host '생성이 완료되었습니다.' -ForegroundColor Green
Write-Host ("세션 폴더: {0}" -f $sessionDir)
Write-Host ("첫 번째 프롬프트: {0}" -f $analysisPromptPath)
Write-Host ("실행 가이드: {0}" -f $executionGuidePath)
Write-Host ''
Write-Host '다음 순서로 진행하세요.' -ForegroundColor Cyan
Write-Host '1. 선택한 AI CLI를 프로젝트와 함께 엽니다.'
Write-Host '2. 01_analysis_prompt.md를 기준 문서와 함께 넣습니다.'
Write-Host '3. 응답을 11_analysis_result.md에 저장합니다.'
Write-Host '4. 02_critical_review_prompt.md로 비판 검토를 진행합니다.'
Write-Host '5. 03_final_plan_prompt.md로 최종 계획을 받습니다.'
