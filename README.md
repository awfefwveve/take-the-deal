# TAKE THE DEAL · 0.2 리뉴얼

강제 광고 없이 달리고, 선택한 능력으로 장애물을 부수는 세로형 3D 러너입니다.
현재 결과물은 **Windows에서 실행·검증한 오프라인 플레이테스트와 멀티플랫폼 Godot 소스**입니다. 스토어에 바로 제출할 완제품이나 서명된 Android/iOS 빌드는 아닙니다.

## 바로 실행

`Windows/TakeTheDeal.exe`를 실행하세요. 같은 폴더의 `TakeTheDeal.pck`가 필요합니다. ZIP으로 받았다면 전체를 먼저 압축 해제하세요.

- 마우스 좌우 드래그 또는 A/D, 방향키: 이동
- SHRINK 또는 스페이스: 축소/복귀. 낮은 문·레이저를 통과합니다.
- 보스전에서는 HIT 또는 스페이스: 공격. 공격 재사용 대기시간이 있습니다.
- 우측 상단 II 또는 Escape: 일시정지, 소리·진동 설정, 데이터 삭제
- 녹색 코인 경로: 광고 없이 통과할 수 있는 경로
- Deal: 무료 체험 또는 거절. 체험 취소 시 보상 없이 원래 게임으로 돌아갑니다.

홈에서 ‘달리기 시작’을 누르면 플레이가 시작됩니다. 1스테이지에는 Deal이 없고 중간에 무료 거인 파워를 체험합니다. 2스테이지부터 선택형 Deal이 등장합니다. 모든 스테이지에는 무료 파워 한 번이 포함되며, 광고 거절과 무관합니다. 체험 화면에는 실제 광고가 아니라는 안내를 표시했습니다.

## 0.2에서 달라진 점

- 한국어 글꼴·색상·여백을 통일한 홈, 소형 HUD, Deal, 결과, 스테이지 선택, 꾸미기, 업그레이드 화면
- 둥근 캐릭터, 입체 코인, 캐릭터 팔·다리 애니메이션, 원본 마림바 배경음악
- 코코넛 해변 / 선셋 캐니언 / 캔디 가든 / 프로즌 피크 / 로봇 팩토리 / 스타라이트 시티
- 6개 월드 × 5개 고정 레벨 조합. 30레벨 이후 시드 기반 경로 변형
- 12개 의상의 모자·안테나·뿔·망토·왕관 등 독립 장식과 실제 3D 썸네일
- 능력별 탱크·제트팩·로켓·드래곤·철거공·망치 등의 서로 다른 메시
- 거인 크기에 맞춘 파괴 범위, 실제 벽돌·적을 날리는 파편, 타격 순간 감속
- 스테이지 목표 3종(코인 수집·무피격·파괴), 목표 보너스, 콤보 피드백, 별 3개 평가와 최고 별 저장
- 보스별 순환/양옆/추적/한쪽 봉쇄/안전 칸 이동/혼합 공격. 항상 최소 한 칸 회피 경로 유지
- 분신 50명의 메시 인스턴싱, 먼 장애물 숨김으로 불필요한 렌더링 감소

## 이번 구현

- 직접 생성한 로우폴리 캐릭터·장애물·배경, 파편, 효과음, 카메라 흔들림
- 약 27~45초 플레이. 보스는 5레벨마다 등장
- 월드별 패턴을 설계한 30개 레벨과 이후 반복 조합
- 인접한 안전 경로, 축소 통과, 충돌 후 무적 시간, 실패/재도전
- 20개 이름의 Deal 변형. 확대·차량·비행·빔·정지·복제·보호·가속·자석 계열 재사용
- 여섯 보스 외형과 공격 패턴, 예고 후 공격, 무료 회피·공격
- 3종 업그레이드, 12종 의상, 승리 횟수 해제
- 진행 저장·값 검증·체크섬, 임시 파일 후 저장 교체
- 로컬 진단 이벤트, 소리·진동 설정, 로컬 데이터 삭제
- Android/iOS 내보내기 설정 초안
- 서버에서 사용할 광고 서명 검증·중복 지급 차단 코어와 테스트

아트는 코드로 만든 스타일화된 메시이며 외부 모델을 구매하지 않았습니다. 의상은 공통 몸체에 개별 장식을 조합합니다. 장애물과 능력은 공통 시스템을 재사용하며 차량·물·불의 사실적인 물리 시뮬레이션은 없습니다. 스테이지는 고정 레시피의 모듈 조합입니다.

## 개발

