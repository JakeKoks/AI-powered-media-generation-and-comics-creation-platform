import { test, expect } from '@playwright/test';

test.describe('AI Comics Website - E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the application
    await page.goto('http://localhost:3000');
  });

  test('should load the homepage', async ({ page }) => {
    // Check if the page loads
    await expect(page).toHaveTitle(/AI Media & Comics/);
    
    // Check for main navigation elements
    await expect(page.locator('header')).toBeVisible();
    await expect(page.locator('main')).toBeVisible();
  });

  test('should navigate to authentication pages', async ({ page }) => {
    // Test navigation to login page
    await page.click('text=Login');
    await expect(page).toHaveURL(/.*\/auth\/login/);
    
    // Test navigation to register page
    await page.click('text=Register');
    await expect(page).toHaveURL(/.*\/auth\/register/);
  });

  test('should show error for invalid login', async ({ page }) => {
    // Navigate to login
    await page.goto('http://localhost:3000/auth/login');
    
    // Fill invalid credentials
    await page.fill('[data-testid=email-input]', 'invalid@example.com');
    await page.fill('[data-testid=password-input]', 'wrongpassword');
    await page.click('[data-testid=login-button]');
    
    // Check for error message
    await expect(page.locator('[data-testid=error-message]')).toBeVisible();
  });

  test('should access admin panel with admin role', async ({ page }) => {
    // This test would require a test admin user to be seeded
    // For now, just check that admin route is protected
    await page.goto('http://localhost:3000/admin');
    
    // Should redirect to login if not authenticated
    await expect(page).toHaveURL(/.*\/auth\/login/);
  });
});

test.describe('API Health Checks', () => {
  test('backend API should be healthy', async ({ request }) => {
    const response = await request.get('http://localhost:4000/health');
    expect(response.ok()).toBeTruthy();
    
    const health = await response.json();
    expect(health.status).toBe('healthy');
  });

  test('database connection should work', async ({ request }) => {
    const response = await request.get('http://localhost:4000/health/db');
    expect(response.ok()).toBeTruthy();
  });

  test('redis connection should work', async ({ request }) => {
    const response = await request.get('http://localhost:4000/health/redis');
    expect(response.ok()).toBeTruthy();
  });
});
