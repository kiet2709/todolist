// src/utils/axiosClient.js
import axios from 'axios';

/**
 * BASE_URL:
 * - Ưu tiên VITE_API_BASE_URL
 * - Fallback về <origin>/api cho tiện dev (VD: http://localhost:5173 -> http://localhost:5173/api)
 */
const BASE_URL =
  (import.meta?.env?.VITE_API_BASE_URL && String(import.meta.env.VITE_API_BASE_URL).trim()) ||
  (typeof window !== 'undefined' ? `${window.location.origin}/api` : 'http://localhost:3000/api');

// Khóa lưu trữ token trong localStorage (để bạn dùng lại sau này khi làm login)
const STORAGE_KEYS = {
  accessToken: 'accessToken',
  refreshToken: 'refreshToken', // chừa sẵn cho tương lai nếu bạn muốn dùng refresh token
};

// ====== Helpers cho auth storage ======
const getAccessToken = () => {
  try {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(STORAGE_KEYS.accessToken);
  } catch {
    return null;
  }
};

const setAccessToken = (token) => {
  try {
    if (typeof window !== 'undefined') {
      if (token) localStorage.setItem(STORAGE_KEYS.accessToken, token);
      else localStorage.removeItem(STORAGE_KEYS.accessToken);
    }
  } catch {}
};

const clearAuth = () => {
  try {
    if (typeof window !== 'undefined') {
      localStorage.removeItem(STORAGE_KEYS.accessToken);
      localStorage.removeItem(STORAGE_KEYS.refreshToken);
    }
  } catch {}
};

// Điều hướng về trang login, có gắn ?next= để quay lại trang trước đó
const redirectToLogin = (preserveCurrent = true) => {
  if (typeof window === 'undefined') return;
  const currentPath = window.location.pathname + window.location.search + window.location.hash;
  const next = preserveCurrent ? `?next=${encodeURIComponent(currentPath)}` : '';

  // Dùng dynamic import để tránh vòng lặp phụ thuộc
  import('@/router')
    .then(({ default: router }) => {
      const target = `/login${next}`;
      // Tránh push lại cùng route
      const curPath = router?.currentRoute?.value?.fullPath || router?.currentRoute?.value?.path;
      if (curPath !== target) router.push(target);
    })
    .catch(() => {
      // Fallback nếu chưa có router
      window.location.href = `/login${next}`;
    });
};

// ====== Khởi tạo axios instance ======
const client = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  },
  timeout: 15000,
  withCredentials: false, // Nếu bạn dùng cookie, chỉnh true
});

// ====== Request Interceptor ======
// - Tự động gắn Bearer token nếu có
client.interceptors.request.use(
  (config) => {
    const token = getAccessToken();
    if (token) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// ====== Response Interceptor ======
// - KHÔNG refresh token vào lúc này (theo yêu cầu).
// - Nếu token hết hạn/không hợp lệ -> xóa token & chuyển về /login
client.interceptors.response.use(
  (response) => response,
  async (error) => {
    const status = error?.response?.status;
    const data = error?.response?.data;
    const message = String(data?.message || data?.error || '').toLowerCase();
    const originalRequest = error?.config || {};

    // Nếu đang ở trang login hoặc gọi endpoint login -> không redirect vòng lặp
    const isLoginPath =
      (typeof window !== 'undefined' && window.location.pathname.includes('/login')) ||
      /\/auth\/login/i.test(originalRequest?.url || '');

    if (isLoginPath) {
      return Promise.reject(error);
    }

    // Các tình huống coi như token hỏng/hết hạn
    const isTokenProblem =
      status === 401 ||
      status === 403 ||
      (status === 400 && (message.includes('expired') || message.includes('invalid'))) ||
      (status >= 500 && message.includes('token'));

    if (isTokenProblem) {
      clearAuth();
      redirectToLogin(true);
      return Promise.reject(error);
    }

    // Các lỗi mạng/timeout hoặc HTTP khác -> trả về cho phần gọi xử lý
    return Promise.reject(error);
  }
);

// ====== Exports ======
export const authStorage = { getAccessToken, setAccessToken, clearAuth };
export { client as axiosClient };
export default client;
