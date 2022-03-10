# User

登録ユーザー

```text
管理者と登録者との操作の違いはsidから判定
ログインを通過したときに発行されるsidの値が必要
httpリクエストの場合Cookieにsidが存在する場合はそちらを判定
Cookieに存在しない場合はパラメーターのsidを判定に利用します
```

CLI

```text
beauth user <method> [--params=<JSON>]

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
get         Get registered user information
list        Get a list of registered users
insert      Creating a new registered user
update      Renewal of registered users
delete      Delete registered user information
```

## Example

### User get

登録ユーザーの情報を取得

Request parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "loginid": "info@becom.co.jp"
}
```

Response parameters

```json
{
  "id": 1,
  "loginid": "info@becom.co.jp",
  "password": "info",
  "approved": 1,
  "deleted": 0,
  "created_ts": "2022-01-24 00:46:47",
  "modified_ts": "2022-01-24 00:46:47"
}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp/' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"user","method":"get","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth user get --params='{}'
```

### User list

登録ユーザーの一覧を取得

Request parameters

```json
{ "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0" }
```

Response parameters

```json
[
  {
    "id": 1,
    "loginid": "info@becom.co.jp",
    "password": "info",
    "approved": 1,
    "deleted": 0,
    "created_ts": "2022-01-24 00:46:47",
    "modified_ts": "2022-01-24 00:46:47"
  }
]
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"user","method":"list","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth user list --params='{}'
```

### User insert

登録ユーザーの新規作成(root権限のみ有効)

Request parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "loginid": "info@becom.co.jp",
  "password": "info"
}
```

Response parameters

```json
{
  "id": 1,
  "loginid": "info@becom.co.jp",
  "password": "info",
  "approved": 1,
  "deleted": 0,
  "created_ts": "2022-01-24 00:46:47",
  "modified_ts": "2022-01-24 00:46:47"
}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"user","method":"insert","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth user insert --params='{}'
```

### User update

登録ユーザーのパスワード更新

Request parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "id": 1,
  "password": "updateinfo"
}
```

Response parameters

```json
{
  "id": 1,
  "loginid": "updateinfo@becom.co.jp",
  "password": "updateinfo",
  "approved": 1,
  "deleted": 0,
  "created_ts": "2022-01-24 01:26:59",
  "modified_ts": "2022-01-25 18:45:06"
}
```

HTTP

```zsh
curl 'https://auth-api.becom.co.jp' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"user","method":"update","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth user update --params='{}'
```

### User delete

登録ユーザーの情報を削除

Request parameters

```json
{
  "sid": "aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0",
  "id": 1
}
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
--header 'Cookie: sid=aW5mb0BiZWNvbS5jby5qcDoyMDIyLTAzLTA3IDE0OjI1OjA0' \
--data-binary '{"resource":"user","method":"delete","apikey":"becom","params":{}}'
```

CLI

```zsh
beauth user delete --params='{}'
```
