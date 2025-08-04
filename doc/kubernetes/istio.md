## Istio / Telemetry 구성
### 1) Istio 설치

- Kubernetes-Istio 호환 버전 확인
    ![istio_version](/images/istio_version.png)

- Kubernetes에서 지원되는 버전을 사용해야함
    - 프로젝트의 버전 구성
        - Kubernetes : 1.32.5
        - Istio Version : 1.25.0
- namespace 생성
    ```bash
    kubectl create namespace istio-system
    ```
- Istio 바이너리(istioctl 등) 도구 설치
    ```bash
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.0 TARGET_ARCH=amd64 sh -
    ```
    - TARGET_ARCH
        - MAC/Linux인 경우 : arm64
        - Window인 경우 : amd64
    - 버전 지정하지 않는 경우 최신 버전 다운로드됨
- istio 설치 : 
    `istioctl install --set profile=default -y `
- 설치 확인 : `istioctl version`

### 2) Istio 구성
1. configMap 배포
    ```bash
    kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-istio/config.yaml
    ```

2. Isito Injection 레이블 추가
    ```bash
    kubectl label namespace egov-app istio-injection=enabled --overwrite
    ```

3. 필요한 네임스페이스에 사이드카 주입 활성화
    ```bash
    kubectl label namespace egov-infra istio-injection=enabled --overwrite
    ```
4. Telemetry 설정 적용
    ```bash
    kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-istio/telemetry.yaml
    ```

---
<div align="center">
   <table>
     <tr>
        <th><a href="namespace.md">◁ Step1. Namespace 생성</a></th>
        <th>Step2. Istio 배포</th>
        <th><a href="nfs.md">Step3. NFS Provisioner 배포 ▷</a></th>
     </tr>
   </table>
</div>