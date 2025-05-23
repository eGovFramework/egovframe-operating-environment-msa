# 전자정부 표준프레임워크 MSA 공통컴포넌트 Kubernetes 수동 배포 스크립트

> 각 명령어는 **순서대로** 실행해야 합니다.  
> 각 단계에서 오류가 발생하면 다음 단계로 진행하기 전에 해결해야 합니다.  
> `kubectl wait` 명령어는 리소스가 준비될 때까지 대기합니다.  
> 실제 환경에 따라 일부 경로나 설정을 조정해야 할 수 있습니다.

## 1. 사전 설정

### Host 에 Vagrant로 3개 노드로 쿠버네티스 클러스터 구성할 경우

3개의 VM (Control Plane, Worker1, Worker2) 으로 구성된다고 가정한다.
Control Plane CPU 2개, 메모리 6GB
Worker1 CPU 3개, 메모리 14GB
Worker2 CPU 2개, 메모리 6GB

호스트로 접속하여 vagrant 프로젝트를 확인한다.

```bash
ssh msadev2@192.168.100.116
# 프롬프트가 나타나면 msadev3 계정의 정확한 비밀번호를 입력 password1!

cd vagrant_restore

# 현재 Vagrant 가상 머신들의 상태 확인 (실행 중, 중지됨 등)
vagrant status
# 모든 Vagrant 가상 머신을 정상적으로 종료 (전원 끄기)
vagrant halt
# 모든 Vagrant 가상 머신을 시작 (전원 켜기)
vagrant up

vagrant ssh control-plane1 # 컨트롤 플레인 노드 VM에 SSH 접속
vagrant ssh worker1 # 첫 번째 워커 노드 VM에 SSH 접속
vagrant ssh worker2 # 두 번째 워커 노드 VM에 SSH 접속

```

호스트로 접속하여 git 프로젝트를 클론 후 빌드한다.

```bash
ssh msadev2@192.168.100.116
# 프롬프트가 나타나면 msadev3 계정의 정확한 비밀번호를 입력 password1!

git clone https://github.com/chris-yoon/egovframe-common-components-msa-krds.git
cd egovframe-common-components-msa-krds

# Java 17 설치
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk maven git

# Java 17을 기본 버전으로 설정
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
sudo update-alternatives --set javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac
java -version
mvn -version

# 소유권 및 권한 설정
sudo chown -R vagrant:vagrant /home/msadev2/egovframe-common-components-msa-krds
sudo chmod -R 755 /home/msadev2/egovframe-common-components-msa-krds

./build.sh # 프로젝트 빌드
./docker-build.sh -k # k8s 태그로 이미지 빌드

# OpenSearch 이미지(Nori 플러그인 포함) 빌드
cd /{프로젝트 경로}/EgovSearch/docker-compose/Opensearch
docker build -t opensearch-with-nori:2.15.0 .

```

### NFS 서버 설치 및 설정

Control-plane1에서 진행한다.

```bash
vagrant ssh control-plane1

# NFS 서버 설치
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

# NFS 데이터 디렉토리 생성
sudo mkdir -p /srv/nfs/data
sudo mkdir -p /srv/nfs/data/{jenkins,nexus,mysql,sonarqube,opensearch,rabbitmq,gitlab,postgresql,redis,prometheus,egov-mobileid/config,egov-search/{cacerts,example,model,config}}

# 모든 데이터 디렉토리에 대한 권한 설정
sudo chmod -R 777 /srv/nfs/data
sudo chown -R nobody:nogroup /srv/nfs/data

# NFS 서버 시작
sudo /etc/init.d/nfs-kernel-server start
```

EgovSearch 와 EgovMobileId 설정 파일 복사 (나의 로컬 파일 -> 호스트)

```bash
# EgovSearch-config 디렉토리 전체를 한 번에 복사
scp -r ~/Projects/egovframe/egovframe-common-components-msa-krds/EgovSearch-config msadev2@192.168.100.116:~/egovframe-common-components-msa-krds/

scp -r ~/Projects/egovframe/egovframe-common-components-msa-krds/EgovMobileId/config msadev2@192.168.100.116:~/egovframe-common-components-msa-krds/
```

