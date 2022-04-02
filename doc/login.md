# Login

ログインシステム

```text
ログインを通過したときに発行されるsidの値が必要
httpリクエストの場合Cookieにsidが存在する場合はそちらを判定
Cookieに存在しない場合はパラメーターのsidを判定に利用します
```

CLI

```text
beauth login <method> [--params=<JSON>]

    <method>    Specify each method name
    --params    Json format with reference to request parameters
```

HTTP

```text
POST https://auth-api.becom.co.jp/

See example for usage
使用法は Example を参照
```

Method

```text
signup      Creating a login user
start       Start login
end         Logout
status      Check login status
refresh     Update session id
```

## Example

### Login signup

ログインユーザーの作成

```text
ログインユーザーの作成後はログイン状態
```

Request parameters

```json
{
  "loginid": "info@becom.co.jp",
  "password": "info",
  "limitation": "100"
}
```

Response parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp/' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--data-binary '{"resource":"login","method":"signup","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login signup --params='{}'
```

### Login start

ログインを開始

Request parameters

```json
{
  "loginid": "info@becom.co.jp",
  "password": "info"
}
```

Response parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp/' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--data-binary '{"resource":"login","method":"start","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login start --params='{}'
```

### Login end

ログアウトする

判定順位 cookie_sid -> params_sid -> params_loginid

Request parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

or

```json
{ "loginid": "info@becom.co.jp" }
```

Response parameters

```json
{ "status": 200 }
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"login","method":"end","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login end --params='{}'
```

### Login status

ログインステータスを確認する

Request parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

Response parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "status": 200
}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"login","method":"status","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login status --params='{}'
```

### Login refresh

セッション ID を更新

Request parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

Response parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA4IDEwOjM3OjU2OjAyNDM" }
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"login","method":"refresh","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login refresh --params='{}'
```
