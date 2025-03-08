import axios, { AxiosError, AxiosResponse } from 'axios';
import { 
  User, 
  TokenResponse, 
  RegisterCredentials 
} from '../types';

// 基本のAPI URL設定
let API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// クライアントサイドでの実行時に環境を検出して上書き
if (typeof window !== 'undefined') {
  const hostname = window.location.hostname;
  if (hostname.includes('prod')) {
    // 本番環境
    API_URL = 'https://simple-memo-app-backend-prod.azurewebsites.net';
    console.log('Production environment detected, API URL:', API_URL);
  } else if (hostname.includes('dev')) {
    // 開発環境
    API_URL = 'https://simple-memo-app-backend-dev.azurewebsites.net';
    console.log('Development environment detected, API URL:', API_URL);
  }
}

// ログイン処理
export const login = async (username: string, password: string): Promise<TokenResponse | null> => {
  try {
    const formData = new FormData();
    formData.append('username', username);
    formData.append('password', password);

    const response: AxiosResponse<TokenResponse> = await axios.post(
      `${API_URL}/token`, 
      formData, 
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );

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

// ユーザー登録処理
export const register = async (
  username: string, 
  email: string, 
  password: string
): Promise<User> => {
  try {
    const response: AxiosResponse<User> = await axios.post(`${API_URL}/users/`, {
      username,
      email,
      password,
    });
    return response.data;
  } catch (error) {
    console.error('Registration error:', error);
    throw error;
  }
};

// ログアウト処理
export const logout = (): void => {
  localStorage.removeItem('token');
};

// 現在のユーザー情報を取得
export const getCurrentUser = async (): Promise<User | null> => {
  try {
    const tokenStr = localStorage.getItem('token');
    if (!tokenStr) return null;

    const token: TokenResponse = JSON.parse(tokenStr);

    const response: AxiosResponse<User> = await axios.get(`${API_URL}/users/me/`, {
      headers: {
        Authorization: `Bearer ${token.access_token}`,
      },
    });
    return response.data;
  } catch (error) {
    console.error('Get current user error:', error);
    // 認証エラーの場合はトークンを削除
    if ((error as AxiosError).response?.status === 401) {
      logout();
    }
    return null;
  }
};

// トークン付きのリクエストヘッダーを取得
export const authHeader = (): Record<string, string> => {
  const tokenStr = localStorage.getItem('token');
  if (tokenStr) {
    const token: TokenResponse = JSON.parse(tokenStr);
    if (token.access_token) {
      return { Authorization: `Bearer ${token.access_token}` };
    }
  }
  return {};
};

// 認証済みかどうかをチェック
export const isAuthenticated = (): boolean => {
  return !!localStorage.getItem('token');
};