Godot 4.4.1 Standard로 `project.godot`을 엽니다. 외부 게임 자산·플러그인 설치가 필요하지 않습니다. Windows 체험판은 공식 엔진 실행 파일에 게임 팩을 연결한 개발용 패키지이므로 최적화된 정식 export보다 큽니다.

```text
scripts/game.gd          플레이, 입력, 화면, 오디오, 보스
scripts/catalog.gd       레벨, 능력, 스킨, 가격 데이터
scripts/art.gd           캐릭터, 의상, 능력 메시와 6개 월드 아트
scripts/interface.gd     한국어 UI와 3D 미리보기
scripts/ui_icon.gd       직접 그리는 UI 아이콘
scripts/profile.gd       오프라인 저장과 입력값 검증
scripts/reward_gate.gd   체험 보상의 상태 전이 및 중복 방지
server/reward_ledger.py  배포 전 연결이 필요한 서버 검증 코어
tests/                  엔진 내 테스트
```

```sh
godot --headless --path . --script res://tests/test_core.gd
godot --headless --path . --script res://tests/test_game.gd
godot --headless --path . --script res://tests/test_v2.gd
godot --headless --path . --fixed-fps 60 -- --autoplay --level=5
python -m unittest discover -s server -v
```

서버 테스트는 `server/requirements.txt`의 cryptography 라이브러리가 필요합니다. 자동 플레이는 실제 게임 충돌·보스 로직을 통과하지만 사람의 재미, 첫 플레이 이해도, 모바일 성능을 입증하지 않습니다. 테스트에는 별도 사용자 데이터 폴더를 사용하세요.

## 광고와 개인정보

이 빌드는 광고 SDK·Firebase·외부 통신을 포함하지 않습니다. 실제 광고 수익이나 사용자 분석을 수집하지 않습니다. 로컬 `preview_events.jsonl`을 기록하며 약 512KB에서 순환합니다. 체험 성공 이벤트는 `preview_complete`로 기록하고 실제 `rewarded_complete`로 기록하지 않습니다.

저장 위치는 Godot의 `user://`이며 일반 Windows에서는 `%APPDATA%/Godot/app_userdata/TAKE THE DEAL — Playtest/`입니다. 테스트 실행 환경에서는 별도 데이터 폴더를 사용했습니다.

## 출시 전 필수 작업

1. 실제 Android 기기에서 터치·백그라운드 복귀·종횡비·발열·저사양 성능을 검증합니다. 현재 Windows에서만 실행 검증했습니다.
2. 최신 스토어 요구사항에 맞는 Godot 버전·내보내기 템플릿·Android SDK/JDK를 선택하고 APK/AAB를 빌드합니다. 현재 APK/AAB는 생성하지 않았습니다.
3. 소유한 패키지 ID로 `com.example...`를 교체하고 서명키·Play Console 계정을 연결합니다. 서명키는 소스에 넣지 않습니다.
4. 정식 AdMob 보상형 SDK, 테스트 광고, 동의 흐름, 서버 SSV 검증을 통합합니다. 광고 실패 시 무료 경로로 복귀하도록 유지합니다.
5. 서버 인증, 세션과 허용 Deal 결정, 속도 제한, Play Integrity 검증, HTTPS 서비스·키 갱신·DB 백업을 구현하고 운영 환경에서 테스트합니다. 현재 서버 코어는 네트워크 서비스가 아닙니다.
6. Firebase 분석/크래시 리포팅, 동의 여부에 따른 수집 제어, 개인정보처리방침·데이터 보안 신고를 실제 SDK 구성에 맞춰 준비합니다.
7. 사용자 테스트로 조작 난이도·Deal 빈도·재방문율과 개선된 콘텐츠의 재미를 검증합니다.
8. 최종 아이콘·스토어 스크린샷·영상, 연령 등급, 게임명/상표 확인과 출시 심사를 진행합니다. 현재 아이콘은 프로젝트용 원본 SVG입니다.
9. iOS는 macOS/Xcode와 Apple 개발자 계정으로 별도 빌드·서명·실기기 검증이 필요합니다.

## 공식 참고

- Godot 내보내기: https://docs.godotengine.org/en/stable/tutorials/export/index.html
- AdMob SSV: https://developers.google.com/admob/android/ssv
- Play Integrity: https://developer.android.com/google/play/integrity/standard

현재 산출물에 포함된 Godot 엔진에는 Windows 폴더의 MIT 라이선스와 제3자 고지가 적용됩니다. Jua 글꼴은 SIL Open Font License이며 `assets/Jua-OFL.txt`를 포함했습니다. 게임의 코드·메시·효과음·배경음악·아이콘은 이 작업에서 생성했습니다.
