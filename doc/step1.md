# 환경설정

## 운영체제
  - Linux (Ubuntu 20.04 LTS 이상 권장)
  - macOS 12 이상
  - Windows 10/11 Pro 이상

## 소프트웨어
  - Docker Engine 24.0.0 이상
  - Docker Compose v2.20.0 이상
  - Java Development Kit (JDK) 17 이상
  - Git 2.34.1 이상

## 네트워크
  - 컨테이너 이미지 다운로드를 위해 인터넷 사용 필요
  - 다음 포트들이 사용 가능해야 함:   
    | 포트  | 서비스|
    | --- | --- |
    | 8761 | Eureka Server |
    | 8888 | Config Server |
    | 9000 | API Gateway |
    | 9200, 9600 | OpenSearch |
    | 5601 | OpenSearch Dashboards |
    | 3306 | MySQL |
    | 5672 | RabbitMQ |
    | 8081 | EgovAuthor |
    | 8082 | EgovBoard |
    | 8083 | EgovCmmnCode |
    | 8084 | EgovLogin |
    | 8085 | EgovLoginPolicy |
    | 8086 | EgovMain |
    | 8087 | EgovMobileId |
    | 8088 | EgovQuestionnaire |
    | 9992 | EgovSearch |

## Docker Desktop 설치

### Window
- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop) 다운로드
- WSL 설치 (PowerShell 관리자권한 실행)
    ```bash
    wsl --install
    ```
### Mac
- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop) 다운로드
- homebrew를 통한 설치
    ```bash
    brew install --cask docker
    ```

### Linux
```bash
# 이전 버전 제거
sudo apt-get remove docker docker-engine docker.io containerd runc

# 필요한 패키지 설치
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker 공식 GPG 키 추가
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker 리포지토리 설정
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 엔진 설치
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 docker 그룹에 추가 (sudo 없이 실행)
sudo usermod -aG docker $USER

# Docker Compose 플러그인 설치
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

---

<div align="center">
   <table>
     <tr>
       <th>Step1. 환경설정</th>
       <th><a href="step2.md">Step2. 프로젝트 준비 ▷</a></th>
     </tr>
   </table>
</div>