호스트 -> Control-plane1

```bash
# 로컬에서 tar로 압축 후 vagrant scp로 전송하고 원격에서 압축 해제
cd ~/egovframe-common-components-msa-krds
tar -czf EgovSearch-config.tar.gz EgovSearch-config
cd ~/vagrant_restore
vagrant scp ~/egovframe-common-components-msa-krds/EgovSearch-config.tar.gz control-plane1:/tmp/
vagrant ssh control-plane1 -c "sudo tar -xzf /tmp/EgovSearch-config.tar.gz -C /tmp/ && sudo cp -r /tmp/EgovSearch-config/config/* /srv/nfs/data/egov-search/config/ && sudo cp -r /tmp/EgovSearch-config/model/* /srv/nfs/data/egov-search/model/ && sudo cp -r /tmp/EgovSearch-config/example/* /srv/nfs/data/egov-search/example/ && sudo cp -r /tmp/EgovSearch-config/cacerts/* /srv/nfs/data/egov-search/cacerts/ && sudo rm -rf /tmp/EgovSearch-config*"

# EgovMobileId 설정 파일 전송 (tar 방식)
cd ~/egovframe-common-components-msa-krds
tar -czf EgovMobileId-config.tar.gz EgovMobileId/config
cd ~/vagrant_restore
vagrant scp ~/egovframe-common-components-msa-krds/EgovMobileId-config.tar.gz control-plane1:/tmp/
vagrant ssh control-plane1 -c "sudo tar -xzf /tmp/EgovMobileId-config.tar.gz -C /tmp/ && sudo cp -r /tmp/EgovMobileId/config/* /srv/nfs/data/egov-mobileid/config/ && sudo rm -rf /tmp/EgovMobileId* /tmp/EgovMobileId-config.tar.gz"
```


### PV 및 PVC 파일 수정

각 PV 및 PVC 파일을 수정하여 NFS를 사용하도록 설정합니다. (호스트에서 작업)

```bash
# PV 및 PVC 파일 수정
cd /{프로젝트 경로}/k8s-deploy/manifests
# 다음 PV, PVC 파일에서 nfs 서버 주소, path를 확인/수정한다.
egov-monitoring/prometheus-pv.yaml
egov-db/mysql-pv.yaml
egov-db/opensearch-pv.yaml
egov-db/postgresql-pv.yaml
egov-db/redis-pv.yaml
egov-infra/rabbitmq-pv.yaml
egov-app/egov-mobileid-pv.yaml
egov-app/egov-search-pv.yaml

# 다음 파일에서 persistentVolumeClaim 명을 확인/수정한다.
egov-monitoring/prometheus.yaml
egov-db/mysql.yaml
egov-db/opensearch.yaml
egov-db/postgresql.yaml
egov-db/redis.yaml
egov-infra/rabbitmq-deployment.yaml
egov-app/egov-mobileid-deployment.yaml
egov-app/egov-search-deployment.yaml
```

### 도커 이미지 복사

빌드된 도커 이미지를 호스트의 vagrant 프로젝트 폴더로 저장한 후, 각 노드로 복사한다.
각 노드에서 `ctr` 명령어를 사용하여 이미지를 로드한다.

