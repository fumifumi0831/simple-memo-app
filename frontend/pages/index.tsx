import { useState, useEffect, FormEvent } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { useTheme } from '../components/ThemeProvider';
import { useAuth } from '../contexts/AuthContext';
import { getNotes, createNote, deleteNote } from '../services/notes';
import { Note } from '../types';

export default function Home(): JSX.Element | null {
  const [notes, setNotes] = useState<Note[]>([]);
  const [title, setTitle] = useState<string>('');
  const [content, setContent] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const { darkMode, toggleDarkMode } = useTheme();
  const { user, logout, isAuthenticated } = useAuth();
  const router = useRouter();

  // 認証状態をチェック
  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
    }
  }, [isAuthenticated, router]);

  // メモ一覧の取得
  const fetchNotes = async (): Promise<void> => {
    try {
      setLoading(true);
      const data = await getNotes();
      setNotes(data);
      setError('');
    } catch (error) {
      console.error('Error fetching notes:', error);
      setError('メモの取得に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  // 初回ロード時にメモ一覧を取得
  useEffect(() => {
    if (isAuthenticated) {
      fetchNotes();
    }
  }, [isAuthenticated]);

  // 新規メモの作成
  const handleCreateNote = async (e: FormEvent<HTMLFormElement>): Promise<void> => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;

    try {
      await createNote(title, content);
      // フォームをリセット
      setTitle('');
      setContent('');
      // メモ一覧を更新
      fetchNotes();
      setError('');
    } catch (error) {
      console.error('Error creating note:', error);
      setError('メモの作成に失敗しました');
    }
  };

  // メモの削除
  const handleDeleteNote = async (id: number): Promise<void> => {
    try {
      await deleteNote(id);
      // メモ一覧を更新
      fetchNotes();
      setError('');
    } catch (error) {
      console.error('Error deleting note:', error);
      setError('メモの削除に失敗しました');
    }
  };

  // ログアウトの処理
  const handleLogout = (): void => {
    logout();
    router.push('/login');
  };

  if (!isAuthenticated) {
    return null; // 認証されていない場合は何も表示しない（useEffectによりリダイレクト）
  }

  return (
    <div className={styles.container}>
      <Head>
        <title>Memo App</title>
        <meta name="description" content="Simple memo application" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <div className={styles.header}>
          <div className={styles.themeToggle}>
            <button onClick={toggleDarkMode} className={styles.themeButton}>
              {darkMode ? '🌞 ライトモード' : '🌙 ダークモード'}
            </button>
          </div>
          <div className={styles.userInfo}>
            {user && <span>ようこそ、{user.username}さん</span>}
            <button onClick={handleLogout} className={styles.logoutButton}>
              ログアウト
            </button>
          </div>
        </div>

        <h1 className={styles.title}>Memo App</h1>

        {error && <div className={styles.error}>{error}</div>}

        <div className={styles.formContainer}>
          <form onSubmit={handleCreateNote} className={styles.form}>
            <input
              type="text"
              placeholder="タイトル"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className={styles.input}
            />
            <textarea
              placeholder="メモの内容"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className={styles.textarea}
            />
            <button type="submit" className={styles.button}>
              保存
            </button>
          </form>
        </div>

        <div className={styles.grid}>
          {loading ? (
            <p>読み込み中...</p>
          ) : notes.length === 0 ? (
            <p>メモがありません。新しいメモを作成してください。</p>
          ) : (
            notes.map((note) => (
              <div key={note.id} className={styles.card}>
                <h2>{note.title}</h2>
                <p>{note.content}</p>
                <div className={styles.cardFooter}>
                  <small>
                    作成日: {new Date(note.created_at).toLocaleDateString()}
                  </small>
                  <button
                    onClick={() => handleDeleteNote(note.id)}
                    className={styles.deleteButton}
                  >
                    削除
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}// Development environment test change
