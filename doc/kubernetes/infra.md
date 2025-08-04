## Infra 구성 및 배포 (RabbitMQ, Gateway)
### 1. RabbitMQ
#### 1) pv 생성
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-pv-nfs.yaml
```
#### 2) configmap 설정
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-configmap.yaml
```

#### 3) raabitmq 배포
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-deployment.yaml
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/rabbitmq-service.yaml
``` 

### 2. GatewayServer
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-infra/gatewayserver-deployment.yaml
```
- MSA_KRDs 서비스에서 제공하는 GatewayServer와 같은 기능으로 서비스 내의 gateway의 기능을 함

 ---
 <div align="center">
    <table>
      <tr>
         <th><a href="db.md">◁ Step5. DB 구성 및 배포</a></th>
         <th>Step6. Infra 구성 및 배포</th>
         <th><a href="app.md">Step7. Application 구성 및 배포 ▷</a></th>
      </tr>
    </table>
 </div>