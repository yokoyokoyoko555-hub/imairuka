# Imairuka

This README would normally document whatever steps are necessary to get the
application up and running.

## セットアップ手順

インストール型としてWindows PCで試す場合は、まず `install_imairuka.bat` をダブルクリックしてください。詳しい手順は [docs/installable_deploy.md](docs/installable_deploy.md) を参照してください。

### 1. 依存関係のインストール

```bash
bundle install
npm install
```

### 2. データベースのセットアップ

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 3. Cloudinary の設定

商品画像と添付ファイルの管理に Cloudinary を使用しています。

#### 3.1 Cloudinary アカウントの作成

1. [Cloudinary](https://cloudinary.com/)にアクセス
2. 無料アカウントを作成
3. ダッシュボードから以下を取得：
   - Cloud Name
   - API Key
   - API Secret

#### 3.2 環境変数の設定

`.env`ファイルを作成し、以下を設定：

```bash
# Cloudinary設定
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

#### 3.3 Heroku での設定

```bash
heroku config:set CLOUDINARY_CLOUD_NAME=your_cloud_name
heroku config:set CLOUDINARY_API_KEY=your_api_key
heroku config:set CLOUDINARY_API_SECRET=your_api_secret
```

### 4. アプリケーションの起動

```bash
bin/rails server
```

## 機能

- 商品管理（画像・添付ファイル対応）
- 案件管理
- 見積書・請求書管理
- 顧客管理
