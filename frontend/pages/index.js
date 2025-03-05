import { useState, useEffect } from 'react';
import axios from 'axios';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { useTheme } from '../components/ThemeProvider';

export default function Home() {
  const [notes, setNotes] = useState([]);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);
  const { darkMode, toggleDarkMode } = useTheme();

  // メモ一覧の取得
  const fetchNotes = async () => {
    try {
      setLoading(true);
      const response = await axios.get('http://localhost:8000/notes/');
      setNotes(response.data);
    } catch (error) {
      console.error('Error fetching notes:', error);
    } finally {
      setLoading(false);
    }
  };

  // 初回ロード時にメモ一覧を取得
  useEffect(() => {
    fetchNotes();
  }, []);

  // 新規メモの作成
  const createNote = async (e) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;

    try {
      await axios.post('http://localhost:8000/notes/', {
        title,
        content,
      });
      // フォームをリセット
      setTitle('');
      setContent('');
      // メモ一覧を更新
      fetchNotes();
    } catch (error) {
      console.error('Error creating note:', error);
    }
  };

  // メモの削除
  const deleteNote = async (id) => {
    try {
      await axios.delete(`http://localhost:8000/notes/${id}`);
      // メモ一覧を更新
      fetchNotes();
    } catch (error) {
      console.error('Error deleting note:', error);
    }
  };

  return (
    <div className={styles.container}>
      <Head>
        <title>Memo App</title>
        <meta name="description" content="Simple memo application" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <div className={styles.themeToggle}>
          <button onClick={toggleDarkMode} className={styles.themeButton}>
            {darkMode ? '🌞 ライトモード' : '🌙 ダークモード'}
          </button>
        </div>

        <h1 className={styles.title}>Memo App</h1>

        <div className={styles.formContainer}>
          <form onSubmit={createNote} className={styles.form}>
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
                    onClick={() => deleteNote(note.id)}
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
}