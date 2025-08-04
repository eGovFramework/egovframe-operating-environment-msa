## Application 구성 및 배포
### 1. Mysql Secret 복사
```bash
kubectl get secret mysql-secret -n egov-db -o yaml | sed 's/namespace: egov-db/namespace: egov-app/' | kubectl apply -f -
```

### 2. FileUpload pv 생성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-fileupload-pvc-nfs.yaml
```

### 3. Appliation 서비스 배포
```bash
#메인 레이아웃
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-main-deployment.yaml
#게시판 (egov-board)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-board-deployment.yaml
#로그인 (egov-login)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-login-deployment.yaml
#로그인 정책 (loginPolicy)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-loginpolicy-deployment.yaml
#권한 (egov-author)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-author-deployment.yaml
#설문 (egov-questionnaire)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-questionnaire-deployment.yaml
#공통코드 (egov-cmmncode)
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-app/egov-cmmncode-deployment.yaml
```
#### 4) EgovSearch
*EgovSearch를 사용하는 경우 서버구성 등에 관련된 사항은 [EgovSearch 가이드](https://github.com/eGovFramework/egovframe-common-components-msa-krds/blob/main/EgovSearch/README.md) 를 참조하시기 바랍니다.

#### 5) EgovMobileId

*EgovMobileId 사용하는 경우 서버구성 등에 관련된 사항은 [EgovMobileId 가이드](https://github.com/eGovFramework/egovframe-common-components-msa-krds/blob/main/EgovMobileId/README.md) 를 참조하시기 바랍니다.

### 9. 실행 확인

| 서비스 | 포트 |기타|
|---|---|---|
|EgovSearch Swagger UI|30992|swagger-ui.html|
|EgovMain|9000|main|
|Kiali|30001|
|Grafana|30002|
|Jaeger|30003|


#### 1) MSA 서비스
![main_layout](/images/main.png)
- http://xxx.xxx.xxx.xx:9000
- 로그인 계정
    - 일반 계정 : USER/rhdxhd12
    - 업무 계정: TEST1/rhdxhd12

#### 2) Swagger 서비스
![swagger](/images/swagger.png)
ex) http://xxx.xxx.xxx.xxx:30992/swagger-ui.html
   - egov-search의 swagger 서비스 : [OpenSearch 관련 API 설명](https://github.com/eGovFramework/egovframe-common-components-msa-krds/tree/main/EgovSearch#open-search-%EA%B4%80%EB%A0%A8-api-%EC%84%A4%EB%AA%85) 

#### 3) 모니터링 서비스
1. Kiali
![kiali](/images/kiali.png)
   - Service Mesh
   - 서비스간 연결관계 및 트래픽 상태 등을 확인할 수 있다.

2. grafana
   - http://xxx.xxx.xxx.xx:30002
   - metric
      ![grafana_metric](/images/grafana-metric.png)
   - log
      ![grafana-logs](/images/grafana-logs.png)

3. jaeger
![jaeger](/images/jaeger.png)
   - http://xxx.xxx.xxx.xx:30003

#### 4) [파일업로드 테스트](/service_test.md)
 ---
 <div align="center">
    <table>
      <tr>
         <th><a href="db.md">◁ Step6. Infra 구성 및 배포</a></th>
         <th>Step7. Application 구성 및 배포</th>
      </tr>
    </table>
 </div>