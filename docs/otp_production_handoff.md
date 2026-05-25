# OTPログイン本番反映 引継ぎ書

作成日: 2026-05-26

## 目的

Imairuka本番環境に、メールOTPログイン機能を反映する。

現在、OTPログイン機能のコードはリポジトリに反映済みだが、Heroku本番では後日有効化する。SMTP設定が完了するまでは通常ログインを継続する。

## 対象リポジトリ

- GitHub: https://github.com/yokoyokoyoko555-hub/imairuka
- 反映対象コミット: `ff129ec feat: add email otp login`
- Herokuアプリ: `imairuka-order`
- Heroku本番URL: https://imairuka-order-793fd07d208c.herokuapp.com/

## 運営会社用URL

契約管理は運営会社用の管理ページで行う。

- 契約管理URL: https://imairuka-order-793fd07d208c.herokuapp.com/admin/companies
- ログインURL: https://imairuka-order-793fd07d208c.herokuapp.com/login
- 利用申込URL: https://imairuka-order-793fd07d208c.herokuapp.com/signup

契約管理ページは `platform_admin` 権限のユーザーのみ利用可能。

## 本番反映前の現状

2026-05-26時点の確認結果:

- ローカル最新コミット: `ff129ec feat: add email otp login`
- Heroku最新リリース: `v70 Deploy 5d312700`
- Heroku本番にはOTPログイン機能が未反映
- HerokuのSMTP関連Config Varsは未設定
- `EMAIL_OTP_LOGIN_ENABLED` は未設定または `false` のままにする

## 現時点の運用方針

SMTP設定が完了するまでは、OTPログインを有効化しない。

`EMAIL_OTP_LOGIN_ENABLED` が未設定または `false` の場合、ログインは従来通りメールアドレスとパスワードのみで完了する。

本番反映時点のテスト用ログイン:

```text
Email: admin@example.com
Password: Password1!
```

## SMTP環境変数

Heroku本番環境に以下のConfig Varsを設定する。

OTP有効化フラグ:

```text
EMAIL_OTP_LOGIN_ENABLED=true
```

必須:

```text
SMTP_ADDRESS=<SMTPサーバー>
SMTP_PORT=587
SMTP_USERNAME=<SMTPユーザー名>
SMTP_PASSWORD=<SMTPパスワードまたはアプリパスワード>
MAIL_FROM=<送信元メールアドレス>
```

推奨:

```text
SMTP_DOMAIN=imairuka.com
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
APP_HOST=imairuka-order-793fd07d208c.herokuapp.com
```

補足:

- `SMTP_ADDRESS` が設定されると、本番環境でAction MailerのSMTP配信が有効になる。
- `MAIL_FROM` はOTPメールの送信元として使われる。
- Gmail / Google Workspaceを使う場合、通常のログインパスワードではなくアプリパスワードを使う。
- SMTPの契約・認証情報はコードやGitHubにコミットしない。

## Heroku設定コマンド例

値を確認したうえで、Heroku管理者または本番環境を管理するエンジニアが実行する。

```bash
heroku config:set SMTP_ADDRESS=<SMTPサーバー> --app imairuka-order
heroku config:set SMTP_PORT=587 --app imairuka-order
heroku config:set SMTP_USERNAME=<SMTPユーザー名> --app imairuka-order
heroku config:set SMTP_PASSWORD=<SMTPパスワード> --app imairuka-order
heroku config:set MAIL_FROM=<送信元メールアドレス> --app imairuka-order

heroku config:set SMTP_DOMAIN=imairuka.com --app imairuka-order
heroku config:set SMTP_AUTHENTICATION=plain --app imairuka-order
heroku config:set SMTP_ENABLE_STARTTLS_AUTO=true --app imairuka-order
heroku config:set APP_HOST=imairuka-order-793fd07d208c.herokuapp.com --app imairuka-order
```

設定確認:

```bash
heroku config --app imairuka-order
```

## デプロイ手順

SMTP未設定のまま `main` をデプロイする場合は、`EMAIL_OTP_LOGIN_ENABLED` を設定しない。これにより通常ログインのまま本番反映できる。

SMTP設定後にOTPを有効化する場合は、SMTP環境変数と `EMAIL_OTP_LOGIN_ENABLED=true` を設定してからHerokuへデプロイする。

```bash
git checkout main
git pull origin main
git log -1 --oneline
git push heroku main
```

`Procfile` のrelease phaseで以下が実行されるため、OTP用DBマイグレーションもデプロイ時に適用される。

```text
release: bin/rails db:migrate
```

## デプロイ後の確認

リリース確認:

```bash
heroku releases --app imairuka-order
```

アプリ起動確認:

```bash
heroku ps --app imairuka-order
heroku logs --tail --app imairuka-order
```

Rails側の簡易確認:

```bash
heroku run bin/rails runner "puts UserMailer.otp_delivery_available?" --app imairuka-order
```

期待値:

```text
true
```

## OTPログイン確認

1. https://imairuka-order-793fd07d208c.herokuapp.com/login を開く。
2. 既存ユーザーのメールアドレスとパスワードでログインする。
3. 登録メールアドレスに6桁の認証コードが届くことを確認する。
4. `/login/otp` で認証コードを入力する。
5. ログイン後の画面に遷移することを確認する。

確認ポイント:

- メールが届かない場合はHeroku logsで `Login OTP delivery failed` を確認する。
- SMTP認証エラーの場合は `SMTP_USERNAME` / `SMTP_PASSWORD` / アプリパスワードを確認する。
- 送信元エラーの場合は `MAIL_FROM` がSMTPサービスで許可されたメールアドレスか確認する。

## 契約管理ページ確認

1. `platform_admin` 権限のユーザーでログインする。
2. https://imairuka-order-793fd07d208c.herokuapp.com/admin/companies を開く。
3. 契約企業一覧が表示されることを確認する。
4. 必要に応じて、申込受付中の契約候補、契約状態、契約金額、契約期間を確認する。

## 関連実装

- SMTP本番設定: `config/environments/production.rb`
- OTPメール送信可否: `app/mailers/user_mailer.rb`
- 送信元メール: `app/mailers/application_mailer.rb`
- ログインOTP処理: `app/controllers/sessions_controller.rb`
- OTP保存・検証: `app/models/user.rb`
- OTP用DBマイグレーション: `db/migrate/20260526090000_add_login_otp_to_users.rb`
- 契約管理ルート: `config/routes.rb`

## ロールバック

デプロイ後に問題がある場合:

```bash
heroku releases --app imairuka-order
heroku rollback v70 --app imairuka-order
```

注意:

- `v70` は2026-05-26確認時点のOTP反映前リリース。
- 実際にロールバックする前に、最新の `heroku releases` で戻し先を確認する。
- DBマイグレーションが適用済みでも、追加カラムは既存ログインに影響しない想定。

## 未対応事項

- Heroku本番へのSMTP Config Vars設定
- Heroku本番での `EMAIL_OTP_LOGIN_ENABLED=true` 設定
- 本番でのOTPメール到達確認
- 運営会社用の契約管理ページ確認
