import { Component, inject } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { AsyncPipe, CommonModule } from '@angular/common';
import { AuthService } from './core/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, AsyncPipe],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  loggedIn$ = this.auth.loggedIn$;

  isLoggingOut = false;
  logoutError: string | null = null;

  onLogout(): void {
    this.logoutError = null;
    this.isLoggingOut = true;

    this.auth.logout().subscribe({
      next: () => {
        this.isLoggingOut = false;
        this.router.navigateByUrl('/login');
      },
      error: (e: Error) => {
        this.isLoggingOut = false;
        // Still navigated token cleared; show message briefly.
        this.logoutError = e.message || 'Logout failed.';
        this.router.navigateByUrl('/login');
      }
    });
  }
}
