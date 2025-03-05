import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { ThemeContextType } from '../types';

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

interface ThemeProviderProps {
  children: ReactNode;
}

export function ThemeProvider({ children }: ThemeProviderProps): JSX.Element {
  // ブラウザでのみ実行（Next.jsのSSR対応）
  const [darkMode, setDarkMode] = useState<boolean>(false);
  const [loaded, setLoaded] = useState<boolean>(false);

  // コンポーネントマウント時にlocalStorageから設定を読み込み
  useEffect(() => {
    // クライアントサイドのみで実行
    if (typeof window !== 'undefined') {
      const storedDarkMode = localStorage.getItem('darkMode') === 'true';
      setDarkMode(storedDarkMode);
      setLoaded(true);
    }
  }, []);

  // ダークモード切り替え
  const toggleDarkMode = (): void => {
    const newDarkMode = !darkMode;
    setDarkMode(newDarkMode);
    // クライアントサイドのみで実行
    if (typeof window !== 'undefined') {
      localStorage.setItem('darkMode', String(newDarkMode));
    }
  };

  // ドキュメントにdark-modeクラスを追加/削除
  useEffect(() => {
    if (loaded && typeof document !== 'undefined') {
      if (darkMode) {
        document.documentElement.classList.add('dark-mode');
      } else {
        document.documentElement.classList.remove('dark-mode');
      }
    }
  }, [darkMode, loaded]);

  return (
    <ThemeContext.Provider value={{ darkMode, toggleDarkMode }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme(): ThemeContextType {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}