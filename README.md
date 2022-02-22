# auth-api

認証をする共通のアプリ

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
