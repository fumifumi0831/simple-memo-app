# シンプルメモアプリ

Next.js（フロントエンド）とFastAPI + SQLAlchemy（バックエンド）を使用した、認証機能付きのシンプルなメモアプリケーションです。TypeScriptを使用して型安全性を確保しています。

## アプリの概要

このアプリケーションは、データベース（サーバーサイド）、セッション管理、ローカルストレージ（フロントエンド）の3つのデータ保存技術を学習するために作成されました。

### 主な機能

- **ユーザー認証**
  - ユーザー登録
  - ログイン/ログアウト
  - JWTを使用したセッション管理

- **メモ管理**
  - メモの作成（タイトルと内容）
  - メモの一覧表示
  - メモの削除

- **UIカスタマイズ**
  - ダークモード/ライトモード切替（ローカルストレージに保存）

## 環境構成

### プロジェクト構造

```
simple-memo-app/
├── backend/     # FastAPIアプリケーション
│   ├── main.py             # メインアプリケーション
│   ├── database.py         # データベース設定
│   ├── models.py           # データモデル
│   ├── auth.py             # 認証機能
│   └── requirements.txt    # 依存ライブラリ
└── frontend/    # Next.jsアプリケーション
    ├── pages/              # ページコンポーネント
    │   ├── index.tsx       # メインページ
    │   ├── login.tsx       # ログインページ
    │   ├── register.tsx    # 登録ページ
    │   └── _app.tsx        # アプリケーションラッパー
    ├── components/         # 再利用可能なコンポーネント
    │   └── ThemeProvider.tsx # テーマ管理
    ├── contexts/           # Reactコンテキスト
    │   └── AuthContext.tsx  # 認証状態管理
    ├── services/           # APIサービス
    │   ├── auth.ts         # 認証サービス
    │   └── notes.ts        # メモサービス
    ├── types/              # TypeScript型定義
    │   └── index.ts        # アプリケーション全体の型定義
    └── styles/             # CSSスタイル
```

### 技術スタック

#### バックエンド
- **FastAPI**: 高速なPythonウェブフレームワーク
- **SQLAlchemy**: Pythonの代表的なORM（Object-Relational Mapper）
- **SQLite**: 軽量データベース
- **JWT**: JSON Web Token認証
- **Pydantic**: データバリデーション
- **Passlib**: パスワードハッシュ

#### フロントエンド
- **Next.js**: Reactベースのフレームワーク
- **TypeScript**: 静的型付けによる安全なJavaScript
- **React Hooks**: ステート管理（useState, useEffect, useContext）
- **Axios**: HTTP通信
- **CSS Modules**: コンポーネント単位のスタイリング

## 3つのデータ保存技術の詳細解説

このアプリは3つの異なるデータ保存技術を実装しており、それぞれが異なる役割を果たしています。

### 1. サーバーサイドデータベース（SQLite + SQLAlchemy）

#### 基本概念
サーバーサイドデータベースとは、アプリケーションサーバー上で動作するデータベースで、永続的にデータを保存します。

#### 実装詳細
- **ファイル**: `backend/database.py`, `backend/models.py`
- **データ保存場所**: サーバー上の `memo_app.db` ファイル
- **保存されるデータ**: ユーザー情報（ユーザー名、メールアドレス、パスワードハッシュ）、メモデータ（タイトル、内容、作成日時）

#### コード例
```python
# models.py - データモデルの定義
class Note(Base):
    __tablename__ = "notes"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow)
    owner_id = Column(Integer, ForeignKey("users.id"))
```

#### データの流れ
1. ユーザーがアプリでメモを作成/編集する
2. フロントエンドがAPIを通じてデータをサーバーに送信
3. サーバーがデータをSQLiteデータベースに保存
4. データはサーバーのファイルシステム上に永続的に残る

#### メリット
- 複数のデバイスからアクセスしても同じデータが見える
- アプリを削除しても、データは残る
- バックアップが容易
- ユーザー間でデータを共有できる（このアプリでは各ユーザーが自分のメモのみ閲覧可能）

### 2. セッション管理（JWT）

#### 基本概念
セッション管理とは、ユーザーがログインしたことを覚えておくための仕組みです。JWTは、サーバーが発行した「身分証明書」のようなもので、これをフロントエンドが保持することで認証状態を維持します。

#### 実装詳細
- **バックエンドファイル**: `backend/auth.py`
- **フロントエンドファイル**: `frontend/services/auth.ts`, `frontend/contexts/AuthContext.tsx`
- **データ保存場所**: トークンはフロントエンドのlocalStorageに保存、検証はサーバー側で実施
- **保存されるデータ**: アクセストークン（ユーザーIDと有効期限を暗号化したもの）

#### コード例
```typescript
// auth.ts - フロントエンド側でのトークン保存
export const login = async (username: string, password: string): Promise<TokenResponse | null> => {
  try {
    const response: AxiosResponse<TokenResponse> = await axios.post(`${API_URL}/token`, formData);
    if (response.data.access_token) {
      // トークンをローカルストレージに保存
      localStorage.setItem('token', JSON.stringify(response.data));
      return response.data;
    }
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
  return null;
};
```

