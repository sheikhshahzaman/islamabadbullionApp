<?php
// metal/admin/login.php
session_start();
require_once __DIR__ . '/../includes/auth.php';

// CSRF token generation
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

$err = '';
$username = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // CSRF validation
    if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
        $err = 'Security validation failed. Please try again.';
    } else {
        $username = trim($_POST['username'] ?? '');
        $password = trim($_POST['password'] ?? '');
        
        // Basic rate limiting
        if (!isset($_SESSION['login_attempts'])) {
            $_SESSION['login_attempts'] = 0;
            $_SESSION['last_attempt_time'] = time();
        }
        
        // Check if too many attempts
        if ($_SESSION['login_attempts'] >= 5) {
            $time_since = time() - $_SESSION['last_attempt_time'];
            if ($time_since < 300) { // 5 minutes lockout
                $err = 'Too many login attempts. Please try again in ' . (300 - $time_since) . ' seconds.';
            } else {
                $_SESSION['login_attempts'] = 0;
            }
        }
        
        if (!$err && $username !== '' && $password !== '' && adminLogin($username, $password)) {
            // Reset attempts on successful login
            $_SESSION['login_attempts'] = 0;
            header('Location: /metal/admin/index.php');
            exit;
        } elseif (!$err) {
            $_SESSION['login_attempts']++;
            $_SESSION['last_attempt_time'] = time();
            $err = 'Invalid username or password';
            // Don't reveal whether username exists
            $username = ''; // Clear for security
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard | Secure Login</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --shadow-lg: 0 20px 40px rgba(0, 0, 0, 0.1);
            --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        body {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            padding: 1rem;
        }
        
        .login-container {
            background: white;
            border-radius: 24px;
            box-shadow: var(--shadow-lg);
            padding: 3rem 2rem;
            width: 100%;
            max-width: 420px;
            margin: 0 auto;
            position: relative;
            overflow: hidden;
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 2.5rem;
            position: relative;
        }
        
        .login-header::after {
            content: '';
            position: absolute;
            bottom: -15px;
            left: 50%;
            transform: translateX(-50%);
            width: 60px;
            height: 4px;
            background: var(--primary-gradient);
            border-radius: 2px;
        }
        
        .logo {
            background: var(--primary-gradient);
            color: white;
            width: 60px;
            height: 60px;
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            font-size: 1.8rem;
            font-weight: 700;
        }
        
        .form-group {
            margin-bottom: 1.75rem;
            position: relative;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: #2d3748;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .form-group input {
            width: 100%;
            padding: 0.875rem 1rem;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            font-size: 1rem;
            transition: var(--transition);
            background: #f8fafc;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            background: white;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .password-toggle {
            position: absolute;
            right: 1rem;
            top: 2.6rem;
            background: none;
            border: none;
            color: #718096;
            cursor: pointer;
            font-size: 0.9rem;
            padding: 0.25rem;
        }
        
        .btn-login {
            background: var(--primary-gradient);
            color: white;
            border: none;
            padding: 1rem 2rem;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            width: 100%;
            cursor: pointer;
            transition: var(--transition);
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }
        
        .btn-login:active {
            transform: translateY(0);
        }
        
        .alert {
            padding: 1rem;
            border-radius: 12px;
            margin-bottom: 1.5rem;
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }
        
        .alert-error {
            background: #fed7d7;
            color: #9b2c2c;
            border-left: 4px solid #e53e3e;
        }
        
        .alert-info {
            background: #bee3f8;
            color: #2c5282;
            border-left: 4px solid #3182ce;
            font-size: 0.875rem;
            margin-top: 1.5rem;
        }
        
        .footer-links {
            display: flex;
            justify-content: center;
            gap: 1.5rem;
            margin-top: 2rem;
            padding-top: 2rem;
            border-top: 1px solid #e2e8f0;
        }
        
        .footer-links a {
            color: #718096;
            text-decoration: none;
            font-size: 0.875rem;
            transition: color 0.2s;
        }
        
        .footer-links a:hover {
            color: #667eea;
        }
        
        @media (max-width: 480px) {
            .login-container {
                padding: 2rem 1.5rem;
                border-radius: 20px;
            }
            
            .footer-links {
                flex-direction: column;
                gap: 0.75rem;
                text-align: center;
            }
        }
        
        /* Loading animation */
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            margin-right: 8px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-header">
            <h1 style="margin-bottom: 0.5rem; color: #2d3748;">Admin Portal</h1>
            <p style="color: #718096; font-size: 0.95rem;">Secure access to dashboard</p>
        </div>
        
        <?php if ($err): ?>
            <div class="alert alert-error">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
                <?= htmlspecialchars($err) ?>
            </div>
        <?php endif; ?>
        
        <form method="post" autocomplete="off" id="loginForm">
            <input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">
            
            <div class="form-group">
                <label for="username">Username</label>
                <input 
                    type="text" 
                    id="username" 
                    name="username" 
                    value="<?= htmlspecialchars($username) ?>" 
                    required 
                    placeholder="Enter admin username"
                    autofocus
                >
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input 
                    type="password" 
                    id="password" 
                    name="password" 
                    required 
                    placeholder="Enter your password"
                >
                <button type="button" class="password-toggle" id="togglePassword">
                    👁️
                </button>
            </div>
            
            <button type="submit" class="btn-login" id="submitBtn">
                <span id="btnText">Sign In</span>
                <span id="btnLoader" style="display: none;">
                    <span class="loading"></span> Authenticating...
                </span>
            </button>
        </form>
        
        
    </div>

    <script>
        // Toggle password visibility
        document.getElementById('togglePassword').addEventListener('click', function() {
            const passwordInput = document.getElementById('password');
            const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
            passwordInput.setAttribute('type', type);
            this.textContent = type === 'password' ? '👁️' : '🔒';
        });
        
        // Form submission with loading state
        document.getElementById('loginForm').addEventListener('submit', function() {
            const btnText = document.getElementById('btnText');
            const btnLoader = document.getElementById('btnLoader');
            const submitBtn = document.getElementById('submitBtn');
            
            btnText.style.display = 'none';
            btnLoader.style.display = 'inline';
            submitBtn.disabled = true;
        });
        
        // Auto-focus username field on page load
        document.getElementById('username').focus();
        
        // Add subtle animation on load
        document.addEventListener('DOMContentLoaded', function() {
            const container = document.querySelector('.login-container');
            container.style.opacity = '0';
            container.style.transform = 'translateY(20px)';
            
            setTimeout(() => {
                container.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
                container.style.opacity = '1';
                container.style.transform = 'translateY(0)';
            }, 100);
        });
    </script>
</body>
</html>