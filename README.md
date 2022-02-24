# auth-api

認証をする共通のアプリ

## SETUP

ignore

```zsh
echo 'local' >> .gitignore
echo 'db' >> .gitignore
```

Perl

```zsh
echo '5.14.4' > .perl-version
echo "requires 'DBD::SQLite', '==1.54';" >> cpanfile
echo "requires 'Test::Trap';" >> cpanfile
echo "requires 'Text::CSV', '2.01';" >> cpanfile
```

Module

```zsh
curl -L https://cpanmin.us/ -o cpanm
chmod +x cpanm
./cpanm -l ./local --installdeps .
```

## Usage

### CLI

`beauth <resource> <method> [--params=<JSON>]`

```text
<resource>  Specify each resource name
<method>    Specify each method name
--params    Json format with reference to request parameters
```

```text
Specify the resource name as the first argument
Specify the method name as the second argument
Format command line interface options in json format

第一引数はリソース名を指定
第二引数はメソッド名を指定
コマンドラインインターフェスのオプションはjson形式で整形してください
```

### HTTP

`POST https://auth-api.becom.co.jp/`

```text
http request requires apikey
All specifications should be included in the post request parameters
See Examples in each document for usage

http リクエストには apikey の指定が必要
全ての指定は post リクエストのパラメーターに含めてください
使用法は各ドキュメントの Example を参照
```

### Resource

See here for details: [doc/](doc/)

```text
user      Registered user
login     Login system
session   Issuing unique values
apikey    Manage apikey
```

## Memo

```text
認証をする共通のアプリ
auth-api.becom.co.jp -> www/auth-api/cgi-bin/
コマンド
beauth --path=user --method=get --params='{}'
beauth --path=user --method=list --params='{}'
beauth --path=user --method=insert --params='{}'
beauth --path=user --method=update --params='{}'
beauth --path=user --method=delete --params='{}'

beauth --path=login --params='{}'
beauth --path=logout --params='{}'

beauth --path=session --method=get --params='{}'
beauth --path=session --method=list --params='{}'
beauth --path=session --method=insert --params='{}'
beauth --path=session --method=update --params='{}'
beauth --path=session --method=delete --params='{}'

beauth --path=apikey --method=get --params='{}'
beauth --path=apikey --method=list --params='{}'
beauth --path=apikey --method=insert --params='{}'
beauth --path=apikey --method=update --params='{}'
beauth --path=apikey --method=delete --params='{}'
```

ログインの流れのメモ

```text
get / zsearch-web.becom.co.jp/login
  入力フォーム
  html の入力フォームのpostでおくる
  id,pass 送信logincheck
  post auth-api.becom.co.jp/index.cgi
    {path:login,method:input,params:{id:becom,pass:becom}}
    res {msg:ok,id:'',sid:becom..}
    html フォームをクリック実行
    送信時postのparamsにsidをのせておく
    post auth-api.becom.co.jp/index.cgi

    post zsearch-web.becom.co.jp/loggedin.cgi
      cookie情報の埋め込み
        sid: becomsid ...
      body: ログイン後の画面へのリンク
    get zsearch-web.becom.co.jp/admin
```
