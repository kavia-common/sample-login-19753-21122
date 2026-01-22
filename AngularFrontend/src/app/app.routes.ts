import { Routes } from '@angular/router';
import { authGuard } from './core/auth.guard';
import { AuthService } from './core/auth.service';
import { inject } from '@angular/core';
import { Router } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    pathMatch: 'full',
    redirectTo: 'login'
  },
  {
    path: 'login',
    loadComponent: () => import('./pages/login/login.component').then((m) => m.LoginComponent),
    title: 'Login'
  },
  {
    path: 'forgot-password',
    loadComponent: () =>
      import('./pages/forgot-password/forgot-password.component').then((m) => m.ForgotPasswordComponent),
    title: 'Forgot Password'
  },
  {
    path: 'reset-password',
    loadComponent: () =>
      import('./pages/reset-password/reset-password.component').then((m) => m.ResetPasswordComponent),
    title: 'Reset Password'
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    loadComponent: () => import('./pages/dashboard/dashboard.component').then((m) => m.DashboardComponent),
    title: 'Dashboard'
  },
  // Convenience: if user hits /, send them where they should go based on auth state.
  {
    path: 'home',
    resolve: [],
    canActivate: [
      () => {
        const auth = inject(AuthService);
        const router = inject(Router);
        return router.createUrlTree([auth.isLoggedIn() ? '/dashboard' : '/login']);
      }
    ],
    loadComponent: () => import('./pages/login/login.component').then((m) => m.LoginComponent)
  },
  {
    path: '**',
    redirectTo: 'login'
  }
];