#### データの流れ
1. ユーザーがログインする
2. サーバーが認証情報をチェックし、正しければJWTトークンを生成
3. フロントエンドがトークンをlocalStorageに保存
4. 以降のAPI呼び出しで、トークンをAuthorizationヘッダーに含めて送信
5. サーバーはトークンを検証し、有効なら操作を許可

#### メリット
- ステートレス（サーバーがセッション情報を保持しなくて良い）
- スケーラビリティが高い（複数サーバーでも動作）
- クロスドメインでも利用可能
- トークンに有効期限を設定できる

### 3. フロントエンドストレージ（localStorage）

#### 基本概念
フロントエンドストレージとは、ブラウザ上にデータを保存する仕組みです。localStorageは、キーと値のペアでデータを永続的に保存できます。

#### 実装詳細
- **ファイル**: `frontend/components/ThemeProvider.tsx`
- **データ保存場所**: ユーザーのブラウザ内
- **保存されるデータ**: ダークモード設定、認証トークン

#### コード例
```typescript
// ThemeProvider.tsx - テーマ設定の保存
const toggleDarkMode = (): void => {
  const newDarkMode = !darkMode;
  setDarkMode(newDarkMode);
  localStorage.setItem('darkMode', String(newDarkMode));
};
```

#### データの流れ
1. ユーザーがダークモードを切り替える
2. 設定がlocalStorageに保存される
3. ブラウザを閉じても設定は維持される
4. 次回アクセス時に設定が読み込まれ適用される

#### メリット
- ネットワーク接続なしでデータにアクセスできる
- サーバー負荷を軽減できる
- 即時アクセスが可能（レスポンスが速い）
- ブラウザを閉じても設定が維持される

## 技術選択の理由と使い分け

### データの保存先選択基準

データの特性に応じて、以下の基準で保存先を決定しています：

- **重要度が高い/共有されるべきデータ** → サーバーサイドデータベース
  - ユーザーアカウント情報
  - メモの内容と作成日時

- **セッションに関するデータ** → JWT + localStorage
  - ログイン状態
  - アクセス権限情報
  - 有効期限のある認証情報

- **UI/UXに関する個人設定** → localStorage
  - テーマ設定（ダークモード/ライトモード）
  - 表示設定

## TypeScriptによる型安全性

TypeScriptを使用することで、各データ保存技術の実装に型安全性を追加しています：

```typescript
// データモデルの型定義
export interface Note {
  id: number;
  title: string;
  content: string;
  created_at: string;
  updated_at: string;
}

// APIレスポンスの型定義
export interface TokenResponse {
  access_token: string;
  token_type: string;
}
```

主なメリット：
- コンパイル時の型チェックによるエラー検出
- コード補完によるDX向上
- 保守性と可読性の向上
- リファクタリングの安全性

## セットアップと実行方法

### 前提条件
- Python 3.8以上
- Node.js 16以上
- npm（または yarn）

### バックエンド起動手順

1. バックエンドディレクトリに移動
   ```bash
   cd simple-memo-app/backend
   ```

2. 仮想環境の作成とアクティベート
   ```bash
   # 仮想環境の作成
   python -m venv venv

   # 仮想環境のアクティベート（Windows）
   venv\Scripts\activate

   # 仮想環境のアクティベート（macOS/Linux）
   source venv/bin/activate
   ```

3. 必要なパッケージのインストール
   ```bash
   pip install -r requirements.txt
   ```

4. バックエンドサーバーの起動
   ```bash
   uvicorn main:app --reload
   ```

5. バックエンドは http://localhost:8000 で実行されます
   - API ドキュメントは http://localhost:8000/docs で確認できます

### フロントエンド起動手順

1. 別のターミナルでフロントエンドディレクトリに移動
   ```bash
   cd simple-memo-app/frontend
   ```

2. 必要なパッケージのインストール
   ```bash
   npm install
   # または
   yarn install
   ```

3. 開発サーバーの起動
   ```bash
   npm run dev
   # または
   yarn dev
   ```

4. フロントエンドは http://localhost:3000 で実行されます

## アプリの使用方法

1. ブラウザで http://localhost:3000 にアクセス
2. 初めての場合は「登録」リンクからアカウント作成
3. ユーザー名、メールアドレス、パスワードを入力して登録
4. 登録後自動的にログインし、メインページにリダイレクト
5. メモの作成：
   - タイトルと内容を入力
   - 「保存」ボタンをクリック
6. 右上のボタンでダークモード/ライトモード切替
7. 「ログアウト」ボタンでログアウト

## トラブルシューティング

1. **バックエンドの起動エラー**
   - Pythonのバージョンが3.8以上であることを確認
   - 必要なライブラリがすべてインストールされているか確認
   - ポート8000が他のアプリケーションで使用されていないか確認

2. **フロントエンドの起動エラー**
   - Node.jsのバージョンが16以上であることを確認
   - `npm install` が正常に完了しているか確認
   - ポート3000が他のアプリケーションで使用されていないか確認

3. **認証エラー**
   - バックエンドが起動しているか確認
   - 正しいユーザー名とパスワードを使用しているか確認
   - ブラウザのlocalStorageをクリアして再ログイン

4. **メモ操作のエラー**
   - ネットワーク接続を確認
   - 認証が有効か確認（再ログインを試す）
   - バックエンドのログを確認