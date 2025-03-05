// ユーザー関連の型定義
export interface User {
  id: number;
  username: string;
  email: string;
  is_active: boolean;
}

export interface UserCredentials {
  username: string;
  password: string;
}

export interface RegisterCredentials extends UserCredentials {
  email: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
}

// メモ関連の型定義
export interface Note {
  id: number;
  title: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface NoteInput {
  title: string;
  content: string;
}

// 認証コンテキスト用の型定義
export interface AuthContextType {
  user: User | null;
  loading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (username: string, email: string, password: string) => Promise<void>;
  logout: () => void;
}

// テーマコンテキスト用の型定義
export interface ThemeContextType {
  darkMode: boolean;
  toggleDarkMode: () => void;
}