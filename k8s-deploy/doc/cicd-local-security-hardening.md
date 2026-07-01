# CI/CD 로컬 보안 재구성 변경 내역

- 작성일: 2026-06-29
- 대상: `egovframe-operating-environment-msa-master` / F-06 (Critical)
- 근거: 로컬 Docker Desktop K8S 학습 템플릿 취약점 재검토 및 조치 가이드

## 1. 변경 목적

점검보고서 F-06은 Jenkins·GitLab·Nexus·SonarQube가 **NodePort**, **과도한 RBAC**, **privileged/hostPath**로 결합되어 Critical로 분류되었습니다.

본 변경은 **운영 배포용 완전 하드닝**이 아니라, 로컬 학습 환경에서 다음을 달성하는 것이 목표입니다.

| 목표 | 내용 |
|---|---|
| 외부 노출 최소화 | NodePort 제거 → ClusterIP + port-forward |
| 권한 축소 | Jenkins ClusterRole → `egov-cicd` namespace Role |
| 선택 설치 | 기본 `setup.sh`에서 CI/CD 제외 |
| GitLab 위험 완화 | 기본 설치에서 GitLab 제외 (privileged) |
| 스토리지 정리 | Jenkins/Nexus/SonarQube hostPath → local-path PVC |

## 2. 변경 파일 목록

### 신규 파일

| 파일 | 설명 |
|---|---|
| `k8s-deploy/manifests/egov-cicd/jenkins-pv-local-path.yaml` | Jenkins local-path PVC |
| `k8s-deploy/manifests/egov-cicd/nexus-pv-local-path.yaml` | Nexus local-path PVC |
| `k8s-deploy/manifests/egov-cicd/sonarqube-pv-local-path.yaml` | SonarQube local-path PVC |
| `k8s-deploy/scripts/utils/cicd-port-forward.sh` | CI/CD 서비스 일괄 port-forward |
| `k8s-deploy/doc/cicd-local-security-hardening.md` | 본 문서 |

### 수정 파일

| 파일 | 주요 변경 |
|---|---|
| `manifests/egov-cicd/jenkins-statefulset.yaml` | Role/RoleBinding, ClusterIP, PVC, Agent NodePort 제거 |
| `manifests/egov-cicd/gitlab-statefulset.yaml` | ClusterIP, hostPath placeholder, chmod 775 |
| `manifests/egov-cicd/nexus-statefulset.yaml` | ClusterIP, PVC |
| `manifests/egov-cicd/sonarqube-deployment.yaml` | ClusterIP, PVC |
| `scripts/setup/setup.sh` | CI/CD 선택 설치 (`--with-cicd`) |
| `scripts/setup/05-setup-cicd.sh` | PVC 선적용, GitLab 선택 설치, port-forward 안내 |
| `scripts/setup/09-show-access-info.sh` | CI/CD port-forward 접근 안내 |
| `scripts/cleanup/04-cleanup-cicd.sh` | Role/RoleBinding 정리 추가 |

## 3. 항목별 변경 상세

### 3.1 Jenkins RBAC (ClusterRole → Role)

**변경 전**

- `ClusterRole` + `ClusterRoleBinding`
- `pods/exec`에 `create/delete/get/list/patch/update/watch` 전체 권한
- 클러스터 전 namespace에 영향 가능

**변경 후**

- `Role` + `RoleBinding` (`namespace: egov-cicd`)
- `pods/exec`는 `create`, `get`만 허용
- Jenkins K8S agent는 `egov-cicd` namespace 내 Pod로 제한

**로컬 영향**: Jenkins 파이프라인·K8S agent 학습은 `egov-cicd` 내에서 동일하게 가능.

### 3.2 NodePort → ClusterIP + port-forward

**변경 전**

| 서비스 | NodePort |
|---|---|
| Jenkins Web | 30011 |
| Jenkins Agent | 30010 |
| GitLab | 30012 |
| SonarQube | 30013 |
| Nexus | 30014 |

**변경 후**

- 모든 CI/CD Service `type: ClusterIP`
- Jenkins Agent 외부 NodePort(30010) 제거 — in-cluster agent만 사용
- 로컬 접근은 port-forward로 동일 URL 유지

```bash
# 일괄 실행
k8s-deploy/scripts/utils/cicd-port-forward.sh start

# 개별 실행 예시
kubectl port-forward svc/jenkins -n egov-cicd 30011:8080
kubectl port-forward svc/sonarqube -n egov-cicd 30013:9000
kubectl port-forward svc/nexus -n egov-cicd 30014:8081
```

**효과**: LAN(0.0.0.0) NodePort 바인딩 제거 → 외부 네트워크 직접 접근 차단.

### 3.3 CI/CD 선택 설치

**변경 전**: `setup.sh`가 항상 `05-setup-cicd.sh` 실행

**변경 후**

```bash
# 기본 설치 (CI/CD 제외) — Istio/OTel/MSA 학습용
cd k8s-deploy/scripts/setup
./setup.sh

# CI/CD 포함 설치
./setup.sh --with-cicd

# CI/CD만 별도 설치
./05-setup-cicd.sh
```

