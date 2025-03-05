import { createContext, useContext, useState, useEffect } from 'react';
import { 
  login as authLogin,
  register as authRegister,
  logout as authLogout,
  getCurrentUser,
  isAuthenticated
} from '../services/auth';

// 認証コンテキストの作成
const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // 初期化時にユーザー情報を取得
  useEffect(() => {
    const checkAuth = async () => {
      setLoading(true);
      if (isAuthenticated()) {
        try {
          const userData = await getCurrentUser();
          setUser(userData);
        } catch (err) {
          console.error('Failed to get user data:', err);
          setError('Failed to authenticate');
        }
      }
      setLoading(false);
    };

    checkAuth();
  }, []);

  // ログイン処理
  const login = async (username, password) => {
    setLoading(true);
    setError(null);
    try {
      await authLogin(username, password);
      const userData = await getCurrentUser();
      setUser(userData);
    } catch (err) {
      console.error('Login failed:', err);
      setError(err.response?.data?.detail || 'Login failed');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // ユーザー登録処理
  const register = async (username, email, password) => {
    setLoading(true);
    setError(null);
    try {
      await authRegister(username, email, password);
      // 登録後に自動的にログイン
      return login(username, password);
    } catch (err) {
      console.error('Registration failed:', err);
      setError(err.response?.data?.detail || 'Registration failed');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // ログアウト処理
  const logout = () => {
    authLogout();
    setUser(null);
  };

  // コンテキスト値
  const value = {
    user,
    loading,
    error,
    login,
    register,
    logout,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// 認証コンテキストを使用するためのカスタムフック
export function useAuth() {
  return useContext(AuthContext);
}