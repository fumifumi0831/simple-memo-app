import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  login as authLogin,
  register as authRegister,
  logout as authLogout,
  getCurrentUser,
  isAuthenticated as checkIsAuthenticated
} from '../services/auth';
import { User, AuthContextType } from '../types';

// 認証コンテキストの作成
const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps): JSX.Element {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // 初期化時にユーザー情報を取得
  useEffect(() => {
    const checkAuth = async (): Promise<void> => {
      setLoading(true);
      if (checkIsAuthenticated()) {
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
  const login = async (username: string, password: string): Promise<void> => {
    setLoading(true);
    setError(null);
    try {
      await authLogin(username, password);
      const userData = await getCurrentUser();
      setUser(userData);
    } catch (err: any) {
      console.error('Login failed:', err);
      setError(err.response?.data?.detail || 'Login failed');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // ユーザー登録処理
  const register = async (username: string, email: string, password: string): Promise<void> => {
    setLoading(true);
    setError(null);
    try {
      await authRegister(username, email, password);
      // 登録後に自動的にログイン
      return login(username, password);
    } catch (err: any) {
      console.error('Registration failed:', err);
      setError(err.response?.data?.detail || 'Registration failed');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // ログアウト処理
  const logout = (): void => {
    authLogout();
    setUser(null);
  };

  // コンテキスト値
  const value: AuthContextType = {
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
export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}