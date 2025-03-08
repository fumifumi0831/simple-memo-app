import axios, { AxiosResponse } from 'axios';
import { authHeader } from './auth';
import { Note, NoteInput } from '../types';

// 基本のAPI URL設定（サーバーサイドでも安全）
let API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// 環境変数が設定されていない場合のフォールバック処理
// この関数はクライアントサイドでのみ呼び出される
const detectEnvironment = () => {
  if (typeof window === 'undefined') return;
  
  try {
    const hostname = window.location.hostname;
    if (hostname.includes('prod')) {
      // 本番環境
      API_URL = 'https://simple-memo-app-backend-prod.azurewebsites.net';
      console.log('Notes service: Production environment detected, API URL:', API_URL);
    } else if (hostname.includes('dev')) {
      // 開発環境
      API_URL = 'https://simple-memo-app-backend-dev.azurewebsites.net';
      console.log('Notes service: Development environment detected, API URL:', API_URL);
    }
  } catch (error) {
    console.error('Error detecting environment:', error);
  }
};

// クライアントサイドでのみ実行
if (typeof window !== 'undefined') {
  // 非同期で環境検出を実行（エラーが発生してもアプリは動作する）
  setTimeout(detectEnvironment, 0);
}

// メモ一覧を取得
export const getNotes = async (): Promise<Note[]> => {
  try {
    const response: AxiosResponse<Note[]> = await axios.get(`${API_URL}/notes/`, {
      headers: authHeader(),
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching notes:', error);
    throw error;
  }
};

// メモを作成
export const createNote = async (title: string, content: string): Promise<Note> => {
  try {
    const response: AxiosResponse<Note> = await axios.post<Note>(
      `${API_URL}/notes/`,
      { title, content },
      {
        headers: authHeader(),
      }
    );
    return response.data;
  } catch (error) {
    console.error('Error creating note:', error);
    throw error;
  }
};

// メモを削除
export const deleteNote = async (noteId: number): Promise<void> => {
  try {
    await axios.delete(`${API_URL}/notes/${noteId}`, {
      headers: authHeader(),
    });
  } catch (error) {
    console.error('Error deleting note:', error);
    throw error;
  }
};