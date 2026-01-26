# OtoMON-K Claude Code 설정

이 저장소는 OtoMON-K 프로젝트의 Claude Code 설정을 관리합니다.
심볼릭링크를 통해 여러 컴퓨터에서 동일한 설정과 메모리를 공유할 수 있습니다.

## 포함 파일

| 파일 | 설명 |
|------|------|
| `.claude/` | Claude Code 설정 폴더 (plans, docs, settings 등) |
| `.claude/memory.json` | MCP Memory 영속 저장소 (작업 이력, 컨텍스트) |
| `.mcp.json` | MCP 서버 설정 (MariaDB, Memory, Playwright 등) |
| `setup-claude.ps1` | 자동 설정 스크립트 |

## 새 컴퓨터 설정 방법

### 1. 개인 Git Clone

```bash
cd C:\Users\user
git clone https://github.com/HongseockKim/my-claude-config.git my-claude-configs
```

### 2. 설정 스크립트 실행 (관리자 PowerShell)

```powershell
# 관리자 권한으로 PowerShell 실행 후
cd C:\Users\user\my-claude-configs\OtoMON-K
.\setup-claude.ps1
```

스크립트가 자동으로:
- `.claude/` 폴더를 Junction으로 연결
- `.mcp.json` 파일을 심볼릭링크로 연결

### 3. Claude Code 재시작

설정 적용을 위해 Claude Code를 재시작합니다.

## 수동 설정 (스크립트 없이)

```powershell
# 관리자 PowerShell에서 실행

# 1. 프로젝트 폴더로 이동
cd C:\Users\user\IdeaProjects\OtoMON-K

# 2. 기존 .claude 폴더 삭제 (있는 경우)
Remove-Item .claude -Recurse -Force

# 3. Junction 생성
cmd /c mklink /J .claude "C:\Users\user\my-claude-configs\OtoMON-K\.claude"

# 4. .mcp.json 심볼릭링크 생성
Remove-Item .mcp.json -Force
cmd /c mklink .mcp.json "C:\Users\user\my-claude-configs\OtoMON-K\.mcp.json"
```

## 동기화 방법

### 변경사항 Push (현재 PC)
```bash
cd C:\Users\user\my-claude-configs
git add .
git commit -m "설정 업데이트"
git push
```

### 변경사항 Pull (다른 PC)
```bash
cd C:\Users\user\my-claude-configs
git pull
```

## MCP Memory 설정

`.mcp.json`에서 Memory 서버가 `.claude/memory.json`에 저장하도록 설정되어 있습니다:

```json
"memory": {
  "env": {
    "MEMORY_FILE_PATH": "C:/Users/user/IdeaProjects/OtoMON-K/.claude/memory.json"
  }
}
```

이를 통해:
- 작업 이력이 파일로 영속 저장됨
- Git을 통해 다른 PC와 메모리 공유 가능
- Claude가 이전 작업 컨텍스트를 기억함

## 주의사항

- `setup-claude.ps1`은 **관리자 권한**이 필요합니다
- `.mcp.json`의 DB 비밀번호 등 민감정보 주의
- 이 저장소는 **Private**로 유지하세요
