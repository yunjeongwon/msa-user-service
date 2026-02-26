# User Service

사용자 생성, 인증(JWT 발급), 활동 점수 관리를 담당하는 서비스입니다.  
Event-Driven 구조에서 사용자 도메인의 Source of Truth 역할을 수행합니다.

---

## 1. 역할 (Responsibility)

- 회원가입
- 로그인 (JWT 발급)
- 사용자 조회 (Internal API)
- 활동 점수 관리
- 사용자 관련 이벤트 발행 및 소비

---

## 2. 회원가입 처리 흐름

1. 사용자 정보 DB 저장
2. Point Service 동기 호출 → 초기 포인트 1000 지급
3. `user.signed-up` 이벤트 발행

```text
Client → Gateway → User Service
                        │
                        ├─ save user
                        ├─ call point-service (동기)
                        └─ publish user.signed-up (Kafka)
```

### 설계 의도

- 포인트 지급은 회원가입 성공의 일부로 간주하여 동기 처리
- 이후 확장 가능한 처리를 위해 이벤트 발행
- Board Service는 해당 이벤트를 구독하여 Read Model을 구성

---

## 3. 로그인 및 JWT 발급

- 이메일/비밀번호 기반 인증
- JWT subject에 `userId` 저장
- Gateway에서 JWT 검증 후 내부 서비스에 `X-User-Id` 헤더 전달

### 현재 구현 특징

- 비밀번호는 평문 비교 방식 (학습 목적의 단순 구현)
- 토큰 만료 시간 및 추가 Claim 없음

운영 환경에서는 다음 보완이 가능합니다:

- BCrypt 기반 비밀번호 암호화
- JWT 만료 시간(exp) 설정
- Refresh Token 구조 도입

---

## 4. 활동 점수 처리

### 이벤트 기반 점수 적립

`board.created` 이벤트를 소비하여 활동 점수를 증가시킵니다.

```text
Board Service → Kafka(board.created)
                          ↓
                    User Service (Consumer)
                          ↓
                    addActivityScore()
```

### 설계 특징

- 게시글 작성은 User Service를 직접 호출하지 않음
- 이벤트 기반 비동기 처리로 결합도 감소
- 즉시 반영이 필요하지 않은 로직은 비동기 처리

### 멱등성 고려

Kafka는 at-least-once 전달 모델이므로  
동일 이벤트가 중복 소비될 수 있습니다.

현재는 단순 구현 구조이며,  
운영 환경에서는 이벤트 ID 기반 중복 방지 전략을 적용할 수 있습니다.

---

## 5. 트랜잭션 처리

- `signUp()` → `@Transactional`
- `addActivityScore()` → `@Transactional`
- `login()` → `@Transactional`

현재 구조는 단일 인스턴스 환경을 가정한 기본 트랜잭션 처리입니다.

---

## 6. 내부 API

Internal ALB를 통해서만 접근합니다.

### 사용자 조회
GET `/internal/users/{userId}`

GET `/internal/users?ids=1,2,3`

### 활동 점수 적립
POST `/internal/users/activity-score/add`

---

## 7. 이벤트 목록

### 발행
- `user.signed-up`

### 소비
- `board.created`

---

## 8. 기술 스택

- Spring Boot
- Spring Data JPA
- MySQL (RDS)
- Kafka (MSK)
- JWT (jjwt)

---

## 9. Local 실행

```bash
docker-compose up -d
```

기본 포트: 8080