```bash
# 호스트에서 실행
# 루트 전용 폴더에 저장
docker save egovcommonall:k8s -o /home/msadev2/vagrant_restore/egovcommonall.tar
docker save egovhello:k8s -o /home/msadev2/vagrant_restore/egovhello.tar
docker save gatewayserver:k8s -o /home/msadev2/vagrant_restore/gatewayserver.tar
docker save egovmain:k8s -o /home/msadev2/vagrant_restore/egovmain.tar
docker save egovboard:k8s -o /home/msadev2/vagrant_restore/egovboard.tar
docker save egovlogin:k8s -o /home/msadev2/vagrant_restore/egovlogin.tar
docker save egovauthor:k8s -o /home/msadev2/vagrant_restore/egovauthor.tar
docker save egovmobileid:k8s -o /home/msadev2/vagrant_restore/egovmobileid.tar
docker save egovquestionnaire:k8s -o /home/msadev2/vagrant_restore/egovquestionnaire.tar
docker save egovcmmncode:k8s -o /home/msadev2/vagrant_restore/egovcmmncode.tar
docker save egovsearch:k8s -o /home/msadev2/vagrant_restore/egovsearch.tar
docker save opensearch-with-nori:2.15.0 -o /home/msadev2/vagrant_restore/opensearch-with-nori.tar

# 호스트 머신 vagrant 프로젝트에서 worker1 에 복사
cd ~/vagrant_restore
vagrant scp ./egovcommonall.tar worker1:/home/vagrant/
vagrant scp ./egovhello.tar worker1:/home/vagrant/
vagrant scp ./gatewayserver.tar worker1:/home/vagrant/
vagrant scp ./egovmain.tar worker1:/home/vagrant/
vagrant scp ./egovboard.tar worker1:/home/vagrant/
vagrant scp ./egovlogin.tar worker1:/home/vagrant/
vagrant scp ./egovauthor.tar worker1:/home/vagrant/
vagrant scp ./egovmobileid.tar worker1:/home/vagrant/
vagrant scp ./egovquestionnaire.tar worker1:/home/vagrant/
vagrant scp ./egovcmmncode.tar worker1:/home/vagrant/
vagrant scp ./egovsearch.tar worker1:/home/vagrant/
vagrant scp ./opensearch-with-nori.tar worker1:/home/vagrant/

# 호스트 머신 vagrant 프로젝트에서 worker2 에 복사
vagrant scp ./egovcommonall.tar worker2:/home/vagrant/
vagrant scp ./egovhello.tar worker2:/home/vagrant/
vagrant scp ./gatewayserver.tar worker2:/home/vagrant/
vagrant scp ./egovmain.tar worker2:/home/vagrant/
vagrant scp ./egovboard.tar worker2:/home/vagrant/
vagrant scp ./egovlogin.tar worker2:/home/vagrant/
vagrant scp ./egovauthor.tar worker2:/home/vagrant/
vagrant scp ./egovmobileid.tar worker2:/home/vagrant/
vagrant scp ./egovquestionnaire.tar worker2:/home/vagrant/
vagrant scp ./egovcmmncode.tar worker2:/home/vagrant/
vagrant scp ./egovsearch.tar worker2:/home/vagrant/
vagrant scp ./opensearch-with-nori.tar worker2:/home/vagrant/

# vagrant-scp 플러그인이 설치되어 있어야 한다.
vagrant plugin install vagrant-scp

# worker1, worker2 에서 로드
vagrant ssh worker1
vagrant ssh worker2

# 1. containerd CLI로 이미지 import
sudo ctr -n k8s.io images import /home/vagrant/egovcommonall.tar
sudo ctr -n k8s.io images import /home/vagrant/egovhello.tar
sudo ctr -n k8s.io images import /home/vagrant/gatewayserver.tar
sudo ctr -n k8s.io images import /home/vagrant/egovmain.tar
sudo ctr -n k8s.io images import /home/vagrant/egovboard.tar
sudo ctr -n k8s.io images import /home/vagrant/egovlogin.tar
sudo ctr -n k8s.io images import /home/vagrant/egovauthor.tar
sudo ctr -n k8s.io images import /home/vagrant/egovmobileid.tar
sudo ctr -n k8s.io images import /home/vagrant/egovquestionnaire.tar
sudo ctr -n k8s.io images import /home/vagrant/egovcmmncode.tar
sudo ctr -n k8s.io images import /home/vagrant/egovsearch.tar
sudo ctr -n k8s.io images import /home/vagrant/opensearch-with-nori.tar

# 2. 확인
sudo ctr -n k8s.io images ls | grep egovcommonall
```

### control-plane 노드에 "일반 Pod 금지" Taint를 적용함

```bash
# 일반적으로 생성되는 Pod는 이 노드(control-plane1)에 스케줄되지 않는다.
kubectl describe node control-plane1 | grep Taint
Taints:             node-role.kubernetes.io/control-plane:NoSchedule

# 위와 같지 않다면 다음 명령을 실행하여 "일반 Pod 금지" Taint를 적용한다.
kubectl taint nodes control-plane1 node-role.kubernetes.io/control-plane=:NoSchedule
```

