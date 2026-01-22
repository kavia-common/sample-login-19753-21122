export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  /** Token expiration in seconds */
  expiresIn: number;
}

export interface ForgotPasswordRequest {
  email: string;
}

export interface ForgotPasswordResponse {
  message: string;
}

export interface ResetPasswordRequest {
  token: string;
  newPassword: string;
}

export interface ResetPasswordResponse {
  message: string;
}

export interface LogoutResponse {
  message: string;
}

export interface DashboardResponse {
  userData: Record<string, unknown>;
}

export interface ErrorResponse {
  error?: {
    code?: string;
    message?: string;
  };
  status?: number;
}
