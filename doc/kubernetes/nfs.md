## NFS Provisioner

### 1. nfs 설치
#### 1) NFS 서버 설치
```bash
sudo apt-get update
sudo apt install nfs-kernel-server
```

#### 2) 공유폴더 생성
```bash
# 1. 폴더 생성
sudo mkdir -p /srv/nfs

# 2. 권한 부여
sudo chown nobody:nogroup /srv/nfs
sudo chown -R nobody:nogroup /srv/nfs
sudo chmod 777 -R /srv/nfs

# 3. /etc/exports 파일 편집
sudo nano /etc/exports

# 4. /etc/exports에 다음 라인 추가:
/srv/nfs *(rw,sync,no_subtree_check,no_root_squash,insecure)

# 5. NFS 서비스 재시작
sudo systemctl restart nfs-server

# 6. export 다시 내보내기
sudo exportfs -ra
```

- Multi Node 환경인 경우 control-plane에 nfs 서버 설치
- vagrant 설치 확인
    - control-plane 진입 : `vagrnat ssh control-plane명`
        ```
        ~/vagrant_restore$ vagrant ssh control-plane1
        ```
    - nfs 폴더로 이동 : `cd /srv/nfs`
        ```
        vagrant@control-plane1:~$ ll /srv
        total 12
        drwxr-xr-x  3 root   root    4096 Jun 22 08:32 ./
        drwxr-xr-x 19 root   root    4096 Jul 30 06:48 ../
        drwxrwxrwx 10 nobody nogroup 4096 Jul 30 06:41 nfs/
        ```


### 2. nfs 배포

#### 1) nfs 설정
```bash
#Service Account
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-storage/nfs-sa.yaml

#Storage Class
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-storage/nfs-sc.yaml
```

#### 2) nfs 배포
```bash
kubectl apply -f ~/egovframe-operating-environment-msa/k8s-deploy/manifests/egov-storage/nfs-deployment.yaml
```
---
> NFS용 서버를 다른 IP에 구축한 경우   
- `k8s-deploy/manifests/egov-storage/nfs-deployment.yaml` 수정   
    ```
            env:
            - name: PROVISIONER_NAME
                value: nfs-provisioner
            - name: NFS_SERVER
                value: 192.168.56.21
            - name: NFS_PATH
                value: /srv/nfs
            volumeMounts:
            - name: nfs-volume
                mountPath: /persistentvolumes
        volumes:
        - name: nfs-volume
            nfs:
            server: 192.168.56.21
            path: /srv/nfs
    ```
    - `192.168.56.21`은 가상머신에 할당된 개인 네트워크 IP로 실제 환경에 맞는 IP로 수정 필요

---
<div align="center">
   <table>
     <tr>
        <th><a href="istio.md">◁ Step2. Istio 배포</a></th>
        <th>Step3. NFS Provisioner 배포</th>
        <th><a href="monitoring.md">Step4. 모니터링 도구 배포 ▷</a></th>
     </tr>
   </table>
</div>