### 포트 포워드 

Vagrantfile 을 다음과 같이 수정하여 나의 로컬에서도 서비스에 접근할 수 있다.

```vagrant
# Vagrantfile
config.vm.network "forwarded_port", guest: 30001, host: 30001, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30002, host: 30002, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30003, host: 30003, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30004, host: 30004, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30561, host: 30561, protocol: "tcp"
config.vm.network "forwarded_port", guest: 31672, host: 31672, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30090, host: 9000, protocol: "tcp"
config.vm.network "forwarded_port", guest: 32314, host: 32314, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30992, host: 30992, protocol: "tcp"
config.vm.network "forwarded_port", guest: 9093, host: 9039, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30011, host: 30011, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30013, host: 30013, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30014, host: 30014, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30012, host: 30012, protocol: "tcp"
config.vm.network "forwarded_port", guest: 32080, host: 32080, protocol: "tcp"
config.vm.network "forwarded_port", guest: 30306, host: 30306, protocol: "tcp"
```

## 2. Istio 설치

```bash
cd /{프로젝트 경로}/k8s-deploy/bin

# 결과가 x86_64 나오면 Intel/AMD 64 비트 CPU (일반 PC/서버)
uname -m
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.0 sh -

# 그 외엔 ARM CPU
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.0 TARGET_ARCH=arm64 sh -

cd istio-1.25.0
export PATH=$PWD/bin:$PATH
istioctl install --set profile=default -y
kubectl create namespace egov-app
kubectl label namespace egov-app istio-injection=enabled
kubectl apply -f ../../manifests/egov-istio/config.yaml
kubectl apply -f ../../manifests/egov-istio/telemetry.yaml
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s
```

## 3. 전역 설정 및 네임스페이스 생성

```bash
# 전역 ConfigMap 생성 (hostPath 경로)
kubectl apply -f ../../manifests/common/egov-global-configmap.yaml

# 네임스페이스 생성
kubectl create namespace egov-monitoring
kubectl create namespace egov-db
kubectl create namespace egov-infra
kubectl label namespace egov-infra istio-injection=enabled
kubectl create namespace egov-cicd

# ConfigMap 상태 확인
kubectl get configmap egov-global-config
kubectl get configmap egov-common-config

# ConfigMap에서 값 추출해서 환경 변수로 설정
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')

# 공통적으로 사용할 ConfigMap 생성
kubectl apply -f ../../manifests/common/egov-common-configmap.yaml -n egov-app
kubectl apply -f ../../manifests/common/egov-common-configmap.yaml -n egov-infra
```

## 4. 모니터링 설치

### cert-manager 설치
```bash
# 기존 cert-manager 설치 제거
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml --ignore-not-found
sleep 30

# cert-manager webhook configuration 임시 비활성화
kubectl delete validatingwebhookconfiguration cert-manager-webhook --ignore-not-found
kubectl delete mutatingwebhookconfiguration cert-manager-webhook --ignore-not-found
sleep 10

# cert-manager 재설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# cert-manager pods가 완전히 준비될 때까지 대기
kubectl wait --for=condition=Ready pods -l app=cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pods -l app=cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pods -l app=webhook -n cert-manager --timeout=300s
# 또는
kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=300s

# webhook이 완전히 준비될 때까지 추가 대기
sleep 90
```

### OpenTelemetry Operator 설치
```bash
# 기존 OpenTelemetry Operator 제거
kubectl delete -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml --ignore-not-found
sleep 30

# OpenTelemetry Operator 재설치
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.120.0/opentelemetry-operator.yaml

# OpenTelemetry Operator가 준비될 때까지 대기
kubectl wait --for=condition=Ready pods -l control-plane=controller-manager -n opentelemetry-operator-system --timeout=300s
```

