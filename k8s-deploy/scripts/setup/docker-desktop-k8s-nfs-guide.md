## Docker Desktop Kubernetes NFS 가이드
- Docker Desktop 의 Kubernetes 에서 NFS(Network File System) 를 사용하는 방법을 기술한다.
- /sbin/nfsd 에 명령어 위치가 있으며 macOS 기본 포함된다.
- 로컬 디렉토리를 NFS 를 통해 다른 머신 또는 컨테이너에 공유된다.
- `/ect/exports` 설정 후 `nfsd restart` 명령으로 반영한다.
- macOS Ventura 이상에서는 앱이 특정 경로에 접근하려면 **시스템 설정 > 개인정보 보호 및 보안 > 파일 및 폴더**에서 **터미널의 "전체 디스크 접근"** 권한을 허용해야 할 수도 있다.
### 확인
```bash
# 확인 방법
which nfsd
/sbin/nfsd # 출력 예
```
### 명령어
```bash
sudo nfsd start # NFS 데몬 시작
sudo nfsd stop  # NFS 데몬 중지
sudo nfsd restart
sudo nfsd status

# /etc/exports 파일 문법 및 유효성 검사
sudo nfsd checkexports
```
### 공유할 로컬 디렉토리 생성
```bash
mkdir -p ~/nfs-share
chmod -R 777 ~/nfs-share # 테스트용으로 전체 권한 부여

# NFS 데이터 디렉토리 생성
sudo mkdir -p ~/nfs-share/data
sudo mkdir -p ~/nfs-share/data/{jenkins,nexus,mysql,sonarqube,opensearch,rabbitmq,gitlab,postgresql,redis,prometheus,egov-mobileid/config,egov-search/{cacerts,example,model,config}}

# 모든 데이터 디렉토리에 대한 권한 설정
sudo chmod -R 777 ~/nfs-share/data
sudo chown -R nobody:nogroup ~/nfs-share/data
```
### 설정 파일 수정
```bash
sudo touch /etc/exports

sudo vi /etc/exports

/Users/chrisyoon/nfs-share/data/egov-mobileid/config -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/egov-search/config -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/egov-search/model -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/egov-search/example -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/egov-search/cacerts -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/rabbitmq -mapall=root -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/mysql -mapall=root -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/opensearch -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/prometheus -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0

/Users/chrisyoon/nfs-share/data/postgresql -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/gitlab -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/jenkins -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/nexus -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/redis -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0
/Users/chrisyoon/nfs-share/data/sonarqube -mapall=501:20 -network 192.168.64.0 -mask 255.255.255.0

# 501:20은 보통 macOS에서 첫 사용자 UID:GID이다. id 명령어로 본인 UID 확인 가능:
id -u # UID
id -g # GID
```
### NFS 서비스 재시작
```bash
# 데몬 재시작
sudo nfsd restart

# 문법 확인: 정상이라면 아무 출력 없이 끝난다.
sudo nfsd checkexports

# NFS 데몬 상태 확인
nfsd status
```
### Docker Desktop VM이 접근 가능한지 확인
```bash
# VM 내부로 접근
kubectl run test-nfs --rm -i -t --image=busybox --privileged -- /bin/sh

ping 192.168.64.1
mkdir -p /mnt

# 컨테이너에서 NFS 서버 접근 테스트 -> 정상 작동하면 /mnt 에서 파일을 읽고 쓸 수 있어야 한다.
mount -o nolock 192.168.64.1:/Users/chrisyoon/nfs-share/data/mysql /mnt
```
### PV, PVC 등록
- persistentVolumeReclaimPolicy와 storageClassName를 지정해 준다.
- PV는 `standard`라는 StorageClass에 속한다고 선언되어 있다. PVC가 `standard`를 지정하면 이 PV를 바인딩할 수 있다.
```yaml
# Config PV/PVC - NFS
apiVersion: v1
kind: PersistentVolume
metadata:
  name: egov-search-config-pv-nfs
  namespace: egov-app
spec:
  capacity:
    storage: 1Mi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  nfs:
    server: 192.168.64.1
    path: "/Users/chrisyoon/nfs-share/data/egov-search/config"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: egov-search-config-pvc-nfs
  namespace: egov-app
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
  volumeName: egov-search-config-pv-nfs
  storageClassName: standard

```
### 볼륨 권한
- `securityContext`로 보륨 권한을 간접적으로 제어한다.
- UID (User ID) : 시스템 내에서 각 사용자에게 부여되는 고유 번호
- GID (Group ID) : 각 그룹에 부여되는 고유 번호
- MySQL 은 0 (root), RabbitMQ 는 999, Postgresql 는 501
	- 0 : root (최고 권한 사용자)
	- 1-99 : 시스템 예약 (데몬, 커널용 등)
	- 100-999 : 시스템 서비스 계정 (데몬, DB, 메시지큐 등)
		- UID 501: macOS의 일반 사용자
		- UID 999: 컨테이너 전용 non-root 사용자에게 할당되는 번호이다.
```bash
$ id chrisyoon
uid=501(chrisyoon) gid=20(staff)

docker run -it --rm rabbitmq:3-management id
uid=0(root) gid=0(root) groups=0(root)

docker run -it --rm postgres:15.4 id
uid=0(root) gid=0(root) groups=0(root)
```
#### MySQL StatefulSet
- `fsGroup: 0` 과 `runAsUser: 0`로 할당해도 되지만 컨테이너 전용 `999`를 사용한다.
- NFS 설정파일 `/etc/exports` 에  root 설정
	- `/Users/chrisyoon/nfs-share/data/mysql -mapall=root -network 192.168.64.0 -mask 255.255.255.0`
```yaml
    spec:
      # MySQL 컨테이너에 루트 권한 부여
      securityContext:
        fsGroup: 999
        runAsUser: 999
        runAsGroup: 999
      containers:
      - name: mysql
        image: mysql:8.0-oracle
```
#### RabbitMQ Deployment
- Kubernetes에서 `runAsUser: 999`로 설정하면:
	- 컨테이너 전체를 `rabbitmq` 사용자로 실행
	- 보안상 root 권한 없이도 운영 가능
	- NFS, PVC 등의 **볼륨 권한 충돌도 방지**
- 이는 보안 강화를 위해 **컨테이너 전체를 비-root 사용자로 실행**하려는 목적
- NFS 설정파일 `/etc/exports` 에  root 설정
	- `/Users/chrisyoon/nfs-share/data/rabbitmq -mapall=root -network 192.168.64.0 -mask 255.255.255.0`
```yaml
    spec:
      # 컨테이너를 rabbitmq 사용자(UID 999)로 실행
      securityContext:
        fsGroup: 999
        runAsUser: 999
        runAsGroup: 999
      containers:
      - name: rabbitmq
        image: rabbitmq:3-management
```
#### Postgresql StatefulSet
- `runAsUser: 501`, `fsGroup: 20` 설정이 가장 안정적이고 권한 문제가 없는 방법이다.
```yaml
    spec:
      securityContext:
        runAsUser: 501   # 컨테이너 프로세스를 chrisyoon UID로 실행
        runAsGroup: 20   # 컨테이너 프로세스를 staff 그룹(GID 20)으로 실행
        fsGroup: 20      # 마운트된 볼륨의 그룹 소유자를 20으로 설정 → 그룹 쓰기 가능
      containers:
      - name: postgresql
        image: postgres:15.4
```
