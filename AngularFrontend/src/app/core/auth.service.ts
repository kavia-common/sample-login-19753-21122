import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, catchError, map, tap, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import type {
  DashboardResponse,
  ErrorResponse,
  ForgotPasswordRequest,
  ForgotPasswordResponse,
  LoginRequest,
  LoginResponse,
  LogoutResponse,
  ResetPasswordRequest,
  ResetPasswordResponse
} from './api-types';

const TOKEN_STORAGE_KEY = 'sample_login_jwt';

/**
 * Convert an unknown HTTP error into a typed ErrorResponse shape.
 */
function toErrorResponse(err: unknown): ErrorResponse {
  const anyErr = err as any;
  const status: number | undefined = typeof anyErr?.status === 'number' ? anyErr.status : undefined;

  const apiError = anyErr?.error;
  if (apiError && typeof apiError === 'object' && ('error' in apiError || 'status' in apiError)) {
    return {
      status: typeof apiError.status === 'number' ? apiError.status : status,
      error: apiError.error && typeof apiError.error === 'object'
        ? {
            code: typeof apiError.error.code === 'string' ? apiError.error.code : undefined,
            message: typeof apiError.error.message === 'string' ? apiError.error.message : undefined
          }
        : undefined
    };
  }

  return {
    status,
    error: {
      code: 'UNKNOWN_ERROR',
      message: typeof anyErr?.message === 'string' ? anyErr.message : 'Unexpected error occurred.'
    }
  };
}

/**
 * Produce a user-friendly message from ErrorResponse.
 */
function errorMessageFrom(err: ErrorResponse): string {
  return err?.error?.message || `Request failed${err?.status ? ` (status ${err.status})` : ''}.`;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private tokenInMemory: string | null = null;
  private readonly loggedInSubject = new BehaviorSubject<boolean>(this.hasToken());

  /** PUBLIC_INTERFACE */
  readonly loggedIn$: Observable<boolean> = this.loggedInSubject.asObservable();

  constructor(private readonly http: HttpClient) {
    // Initialize in-memory token from localStorage (if present).
    const stored = this.readTokenFromStorage();
    if (stored) {
      this.tokenInMemory = stored;
      this.loggedInSubject.next(true);
    }
  }

  /** PUBLIC_INTERFACE */
  login(payload: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(this.apiUrl('/auth/login'), payload).pipe(
      tap((res) => {
        if (res?.token) {
          this.setToken(res.token);
        }
      }),
      catchError((err) => {
        const er = toErrorResponse(err);
        return throwError(() => new Error(errorMessageFrom(er)));
      })
    );
  }

  /** PUBLIC_INTERFACE */
  forgotPassword(payload: ForgotPasswordRequest): Observable<ForgotPasswordResponse> {
    return this.http.post<ForgotPasswordResponse>(this.apiUrl('/auth/forgot-password'), payload).pipe(
      catchError((err) => {
        const er = toErrorResponse(err);
        return throwError(() => new Error(errorMessageFrom(er)));
      })
    );
  }

  /** PUBLIC_INTERFACE */
  resetPassword(payload: ResetPasswordRequest): Observable<ResetPasswordResponse> {
    return this.http.post<ResetPasswordResponse>(this.apiUrl('/auth/reset-password'), payload).pipe(
      catchError((err) => {
        const er = toErrorResponse(err);
        return throwError(() => new Error(errorMessageFrom(er)));
      })
    );
  }

  /** PUBLIC_INTERFACE */
  logout(): Observable<LogoutResponse> {
    // Call backend to invalidate token (best-effort) then clear local auth state.
    return this.http.post<LogoutResponse>(this.apiUrl('/auth/logout'), {}).pipe(
      tap(() => this.clearToken()),
      catchError((err) => {
        // Even if backend rejects, clear local token to log out from UI.
        this.clearToken();
        const er = toErrorResponse(err);
        return throwError(() => new Error(errorMessageFrom(er)));
      })
    );
  }

  /** PUBLIC_INTERFACE */
  getDashboard(): Observable<DashboardResponse> {
    return this.http.get<DashboardResponse>(this.apiUrl('/dashboard')).pipe(
      catchError((err) => {
        const er = toErrorResponse(err);
        return throwError(() => new Error(errorMessageFrom(er)));
      })
    );
  }

  /** PUBLIC_INTERFACE */
  getToken(): string | null {
    return this.tokenInMemory ?? this.readTokenFromStorage();
  }

  /** PUBLIC_INTERFACE */
  isLoggedIn(): boolean {
    return this.hasToken();
  }

  private apiUrl(path: string): string {
    const base = environment.apiBaseUrl.replace(/\/+$/, '');
    const p = path.startsWith('/') ? path : `/${path}`;
    return `${base}${p}`;
  }

  private setToken(token: string): void {
    this.tokenInMemory = token;
    try {
      localStorage.setItem(TOKEN_STORAGE_KEY, token);
    } catch {
      // ignore storage errors (private mode, etc.)
    }
    this.loggedInSubject.next(true);
  }

  private clearToken(): void {
    this.tokenInMemory = null;
    try {
      localStorage.removeItem(TOKEN_STORAGE_KEY);
    } catch {
      // ignore storage errors
    }
    this.loggedInSubject.next(false);
  }

  private readTokenFromStorage(): string | null {
    try {
      return localStorage.getItem(TOKEN_STORAGE_KEY);
    } catch {
      return null;
    }
  }

  private hasToken(): boolean {
    return !!(this.tokenInMemory ?? this.readTokenFromStorage());
  }
}