### 모니터링 컴포넌트 설치
```bash
cd ../../manifests/egov-monitoring
kubectl apply -f alertmanager-config.yaml
kubectl apply -f circuit-breaker-alerts-configmap.yaml
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
kubectl apply -f kiali.yaml
kubectl apply -f jaeger.yaml
kubectl apply -f loki.yaml
kubectl apply -f alertmanager.yaml
kubectl apply -f opentelemetry-collector.yaml
kubectl wait --for=condition=Ready pods --all -n egov-monitoring --timeout=300s
```

## 5. MySQL 설치

```bash
cd ../egov-db
kubectl apply -f mysql-pv.yaml
kubectl apply -f mysql.yaml
kubectl rollout status statefulset/mysql -n egov-db --timeout=600s
```

## 6. OpenSearch 설치

```bash
kubectl apply -f opensearch-pv.yaml
kubectl apply -f opensearch.yaml
kubectl apply -f opensearch-dashboard.yaml
kubectl rollout status statefulset/opensearch -n egov-db --timeout=300s
kubectl rollout status deployment/opensearch-dashboards -n egov-db --timeout=300s
```

## 7. 인프라 서비스 설치

```bash
cd ../egov-infra
kubectl apply -f rabbitmq-configmap.yaml
kubectl apply -f rabbitmq-pv.yaml
kubectl apply -f rabbitmq-deployment.yaml
kubectl apply -f rabbitmq-service.yaml
kubectl rollout status deployment/rabbitmq -n egov-infra --timeout=300s
kubectl apply -f gatewayserver-deployment.yaml
kubectl rollout status deployment/gateway-server -n egov-infra --timeout=300s
```

## 8. 애플리케이션 서비스 설치

### MySQL Secret 복사 (egov-db -> egov-app)
```bash
cd ../egov-app
kubectl get secret mysql-secret -n egov-db -o yaml | sed 's/namespace: egov-db/namespace: egov-app/' | kubectl apply -f -
```

### PV 및 PVC 생성
```bash
kubectl apply -f egov-mobileid-pv.yaml
kubectl apply -f egov-search-pv.yaml
```

### 각 서비스 배포
```bash
kubectl apply -f egov-hello-deployment.yaml
kubectl apply -f egov-main-deployment.yaml
kubectl apply -f egov-board-deployment.yaml
kubectl apply -f egov-login-deployment.yaml
kubectl apply -f egov-author-deployment.yaml
kubectl apply -f egov-mobileid-deployment.yaml
kubectl apply -f egov-questionnaire-deployment.yaml
kubectl apply -f egov-cmmncode-deployment.yaml
kubectl apply -f egov-search-deployment.yaml
```

### 각 노드 메모리 CPU 확인

```bash
kubectl top node
kubectl top node worker1
kubectl top node worker2

# 노드 상태 확인
kubectl get nodes
```

## 9. CICD 설치

```bash
cd ../egov-cicd
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
envsubst '${DATA_BASE_PATH}' < jenkins-statefulset.yaml | kubectl apply -f -
envsubst '${DATA_BASE_PATH}' < sonarqube-deployment.yaml | kubectl apply -f -
envsubst '${DATA_BASE_PATH}' < nexus-statefulset.yaml | kubectl apply -f -
kubectl rollout status statefulset/jenkins -n egov-cicd --timeout=300s
```

## 10. PostgreSQL, Redis, GitLab 설치

```bash
cd ../egov-db
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
envsubst '${DATA_BASE_PATH}' < postgresql.yaml | kubectl apply -f -
envsubst '${DATA_BASE_PATH}' < redis.yaml | kubectl apply -f -
kubectl rollout status statefulset/postgresql -n egov-db --timeout=300s
kubectl rollout status statefulset/redis -n egov-db --timeout=300s

cd ../egov-cicd
export DATA_BASE_PATH=$(kubectl get configmap egov-global-config -o jsonpath='{.data.data_base_path}')
envsubst '${DATA_BASE_PATH}' < gitlab-statefulset.yaml | kubectl apply -f -
```

## 설치 상태 확인

```bash
kubectl get pods --all-namespaces
```

## 접근 정보 확인

```bash
cd ../../scripts/setup
./09-show-access-info.sh
```
