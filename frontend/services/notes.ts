import axios, { AxiosResponse } from 'axios';
import { authHeader } from './auth';
import { Note, NoteInput } from '../types';

const API_URL = 'http://localhost:8000';

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