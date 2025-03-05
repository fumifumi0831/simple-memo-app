import axios from 'axios';
import { authHeader } from './auth';

const API_URL = 'http://localhost:8000';

// メモ一覧を取得
export const getNotes = async () => {
  try {
    const response = await axios.get(`${API_URL}/notes/`, {
      headers: authHeader(),
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching notes:', error);
    throw error;
  }
};

// メモを作成
export const createNote = async (title, content) => {
  try {
    const response = await axios.post(
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
export const deleteNote = async (noteId) => {
  try {
    await axios.delete(`${API_URL}/notes/${noteId}`, {
      headers: authHeader(),
    });
  } catch (error) {
    console.error('Error deleting note:', error);
    throw error;
  }
};