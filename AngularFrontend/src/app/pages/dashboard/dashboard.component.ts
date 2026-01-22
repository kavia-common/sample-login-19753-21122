import { Component, ElementRef, ViewChild, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html'
})
export class DashboardComponent {
  private readonly auth = inject(AuthService);

  @ViewChild('pageTitle', { static: true }) pageTitle?: ElementRef<HTMLElement>;

  loading = true;
  error: string | null = null;
  userData: Record<string, unknown> | null = null;

  ngOnInit(): void {
    this.load();
  }

  ngAfterViewInit(): void {
    this.pageTitle?.nativeElement?.focus();
  }

  load(): void {
    this.loading = true;
    this.error = null;

    this.auth.getDashboard().subscribe({
      next: (res) => {
        this.loading = false;
        this.userData = (res?.userData || {}) as Record<string, unknown>;
      },
      error: (e: Error) => {
        this.loading = false;
        this.error = e.message || 'Failed to load dashboard.';
      }
    });
  }
}
