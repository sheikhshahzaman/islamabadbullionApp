<?php
// metal/admin/index.php
require_once __DIR__ . '/../includes/auth.php';
requireAdminLogin();
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard - Metal Admin</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    :root {
      --primary: #2563eb;
      --primary-dark: #1d4ed8;
      --primary-light: #dbeafe;
      --secondary: #64748b;
      --accent: #0ea5e9;
      --background: #f8fafc;
      --surface: #ffffff;
      --sidebar: #1e293b;
      --sidebar-hover: #334155;
      --sidebar-active: #2563eb;
      --border: #e2e8f0;
      --text: #1e293b;
      --text-light: #64748b;
      --text-sidebar: #cbd5e1;
      --radius: 8px;
      --radius-lg: 12px;
      --shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.05);
      --sidebar-width: 280px;
      --sidebar-collapsed: 80px;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background-color: var(--background);
      color: var(--text);
      line-height: 1.6;
      min-height: 100vh;
      overflow-x: hidden;
    }

    /* Modern Sidebar */
    .sidebar {
      position: fixed;
      left: 0;
      top: 0;
      width: var(--sidebar-width);
      height: 100vh;
      background: var(--sidebar);
      color: var(--text-sidebar);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      z-index: 1000;
      display: flex;
      flex-direction: column;
      box-shadow: 4px 0 20px rgba(0, 0, 0, 0.1);
      overflow: hidden;
    }

    .sidebar-header {
      padding: 1.75rem 1.5rem;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      margin-bottom: 1rem;
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .logo {
      display: flex;
      align-items: center;
      gap: 0.875rem;
      text-decoration: none;
      transition: all 0.3s ease;
    }

    .logo-icon {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, var(--primary), var(--accent));
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-size: 1.25rem;
      flex-shrink: 0;
    }

    .logo-text {
      display: flex;
      flex-direction: column;
      overflow: hidden;
      transition: all 0.3s ease;
    }

    .logo-main {
      font-size: 1.25rem;
      font-weight: 700;
      color: white;
      line-height: 1.2;
    }

    .logo-sub {
      font-size: 0.75rem;
      color: rgba(255, 255, 255, 0.7);
      font-weight: 400;
    }

    .sidebar-nav {
      flex: 1;
      padding: 0.5rem;
      overflow-y: auto;
      scrollbar-width: thin;
      scrollbar-color: rgba(255, 255, 255, 0.1) transparent;
    }

    .sidebar-nav::-webkit-scrollbar {
      width: 4px;
    }

    .sidebar-nav::-webkit-scrollbar-track {
      background: transparent;
    }

    .sidebar-nav::-webkit-scrollbar-thumb {
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
    }

    .nav-section {
      margin-bottom: 2rem;
    }

    .nav-title {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.1em;
      color: rgba(255, 255, 255, 0.5);
      margin-bottom: 1rem;
      padding: 0 1rem;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .nav-list {
      list-style: none;
    }

    .nav-item {
      margin-bottom: 0.375rem;
    }

    .nav-link {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 0.875rem 1rem;
      text-decoration: none;
      color: var(--text-sidebar);
      border-radius: var(--radius);
      transition: all 0.2s ease;
      font-weight: 500;
      position: relative;
      overflow: hidden;
    }

    .nav-link:hover {
      background: var(--sidebar-hover);
      color: white;
      transform: translateX(4px);
    }

    .nav-link.active {
      background: linear-gradient(90deg, rgba(37, 99, 235, 0.15), rgba(37, 99, 235, 0.05));
      color: white;
      font-weight: 600;
    }

    .nav-link.active::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 4px;
      background: var(--primary);
      border-radius: 0 4px 4px 0;
    }

    .nav-icon {
      width: 20px;
      height: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 1.125rem;
      color: inherit;
    }

    .nav-text {
      flex: 1;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      transition: all 0.3s ease;
    }

    .nav-badge {
      background: rgba(255, 255, 255, 0.1);
      color: white;
      font-size: 0.7rem;
      padding: 0.125rem 0.5rem;
      border-radius: 12px;
      margin-left: auto;
    }

    .sidebar-footer {
      padding: 1.5rem;
      border-top: 1px solid rgba(255, 255, 255, 0.1);
      margin-top: auto;
    }

    .user-profile {
      display: flex;
      align-items: center;
      gap: 0.875rem;
      padding: 0.75rem;
      border-radius: var(--radius);
      transition: all 0.2s ease;
    }

    .user-profile:hover {
      background: var(--sidebar-hover);
    }

    .user-avatar {
      width: 40px;
      height: 40px;
      background: linear-gradient(135deg, #667eea, #764ba2);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 600;
      flex-shrink: 0;
      font-size: 1rem;
    }

    .user-info {
      flex: 1;
      overflow: hidden;
    }

    .user-name {
      font-weight: 600;
      color: white;
      font-size: 0.875rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .user-role {
      font-size: 0.75rem;
      color: rgba(255, 255, 255, 0.6);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .sidebar-toggle {
      position: absolute;
      right: -12px;
      top: 1.5rem;
      width: 24px;
      height: 24px;
      background: white;
      border: 2px solid var(--border);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      color: var(--text);
      font-size: 0.75rem;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      z-index: 1001;
      transition: all 0.3s ease;
    }

    .sidebar-toggle:hover {
      background: var(--primary);
      color: white;
      border-color: var(--primary);
      transform: scale(1.1);
    }

    /* Collapsed Sidebar */
    .sidebar.collapsed {
      width: var(--sidebar-collapsed);
    }

    .sidebar.collapsed .logo-text,
    .sidebar.collapsed .nav-text,
    .sidebar.collapsed .nav-badge,
    .sidebar.collapsed .user-info,
    .sidebar.collapsed .nav-title span,
    .sidebar.collapsed .logo-sub {
      display: none;
    }

    .sidebar.collapsed .nav-title {
      justify-content: center;
      padding: 0;
    }

    .sidebar.collapsed .nav-link {
      justify-content: center;
      padding: 0.875rem;
    }

    .sidebar.collapsed .nav-link:hover .nav-text {
      display: block;
      position: absolute;
      left: calc(100% + 12px);
      background: var(--sidebar);
      padding: 0.5rem 1rem;
      border-radius: var(--radius);
      white-space: nowrap;
      z-index: 1000;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .sidebar.collapsed .user-profile {
      justify-content: center;
      padding: 0.5rem;
    }

    .sidebar.collapsed .sidebar-toggle {
      transform: rotate(180deg);
    }

    /* Main Content Area */
    .main-content {
      margin-left: var(--sidebar-width);
      min-height: 100vh;
      transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .sidebar.collapsed ~ .main-content {
      margin-left: var(--sidebar-collapsed);
    }

    /* Header */
    .admin-header {
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 100;
      padding: 1rem 2rem;
      box-shadow: var(--shadow);
    }

    .header-content {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .page-title h1 {
      font-size: 1.5rem;
      font-weight: 700;
      color: var(--text);
      margin-bottom: 0.25rem;
    }

    .page-title p {
      color: var(--text-light);
      font-size: 0.875rem;
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .logout-btn {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.625rem 1.25rem;
      background: #fef2f2;
      color: #dc2626;
      border: 1px solid #fecaca;
      border-radius: var(--radius);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 500;
      transition: all 0.2s ease;
    }

    .logout-btn:hover {
      background: #dc2626;
      color: white;
      transform: translateY(-1px);
    }

    /* Content Area */
    .content-container {
      padding: 2rem;
    }

    /* Cards Grid */
    .cards-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 1.5rem;
      margin-bottom: 2rem;
    }

    .card {
      background: var(--surface);
      border-radius: var(--radius-lg);
      padding: 1.75rem;
      box-shadow: var(--shadow);
      transition: all 0.3s ease;
      border: 1px solid var(--border);
      position: relative;
      overflow: hidden;
    }

    .card::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 4px;
      background: linear-gradient(90deg, var(--primary), var(--accent));
    }

    .card:hover {
      transform: translateY(-4px);
      box-shadow: var(--shadow-lg);
      border-color: var(--primary-light);
    }

    .card-header {
      display: flex;
      align-items: start;
      justify-content: space-between;
      margin-bottom: 1.25rem;
    }

    .card-icon {
      width: 56px;
      height: 56px;
      background: linear-gradient(135deg, var(--primary-light), #e0f2fe);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--primary);
      font-size: 1.5rem;
    }

    .card h3 {
      font-size: 1.125rem;
      font-weight: 600;
      margin-bottom: 0.75rem;
      color: var(--text);
    }

    .card p {
      color: var(--text-light);
      font-size: 0.875rem;
      line-height: 1.5;
      margin-bottom: 1.5rem;
    }

    .card-link {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      color: var(--primary);
      text-decoration: none;
      font-weight: 500;
      font-size: 0.875rem;
      transition: all 0.2s ease;
      padding: 0.5rem 0;
    }

    .card-link:hover {
      gap: 0.75rem;
      color: var(--primary-dark);
    }

    /* API Endpoint Card */
    .api-card {
      background: var(--surface);
      border-radius: var(--radius-lg);
      padding: 2rem;
      margin-bottom: 2rem;
      box-shadow: var(--shadow);
      border-left: 4px solid var(--primary);
      position: relative;
      overflow: hidden;
    }

    .api-card::after {
      content: '';
      position: absolute;
      top: 0;
      right: 0;
      width: 100px;
      height: 100px;
      background: linear-gradient(135deg, rgba(37, 99, 235, 0.05), transparent);
      border-radius: 0 0 0 100px;
    }

    .api-card h3 {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 1rem;
      display: flex;
      align-items: center;
      gap: 0.75rem;
      color: var(--text);
    }

    .api-card h3 i {
      color: var(--primary);
    }

    .api-description {
      color: var(--text-light);
      margin-bottom: 1.5rem;
      font-size: 0.875rem;
    }

    .api-code {
      background: #1e293b;
      color: #e2e8f0;
      padding: 1.5rem;
      border-radius: var(--radius);
      font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      font-size: 0.875rem;
      overflow-x: auto;
      margin: 1rem 0;
      border: 1px solid #334155;
      position: relative;
    }

    .api-code::before {
      content: 'URL';
      position: absolute;
      top: -10px;
      left: 16px;
      background: #1e293b;
      color: #94a3b8;
      padding: 0 8px;
      font-size: 0.75rem;
      font-weight: 500;
      border: 1px solid #334155;
      border-radius: 4px;
    }

    .api-tags {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-top: 1.5rem;
    }

    .api-tag {
      background: #f1f5f9;
      color: #475569;
      padding: 0.375rem 0.875rem;
      border-radius: 20px;
      font-size: 0.75rem;
      font-weight: 500;
      display: inline-flex;
      align-items: center;
      gap: 0.375rem;
    }

    .api-tag i {
      font-size: 0.625rem;
    }

    /* Quick Start */
    .quick-start {
      background: var(--surface);
      border-radius: var(--radius-lg);
      padding: 2rem;
      box-shadow: var(--shadow);
      position: relative;
      overflow: hidden;
    }

    .quick-start::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 4px;
      background: linear-gradient(90deg, var(--accent), #8b5cf6);
    }

    .quick-start h3 {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 1.5rem;
      display: flex;
      align-items: center;
      gap: 0.75rem;
      color: var(--text);
    }

    .steps {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
    }

    .step {
      background: #f8fafc;
      border-radius: var(--radius);
      padding: 1.5rem;
      border: 1px solid var(--border);
      position: relative;
      transition: all 0.2s ease;
    }

    .step:hover {
      transform: translateY(-2px);
      border-color: var(--primary-light);
      box-shadow: var(--shadow);
    }

    .step-number {
      width: 32px;
      height: 32px;
      background: var(--primary);
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 0.875rem;
      margin-bottom: 1rem;
    }

    .step h4 {
      font-size: 0.875rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: var(--text);
    }

    .step p {
      font-size: 0.8125rem;
      color: var(--text-light);
      line-height: 1.5;
    }

    /* Mobile Navigation */
    .mobile-toggle {
      display: none;
      background: var(--primary);
      color: white;
      border: none;
      border-radius: var(--radius);
      width: 40px;
      height: 40px;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 1.25rem;
    }

    /* Responsive Design */
    @media (max-width: 1024px) {
      .sidebar {
        transform: translateX(-100%);
      }

      .sidebar.active {
        transform: translateX(0);
      }

      .main-content {
        margin-left: 0 !important;
      }

      .mobile-toggle {
        display: flex;
      }

      .sidebar-toggle {
        display: none;
      }

      .overlay {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        z-index: 999;
      }

      .overlay.active {
        display: block;
      }
    }

    @media (max-width: 768px) {
      .content-container {
        padding: 1.5rem 1rem;
      }

      .cards-grid {
        grid-template-columns: 1fr;
      }

      .steps {
        grid-template-columns: 1fr;
      }

      .admin-header {
        padding: 1rem;
      }
    }

    /* Utility Classes */
    .text-sm {
      font-size: 0.875rem;
    }

    .text-xs {
      font-size: 0.75rem;
    }

    .font-medium {
      font-weight: 500;
    }

    .font-semibold {
      font-weight: 600;
    }

    .mt-4 {
      margin-top: 1rem;
    }

    .mb-4 {
      margin-bottom: 1rem;
    }
  </style>
</head>
<body>
  <!-- Overlay for mobile -->
  <div class="overlay" id="overlay"></div>

  <!-- Sidebar -->
  <aside class="sidebar" id="sidebar">
    <div class="sidebar-toggle" id="sidebarToggle">
      <i class="fas fa-chevron-left"></i>
    </div>

    <div class="sidebar-header">
      <a href="index.php" class="logo">
        <div class="logo-icon">
          <i class="fas fa-cog"></i>
        </div>
        <div class="logo-text">
          <div class="logo-main">Admin</div>
          <div class="logo-sub">Legacy Jewellers</div>
        </div>
      </a>
    </div>

    <nav class="sidebar-nav">
      <div class="nav-section">
        <div class="nav-title">
          <span>MAIN NAVIGATION</span>
        </div>
        <ul class="nav-list">
          <li class="nav-item">
            <a href="index.php" class="nav-link active">
              <div class="nav-icon">
                <i class="fas fa-chart-line"></i>
              </div>
              <span class="nav-text">Panel</span>
              <span class="nav-badge">Active</span>
            </a>
          </li>
          <!--<li class="nav-item">-->
          <!--  <a href="metals.php" class="nav-link">-->
          <!--    <div class="nav-icon">-->
          <!--      <i class="fas fa-weight-hanging"></i>-->
          <!--    </div>-->
          <!--    <span class="nav-text">Set Pricing</span>-->
          <!--  </a>-->
          <!--</li>-->
          <li class="nav-item">
            <a href="gold_karat_adjustments.php" class="nav-link">
              <div class="nav-icon">
                <i class="fas fa-weight-hanging"></i>
              </div>
              <span class="nav-text">Gold Pricing</span>
            </a>
          </li>
          <li class="nav-item">
            <a href="silver_quantity_adjustments.php" class="nav-link">
              <div class="nav-icon">
                <i class="fas fa-weight-hanging"></i>
              </div>
              <span class="nav-text">Silver Pricing</span>
            </a>
          </li>
          <li class="nav-item">
            <a href="headlines.php" class="nav-link">
              <div class="nav-icon">
                <i class="fas fa-bell"></i>
              </div>
              <span class="nav-text">Set Notification</span>
            </a>
          </li>
          <!--<li class="nav-item">-->
          <!--  <a href="settings.php" class="nav-link">-->
          <!--    <div class="nav-icon">-->
          <!--      <i class="fas fa-sliders-h"></i>-->
          <!--    </div>-->
          <!--    <span class="nav-text">Settings</span>-->
          <!--  </a>-->
          <!--</li>-->
        </ul>
      </div>

      <div class="nav-section">
        <div class="nav-title">
          <span>SYSTEM</span>
        </div>
        <ul class="nav-list">
          
          <li class="nav-item">
            <a href="logout.php" class="nav-link">
              <div class="nav-icon">
                <i class="fas fa-sign-out-alt"></i>
              </div>
              <span class="nav-text">Logout</span>
            </a>
          </li>
        </ul>
      </div>
    </nav>

    <div class="sidebar-footer">
      <div class="user-profile">
        <div class="user-avatar">A</div>
        <div class="user-info">
          <div class="user-name">Administrator</div>
          <div class="user-role">Super Admin</div>
        </div>
      </div>
    </div>
  </aside>

  <!-- Main Content -->
  <div class="main-content">
    <!-- Header -->
    <header class="admin-header">
      <div class="header-content">
        <div style="display: flex; align-items: center; gap: 1rem;">
          <button class="mobile-toggle" id="mobileToggle">
            <i class="fas fa-bars"></i>
          </button>
          <div class="page-title">
            <h1>Dashboard Overview</h1>
            <p>Welcome back!</p>
          </div>
        </div>
        
        <div class="header-actions">
          <div style="display: flex; align-items: center; gap: 1rem;">
            <div style="text-align: right;">
              <div class="font-semibold"><?php echo date('l, F j, Y'); ?></div>
              <div class="text-sm text-light"><?php echo date('h:i A'); ?></div>
            </div>
            <a href="logout.php" class="logout-btn">
              <i class="fas fa-sign-out-alt"></i>
              <span>Logout</span>
            </a>
          </div>
        </div>
      </div>
    </header>

    <!-- Content -->
    <div class="content-container">
      <!-- Cards Grid -->
      <div class="cards-grid">
        

        <div class="card">
          <div class="card-header">
            <div class="card-icon">
              <i class="fas fa-chart-bar"></i>
            </div>
          </div>
          <h3>Price Management</h3>
          <p>Adjust MID, SELL, and BUY prices for Gold & Silver metals.</p>
          <!--<a href="metals.php" class="card-link">-->
          <!--  Manage Metals-->
          <!--  <i class="fas fa-arrow-right"></i>-->
          <!--</a>-->
        </div>

        
      </div>

  <script>
    // Sidebar toggle for desktop
    const sidebarToggle = document.getElementById('sidebarToggle');
    const sidebar = document.getElementById('sidebar');

    if (sidebarToggle) {
      sidebarToggle.addEventListener('click', () => {
        sidebar.classList.toggle('collapsed');
      });
    }

    // Mobile navigation toggle
    const mobileToggle = document.getElementById('mobileToggle');
    const overlay = document.getElementById('overlay');

    if (mobileToggle) {
      mobileToggle.addEventListener('click', () => {
        sidebar.classList.toggle('active');
        overlay.classList.toggle('active');
        document.body.style.overflow = sidebar.classList.contains('active') ? 'hidden' : '';
      });

      overlay.addEventListener('click', () => {
        sidebar.classList.remove('active');
        overlay.classList.remove('active');
        document.body.style.overflow = '';
      });
    }

    // Set active nav link based on current page
    document.addEventListener('DOMContentLoaded', () => {
      const currentPage = window.location.pathname.split('/').pop();
      const navLinks = document.querySelectorAll('.nav-link');
      
      navLinks.forEach(link => {
        const linkPage = link.getAttribute('href');
        if (linkPage === currentPage || (currentPage === '' && linkPage === 'index.php')) {
          link.classList.add('active');
        } else {
          link.classList.remove('active');
        }
      });
    });

    // Close mobile menu on window resize
    window.addEventListener('resize', () => {
      if (window.innerWidth > 1024) {
        sidebar.classList.remove('active');
        overlay.classList.remove('active');
        document.body.style.overflow = '';
      }
    });
  </script>
</body>
</html>