import { Component, ElementRef, ViewChild, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './forgot-password.component.html'
})
export class ForgotPasswordComponent {
  private readonly auth = inject(AuthService);

  @ViewChild('pageTitle', { static: true }) pageTitle?: ElementRef<HTMLElement>;

  isSubmitting = false;
  serverError: string | null = null;
  successMessage: string | null = null;

  form = new FormGroup({
    email: new FormControl<string>('', {
      nonNullable: true,
      validators: [Validators.required, Validators.email]
    })
  });

  ngAfterViewInit(): void {
    this.pageTitle?.nativeElement?.focus();
  }

  onSubmit(): void {
    this.serverError = null;
    this.successMessage = null;

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.isSubmitting = true;
    const payload = this.form.getRawValue();

    this.auth.forgotPassword(payload).subscribe({
      next: (res) => {
        this.isSubmitting = false;
        this.successMessage = res?.message || 'If the email exists, a reset link has been sent.';
      },
      error: (e: Error) => {
        this.isSubmitting = false;
        this.serverError = e.message || 'Request failed.';
      }
    });
  }

  fieldError(): string | null {
    const c = this.form.controls.email;
    if (!c.touched && !c.dirty) return null;
    if (c.hasError('required')) return 'Email is required.';
    if (c.hasError('email')) return 'Enter a valid email address.';
    return null;
  }
}