환경변수: `INSTALL_CICD=true ./setup.sh`

### 3.4 GitLab 선택 설치 (privileged 완화)

GitLab CE 단일 Pod는 `privileged: true`가 필요할 수 있어 **기본 설치에서 제외**했습니다.

```bash
# GitLab hostPath를 로컬 경로로 수정 후
# manifests/egov-cicd/gitlab-statefulset.yaml 의
# /your/local/path/k8s-deploy/data/gitlab/* 를 실제 경로로 변경

INSTALL_GITLAB=true ./05-setup-cicd.sh
```

GitLab 미설치 시 Jenkins + Nexus + SonarQube로 CI 학습 가능.

### 3.5 스토리지: hostPath → local-path PVC

| 컴포넌트 | 변경 전 | 변경 후 |
|---|---|---|
| Jenkins | 개발자 PC 절대경로 hostPath | `jenkins-pvc-local` (local-path) |
| Nexus | 개발자 PC 절대경로 hostPath | `nexus-pvc-local` (local-path) |
| SonarQube | 개발자 PC 절대경로 hostPath | `sonarqube-pvc-local` (local-path) |
| GitLab | Windows Docker 경로 hostPath | placeholder 경로 (`/your/local/path/...`) |

**사전 요건**: Docker Desktop K8S에 `local-path` StorageClass가 있어야 합니다.

```bash
kubectl get storageclass
```

### 3.6 GitLab initContainer 권한

- `chmod 777` → `chmod 775`로 완화
- `privileged: true`는 GitLab CE 구조상 유지 (주석으로 사유 명시)

## 4. 사용 가이드

### 4.1 최초 설치 (CI/CD 포함)

```bash
cd k8s-deploy/scripts/setup
./setup.sh --with-cicd

# Pod Ready 확인 후
../../scripts/utils/cicd-port-forward.sh start
```

### 4.2 접속 URL (port-forward 실행 후)

| 서비스 | URL | 비고 |
|---|---|---|
| Jenkins | http://localhost:30011 | 초기 admin 비밀번호는 설치 스크립트 출력 |
| SonarQube | http://localhost:30013 | |
| Nexus | http://localhost:30014 | |
| GitLab | http://localhost:30012 | `INSTALL_GITLAB=true` 설치 시 |

### 4.3 CI/CD 제거

```bash
cd k8s-deploy/scripts/cleanup
./04-cleanup-cicd.sh

# port-forward 중지
k8s-deploy/scripts/utils/cicd-port-forward.sh stop
```

### 4.4 로컬 사용 시 권장 습관

- Docker Desktop K8S만 단독 PC에서 사용
- CI/CD 학습 종료 후 `egov-cicd` namespace 삭제
- Jenkins 초기 admin 비밀번호 즉시 변경
- 공유 Wi-Fi 환경에서 클러스터 기동 지양

## 5. 잔여 위험 (로컬 템플릿 한계)

| 항목 | 상태 | 비고 |
|---|---|---|
| GitLab privileged | **잔존** | 필요 시에만 `INSTALL_GITLAB=true`로 설치 |
| GitLab hostPath | **잔존** | PVC 전환은 GitLab 구조상 복잡, placeholder 경로로 제한 |
| 데모 credential | **잔존** | 로컬 학습용, 운영 배포 금지 |
| NetworkPolicy | **미적용** | 로컬 단독 PC 전제, 운영 전환 시 추가 필요 |

## 6. 운영 환경 전환 시 추가 조치

로컬 템플릿을 운영에 사용할 경우 아래를 **반드시** 추가 적용해야 합니다.

1. CI/CD 도구 관리망·SSO 뒤 배치
2. Jenkins Role을 필요 verb/리소스로 추가 축소 검토
3. GitLab privileged 제거 또는 K8S 외부 GitLab 사용
4. `NetworkPolicy`, `PeerAuthentication` STRICT
5. Secret 관리 체계(Vault, SealedSecret 등) 도입

## 7. F-06 재판정 (변경 후)

| 위험 요소 | 변경 전 | 변경 후 (로컬) |
|---|---|---|
| NodePort 외부 노출 | Critical | **완화** (ClusterIP + port-forward) |
| Jenkins ClusterRole pod/exec | Critical | **완화** (namespace Role, verb 축소) |
| Jenkins Agent NodePort | High | **제거** |
| GitLab privileged + NodePort | Critical | **완화** (기본 미설치, ClusterIP) |
| hostPath 임의 경로 | Medium | **부분 완화** (PVC 전환, placeholder) |

**로컬 단독 PC + CI/CD 선택 설치 + port-forward** 조건에서 F-06 실질 위험도는 **Medium 이하**로 낮출 수 있습니다.

---

관련 문서: `k8s-deploy/README.md`, `k8s-deploy/FAQ.md` (NodePort 개발 환경 권장 사항)
