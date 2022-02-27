# Webapi

アプリケーション接続用のキー管理

```text
ログインを通過したときに発行されるsidの値が必要
httpリクエストの場合Cookieにsidが存在する場合はそちらを判定
Cookieに存在しない場合はパラメーターのsidを判定に利用します
```

CLI

```text
beauth webapi <method> [--params=<JSON>]

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
issue       Issue webapi
delete      Delete webapi
list        List of issued apikey
```

## Example

### Webapi issue

webapi の key を発行

Request parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "target": "zsearch"
}
```

Response parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "apikey": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA4IDEwOjM3OjU2OjAyNDM"
}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp/' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"webapi","method":"issue","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth webapi issue --params='{}'
```

### Webapi delete

webapi の key を削除

Request parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "apikey": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA4IDEwOjM3OjU2OjAyNDM"
}
```

Response parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"webapi","method":"delete","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth webapi delete --params='{}'
```

### Webapi list

発行された webapi の key 一覧

Request parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

Response parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "list": [
    {
      "id": "5",
      "apikey": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA4IDEwOjM3OjU2OjAyNDM",
      "loginid": "info@gmail.com",
      "target": "zsearch",
      "is_available": "1",
      "expiry_ts": "2022-02-23 23:49:12",
      "deleted": "0",
      "created_ts": "2022-01-23 23:49:12",
      "modified_ts": "2022-01-23 23:49:12"
    }
  ]
}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"webapi","method":"list","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth webapi list --params='{}'
```
