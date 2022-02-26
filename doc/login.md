# Login

ログインシステム

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
start       Start login
end         Logout
status      Check login status
refresh     Update session id
```

## Example

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

Request parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

Response parameters

```json
{}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
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
--data-binary '{"resource":"login","method":"status","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login status --params='{}'
```

### Login refresh

セッションIDを更新

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
--data-binary '{"resource":"login","method":"refresh","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth login refresh --params='{}'
```
