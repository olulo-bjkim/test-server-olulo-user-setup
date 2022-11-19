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
    test: 'source /etc/environment && [ ! -z "$S3_OLULO_USER_SETUP_PATH" ]'
    command: source /etc/environment && aws s3 cp $S3_OLULO_USER_SETUP_PATH/olulo-user-setup.sh /root/olulo-user-setup.sh
  05-exec-set-olulo-script:
    test: '[ -f /root/olulo-user-setup.sh ]'
    command: chmod 700 /root/olulo-user-setup.sh && /root/olulo-user-setup.sh
```

- users/olulo 아래에 아무것도 없으면 에러나서 불필요하지만 homeDir를 추가하였음.

## git repository 파일 구조
```
/src/olulo-user-setup.sh
/src/eb환경이름/ssh/authorized_keys
/src/eb환경이름/sudoers.d/10-olulo
```
- `eb환경이름`은 각 eb환경의 이름(ex. kg-dev-env)
- `eb환경이름`디렉토리 아래에 필요한 파일은 olulo-user-setup.sh 파일내용에서도 확인 가능

## 환경변수

- 이 repository의 Settings - Secrets - Actions에 다음 환경변수 추가(Settings - Environments를 설정가능하면 upload란 이름의 환경에 설정)
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - S3_OLULO_USER_SETUP_PATH

- S3로의 upload는 .github action을 통해 upload (on:release?)

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
