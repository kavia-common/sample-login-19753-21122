import { Component, ElementRef, ViewChild, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './login.component.html'
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  @ViewChild('pageTitle', { static: true }) pageTitle?: ElementRef<HTMLElement>;

  isSubmitting = false;
  serverError: string | null = null;

  form = new FormGroup({
    username: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(3), Validators.maxLength(64)]
    }),
    password: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(8), Validators.maxLength(128)]
    })
  });

  ngAfterViewInit(): void {
    // Focus the heading so screen reader users land at a clear point.
    this.pageTitle?.nativeElement?.focus();
  }

  onSubmit(): void {
    this.serverError = null;

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.isSubmitting = true;
    const payload = this.form.getRawValue();

    this.auth.login(payload).subscribe({
      next: () => {
        this.isSubmitting = false;
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl') || '/dashboard';
        this.router.navigateByUrl(returnUrl);
      },
      error: (e: Error) => {
        this.isSubmitting = false;
        this.serverError = e.message || 'Login failed.';
      }
    });
  }

  fieldError(id: 'username' | 'password'): string | null {
    const c = this.form.controls[id];
    if (!c.touched && !c.dirty) return null;
    if (c.hasError('required')) return 'This field is required.';
    if (c.hasError('minlength')) {
      const min = id === 'username' ? 3 : 8;
      return `Must be at least ${min} characters.`;
    }
    if (c.hasError('maxlength')) {
      const max = id === 'username' ? 64 : 128;
      return `Must be at most ${max} characters.`;
    }
    return null;
  }
}
