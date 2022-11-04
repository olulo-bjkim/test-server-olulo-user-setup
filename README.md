# test-server-olulo-user-setup
eb에 의한 생성되는 서버에 관리용 계정(olulo)을 생성하고 설정하기 위한 스크립트 및 설정 파일

## .ebextensions
다음 사항을 .ebextensions에 추가

ex) `.ebextensions/01-set-user-olulo.config` (이 config 이전에 환경변수(/etc/environment)가 먼저 설정되어 있어야 함)

```
users:
  olulo:
    homeDir: "/home/olulo"

commands:
  01-set-olulo-user-shell:
    command: usermod --shell /bin/bash olulo
  02-make-olulo-user-home:
    command: mkhomedir_helper olulo 0077
  03-remove-olulo-user-setup-script:
    test: '[ -f /root/olulo-user-setup.sh ]'
    command: rm /root/olulo-user-setup.sh
  04-get-olulo-user-setup-script:
    test: 'source /etc/environment && [ ! -z "$OLULO_USER_SETUP_GITHUB_URL" ]'
    command: source /etc/environment && curl -s -u "olulo:$OLULO_USER_SETUP_GITHUB_TOKEN" "$OLULO_USER_SETUP_GITHUB_URL/olulo-user-setup.sh" > /root/olulo-user-setup.sh
  05-exec-set-olulo-script:
    test: '[ -f /root/olulo-user-setup.sh ]'
    command: chmod 700 /root/olulo-user-setup.sh && /root/olulo-user-setup.sh
```

- users/olulo 아래에 아무것도 없으면 에러나서 불필요하지만 homeDir를 추가하였음.
- 04-get-olulo-user-setup-script 에서 파일 없을 경우(또는 권한없을 경우) "404: Not Found"란 값이 파일에 저장되는데 05-exec-set-olulo-script 에서 실행시 오류나므로 별도로 체크하지 않고 그냥 둠

## git repository 파일 구조
```
/olulo-user-setup.sh
/eb환경이름/ssh/authorized_keys
/eb환경이름/sudoers.d/10-olulo
```
- `eb환경이름`은 각 eb환경의 이름(ex. kg-dev-env)
- `eb환경이름`디렉토리 아래에 필요한 파일은 olulo-user-setup.sh 파일내용에서도 확인 가능

## 환경변수

- `OLULO_USER_SETUP_GITHUB_URL`
  - https://raw.githubusercontent.com/olulo-bjkim/test-server-olulo-user-setup/master

- `OLULO_USER_SETUP_GITHUB_TOKEN`
  - 옵션 사항으로 리포지토리가 public 일 경우 불필요
  - private 일 경우 이 리포지토리만 read 할 수 있는 토큰 생성해서 사용

## 토큰
- Fine-grained tokens (Beta) 로 발급할 경우 리포지토리를 지정할 수 있어서 좋은 데 expire만 최대 1년으로 주기적인 토큰 교체가 필요함
- Tokens (classic)의 경우 expire 없이 토큰 발급할 순 있지만, 토큰 소유자의 모든 레포지토리에 접근할 수 있어서, 이 방식을 사용하려면, 전용계정을 만들어서 계정에 이 레포지토리만 권한을 줘서 토큰을 만들어야할 것임.

## SSH키

- 키는 4096 비트로 생성하여 사용하길 권장(ssh-keygen 기본값 2048)

  `ssh-keygen -b 4096 -f privatekey_file`와 같이 '-b 4096' 옵션과 함께 키파일 생성

- 키에 대한 암호 사용 권한

  `ssh-keygen -p -f privatekey_file` 로 암호 변경
 
- ssh public-key 생성 명령
 
  `ssh-keygen -y -f privatekey_file`

## authencated_keys
- ssh-rsa public 추가시에 줄 끝에 추가되는 comment 영역에 사용자가 누구인지 명확히(email) 하고 finger print로 함께 포함시켜 놓았으면 함(/var/log/secure 에 ssh로그인시 fingerprint가 남기 때문에 확인이 필요할 경우 쉽게 확인하기 위해)
  ```
  ssh-rsa AAAAB.....TFw== bjkim@olulo.io SHA256:hZlY7.....FAQ9A
  ```

- fingerprint 확인

  `ssh-keygen -l -f ssh-public-key-file`
