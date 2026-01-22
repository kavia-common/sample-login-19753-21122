import { Component, ElementRef, ViewChild, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  AbstractControl,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  ValidationErrors,
  Validators
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';

function passwordsMatchValidator(group: AbstractControl): ValidationErrors | null {
  const g = group as FormGroup;
  const newPassword = g.get('newPassword')?.value;
  const confirmPassword = g.get('confirmPassword')?.value;
  if (!newPassword || !confirmPassword) return null;
  return newPassword === confirmPassword ? null : { passwordsMismatch: true };
}

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './reset-password.component.html'
})
export class ResetPasswordComponent {
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  @ViewChild('pageTitle', { static: true }) pageTitle?: ElementRef<HTMLElement>;

  token: string | null = null;

  isSubmitting = false;
  serverError: string | null = null;
  successMessage: string | null = null;

  form = new FormGroup(
    {
      newPassword: new FormControl<string>('', {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(8), Validators.maxLength(128)]
      }),
      confirmPassword: new FormControl<string>('', {
        nonNullable: true,
        validators: [Validators.required]
      })
    },
    { validators: [passwordsMatchValidator] }
  );

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParamMap.get('token');
  }

  ngAfterViewInit(): void {
    this.pageTitle?.nativeElement?.focus();
  }

  onSubmit(): void {
    this.serverError = null;
    this.successMessage = null;

    if (!this.token) {
      this.serverError = 'Reset token is missing. Please use the link from your email.';
      return;
    }

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.isSubmitting = true;
    const { newPassword } = this.form.getRawValue();

    this.auth.resetPassword({ token: this.token, newPassword }).subscribe({
      next: (res) => {
        this.isSubmitting = false;
        this.successMessage = res?.message || 'Password reset successful. You can now sign in.';
        // Redirect to login after a short delay for usability.
        setTimeout(() => this.router.navigateByUrl('/login'), 800);
      },
      error: (e: Error) => {
        this.isSubmitting = false;
        this.serverError = e.message || 'Reset failed.';
      }
    });
  }

  newPasswordError(): string | null {
    const c = this.form.controls.newPassword;
    if (!c.touched && !c.dirty) return null;
    if (c.hasError('required')) return 'New password is required.';
    if (c.hasError('minlength')) return 'Must be at least 8 characters.';
    if (c.hasError('maxlength')) return 'Must be at most 128 characters.';
    return null;
  }

  confirmPasswordError(): string | null {
    const c = this.form.controls.confirmPassword;
    if (!c.touched && !c.dirty) return null;
    if (c.hasError('required')) return 'Please confirm your new password.';
    if (this.form.hasError('passwordsMismatch')) return 'Passwords do not match.';
    return null;
  }
}
