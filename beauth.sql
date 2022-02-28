DROP TABLE IF EXISTS user;
CREATE TABLE user (                                       -- ユーザー
    `id`              INTEGER PRIMARY KEY AUTOINCREMENT,  -- ID (例: 5)
    `loginid`         TEXT,                               -- ログインID名 (例: 'info@gmail.com')
    `password`        TEXT,                               -- ログインパスワード (例: 'info')
    `approved`        INTEGER,                            -- 承認フラグ (例: 0: 承認していない, 1: 承認済み)
    `deleted`         INTEGER,                            -- 削除フラグ (例: 0: 削除していない, 1: 削除済み)
    `created_ts`      TEXT,                               -- 登録日時 (例: '2022-01-23 23:49:12')
    `modified_ts`     TEXT                                -- 修正日時 (例: '2022-01-23 23:49:12')
);
DROP TABLE IF EXISTS `login`;
CREATE TABLE `login` (                                  -- ログイン
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,  -- ID (例: 5)
    `sid`           TEXT,                               -- セッションID名 (例: 'sessionnumber')
    `loginid`       TEXT,                               -- ログインID名 (例: 'info@gmail.com')
    `loggedin`      INTEGER,                            -- 認証フラグ (例: 0: ログインしていない, 1: ログインしている)
    `expiry_ts`     TEXT,                               -- 有効期限 (例: '2022-02-23 23:49:12')
    `deleted`       INTEGER,                            -- 削除フラグ (例: 0: 削除していない, 1: 削除済み)
    `created_ts`    TEXT,                               -- 登録日時 (例: '2022-01-23 23:49:12')
    `modified_ts`   TEXT                                -- 修正日時 (例: '2022-01-23 23:49:12')
);
DROP TABLE IF EXISTS `webapi`;
CREATE TABLE `webapi` (                                 -- apikey管理
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,  -- ID (例: 5)
    `apikey`        TEXT,                               -- 接続キー (例: 'sessionnumber')
    `loginid`       TEXT,                               -- ログインID名 (例: 'info@gmail.com')
    `target`        TEXT,                               -- 対象のアプリケーション (例: 'zsearch')
    `is_available`  INTEGER,                            -- 利用可能フラグ (例: 0: 利用不能, 1: 利用可能)
    `expiry_ts`     TEXT,                               -- 有効期限 (例: '2022-02-23 23:49:12')
    `deleted`       INTEGER,                            -- 削除フラグ (例: 0: 削除していない, 1: 削除済み)
    `created_ts`    TEXT,                               -- 登録日時 (例: '2022-01-23 23:49:12')
    `modified_ts`   TEXT                                -- 修正日時 (例: '2022-01-23 23:49:12')
);
DROP TABLE IF EXISTS `limitation`;
CREATE TABLE `limitation` (                             -- 制限
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,  -- ID (例: 5)
    `loginid`       INTEGER,                            -- ログインID名 (例: 'info@gmail.com')
    `status`        INTEGER,                            -- ステータス (例: 1**: 管理者, 2**: 一般)
    `deleted`       INTEGER,                            -- 削除フラグ (例: 0: 削除していない, 1: 削除済み)
    `created_ts`    TEXT,                               -- 登録日時 (例: '2022-01-23 23:49:12')
    `modified_ts`   TEXT                                -- 修正日時 (例: '2022-01-23 23:49:12')
);
