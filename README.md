# auth-api

認証をする共通のアプリ

## Setup

事前に`plenv`を使えるようにしておき指定バージョンのPerlを使えるように

git clone にてソースコードを配置後プロジェクト配下にてモジュールをインストール

```zsh
./cpanm -l ./local --installdeps .
```

## Work

ローカル開発時の起動方法など

app サーバー起動の場合

```zsh
perl -I ./local/lib/perl5 ./local/bin/morbo ./script/app
```

リクエスト

```zsh
curl 'http://localhost:3000/'
```

cgi ファイルを起動の場合

```zsh
python3 -m http.server 8000 --cgi
```

リクエスト

```zsh
curl 'http://localhost:3000/cgi-bin/index.cgi'
```

コマンドラインによる起動

```zsh
./script/beauth
```

詳細は[doc/](doc/)を参照

公開環境へ公開

```sh
ssh becom2022@becom2022.sakura.ne.jp
cd ~/www/auth-api
git fetch && git checkout main && git pull
```

## Usage

### CLI

```text
beauth <resource> <method> [--params=<JSON>]

  <resource>  Specify each resource name
  <method>    Specify each method name
  --params    Json format with reference to request parameters

Specify the resource name as the first argument
Specify the method name as the second argument
Format command line interface options in json format

第一引数はリソース名を指定
第二引数はメソッド名を指定
コマンドラインインターフェスのオプションはjson形式で整形してください
```

### HTTP

```text
POST https://auth-api.becom.co.jp/

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
build     Environment
user      Registered user
login     Login system
webapi    Manage apikey
```

## URL

`auth-api`に紐づけられる各種URLの全体像

stg環境については各アプリ利用状況に応じて用意してゆく予定

### prod

- zsearch
  - zsearch-api `https://zsearch-api.becom.co.jp/`
  - zsearch-web `https://zsearch-web.becom.co.jp/`
- mhj
  - mhj-api `https://mhj-api.becom.co.jp/`
  - mhj-web `https://mhj-web.becom.co.jp/`
- img-stocker
  - static `https://img.becom.co.jp/`
  - img-api `https://img-api.becom.co.jp/`
  - img-web `https://img-web.becom.co.jp/`
- drill
  - drill-api `https://drill-api.becom.co.jp/`
  - drill-web `https://drill-web.becom.co.jp/`

### stg

- beauth
  - auth-api `https://auth-stg-api.becom.co.jp/`
  - auth-web `https://auth-stg-web.becom.co.jp/`
- zsearch
  - zsearch-api `https://zsearch-stg-api.becom.co.jp/`
  - zsearch-web `https://zsearch-stg-web.becom.co.jp/`
- mhj
  - mhj-api `https://mhj-stg-api.becom.co.jp/`
  - mhj-web `https://mhj-stg-web.becom.co.jp/`
- img-stocker
  - static `https://img-stg.becom.co.jp/`
  - img-api `https://img-stg-api.becom.co.jp/`
  - img-web `https://img-stg-web.becom.co.jp/`
- drill
  - drill-api `https://drill-stg-api.becom.co.jp/`
  - drill-web `https://drill-stg-web.becom.co.jp/`

### local

- beauth
  - auth-api `http://localhost:3000/`
  - auth-web `http://localhost:4000/`
- zsearch
  - zsearch-api `http://localhost:3010/`
  - zsearch-web `http://localhost:4010/`
- mhj
  - mhj-api `http://localhost:3020/`
  - mhj-web `http://localhost:4020/`
- img-stocker
  - static `http://localhost:3030/static/`
  - img-api `http://localhost:3030/`
  - img-web `http://localhost:4030/`
- drill
  - drill-api `http://localhost:3040/`
  - drill-web `http://localhost:4040/`

## Memo

### Environment

初動時の環境構築に関するメモ

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
