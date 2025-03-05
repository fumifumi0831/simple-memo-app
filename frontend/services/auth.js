import axios from 'axios';

const API_URL = 'http://localhost:8000';

// ログイン処理
export const login = async (username, password) => {
  try {
    const formData = new FormData();
    formData.append('username', username);
    formData.append('password', password);

    const response = await axios.post(`${API_URL}/token`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });

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
export const register = async (username, email, password) => {
  try {
    const response = await axios.post(`${API_URL}/users/`, {
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
export const logout = () => {
  localStorage.removeItem('token');
};

// 現在のユーザー情報を取得
export const getCurrentUser = async () => {
  try {
    const token = JSON.parse(localStorage.getItem('token'));
    if (!token) return null;

    const response = await axios.get(`${API_URL}/users/me/`, {
      headers: {
        Authorization: `Bearer ${token.access_token}`,
      },
    });
    return response.data;
  } catch (error) {
    console.error('Get current user error:', error);
    // 認証エラーの場合はトークンを削除
    if (error.response && error.response.status === 401) {
      logout();
    }
    return null;
  }
};

// トークン付きのリクエストヘッダーを取得
export const authHeader = () => {
  const token = JSON.parse(localStorage.getItem('token'));
  if (token && token.access_token) {
    return { Authorization: `Bearer ${token.access_token}` };
  } else {
    return {};
  }
};

// 認証済みかどうかをチェック
export const isAuthenticated = () => {
  return !!localStorage.getItem('token');
};