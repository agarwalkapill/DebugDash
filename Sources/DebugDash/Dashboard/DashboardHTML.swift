import Foundation

/// Generates the complete single-page application HTML for the DebugDash dashboard.
/// All HTML, CSS, and JavaScript are embedded as string literals — no external dependencies.
struct DashboardHTML {
    
    // MARK: - Public API
    
    static func generate(port: UInt16, localIP: String) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="description" content="DebugDash - iOS Debug Dashboard">
            <title>DebugDash</title>
            <style>\(cssString())</style>
        </head>
        <body>
            \(htmlStructure(port: port, localIP: localIP))
            <script>\(coreJS())</script>
        </body>
        </html>
        """
    }
    
    // MARK: - CSS Foundation
    
    private static func cssString() -> String {
        return """
        /* ========================================
           CSS Custom Properties (Design Tokens)
           ======================================== */
        :root {
            /* Background colors */
            --bg-primary: #0a0a0f;
            --bg-secondary: #14141f;
            --bg-card: #1c1c2e;
            --bg-hover: #242438;
            --bg-input: #1a1a28;
            
            /* Accent colors */
            --accent-primary: #fa7e3c;
            --accent-primary-hover: #e96d2b;
            --accent-success: #10b981;
            --accent-warning: #f59e0b;
            --accent-error: #ef4444;
            
            /* Text colors */
            --text-primary: #f3f4f6;
            --text-secondary: #9ca3af;
            --text-muted: #6b7280;
            
            /* Border & Shadow */
            --border: #2d2d44;
            --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.3);
            --shadow-md: 0 4px 8px rgba(0, 0, 0, 0.4);
            --shadow-lg: 0 8px 16px rgba(0, 0, 0, 0.5);
            
            /* Spacing */
            --sidebar-width: 240px;
            --border-radius: 12px;
            --border-radius-sm: 8px;
            
            /* Transitions */
            --transition-fast: 150ms ease-in-out;
            --transition-normal: 250ms ease-in-out;
        }
        
        /* ========================================
           Base Reset & Typography
           ======================================== */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        html, body {
            height: 100%;
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, sans-serif;
            font-size: 15px;
            line-height: 1.6;
            color: var(--text-primary);
            background: linear-gradient(135deg, #0a0a0f 0%, #14141f 100%);
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }
        
        h1, h2, h3, h4, h5, h6 {
            font-weight: 600;
            line-height: 1.3;
            color: var(--text-primary);
        }
        
        h1 { font-size: 2rem; }
        h2 { font-size: 1.5rem; }
        h3 { font-size: 1.25rem; }
        
        /* ========================================
           Layout Structure
           ======================================== */
        .app-container {
            display: flex;
            height: 100vh;
            overflow: hidden;
        }
        
        .sidebar {
            width: var(--sidebar-width);
            background: var(--bg-secondary);
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            overflow-y: auto;
            flex-shrink: 0;
        }
        
        .main-content {
            flex: 1;
            overflow-y: auto;
            background: var(--bg-primary);
            padding: 32px;
        }
        
        /* ========================================
           Sidebar Navigation
           ======================================== */
        .sidebar-header {
            padding: 24px 20px;
            border-bottom: 1px solid var(--border);
        }
        
        .logo {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .logo-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, var(--accent-primary) 0%, #f86a1e 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            font-weight: 700;
            color: white;
            box-shadow: var(--shadow-md);
        }
        
        .logo-text {
            display: flex;
            flex-direction: column;
        }
        
        .logo-title {
            font-size: 18px;
            font-weight: 700;
            color: var(--text-primary);
            letter-spacing: -0.3px;
        }
        
        .logo-subtitle {
            font-size: 11px;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .nav-items {
            padding: 16px 0;
        }
        
        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 20px;
            margin: 2px 12px;
            border-radius: var(--border-radius-sm);
            color: var(--text-secondary);
            cursor: pointer;
            transition: all var(--transition-fast);
            position: relative;
            border-left: 3px solid transparent;
        }
        
        .nav-item:hover {
            background: var(--bg-hover);
            color: var(--text-primary);
        }
        
        .nav-item.active {
            background: var(--bg-card);
            color: var(--accent-primary);
            border-left-color: var(--accent-primary);
            box-shadow: var(--shadow-sm);
        }
        
        .nav-item-icon {
            font-size: 20px;
            width: 24px;
            text-align: center;
        }
        
        .nav-item-label {
            font-size: 14px;
            font-weight: 500;
        }
        
        /* ========================================
           Page System
           ======================================== */
        .page {
            display: none;
            animation: fadeIn 0.3s ease-in-out;
        }
        
        .page.active {
            display: block;
        }
        
        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        /* ========================================
           Cards & Containers
           ======================================== */
        .card {
            background: var(--bg-card);
            border-radius: var(--border-radius);
            border: 1px solid var(--border);
            padding: 24px;
            box-shadow: var(--shadow-sm);
            transition: box-shadow var(--transition-fast);
        }
        
        .card:hover {
            box-shadow: var(--shadow-md);
        }
        
        .card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
        }
        
        .card-title {
            font-size: 18px;
            font-weight: 600;
            color: var(--text-primary);
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        
        .stat-card {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: var(--border-radius);
            padding: 20px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 28px;
            font-weight: 700;
            color: var(--accent-primary);
            margin-bottom: 4px;
        }
        
        .stat-label {
            font-size: 13px;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        /* ========================================
           Tables
           ======================================== */
        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        
        .data-table thead {
            background: var(--bg-secondary);
        }
        
        .data-table th {
            text-align: left;
            padding: 12px 16px;
            font-weight: 600;
            color: var(--text-secondary);
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 2px solid var(--border);
        }
        
        .data-table td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            color: var(--text-primary);
        }
        
        .data-table tr:hover {
            background: var(--bg-hover);
        }
        
        .data-table tr:nth-child(even) {
            background: rgba(255, 255, 255, 0.02);
        }
        
        /* ========================================
           Buttons
           ======================================== */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            border: none;
            border-radius: var(--border-radius-sm);
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all var(--transition-fast);
            text-decoration: none;
            font-family: inherit;
        }
        
        .btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        
        .btn-primary {
            background: var(--accent-primary);
            color: white;
        }
        
        .btn-primary:hover:not(:disabled) {
            background: var(--accent-primary-hover);
            transform: translateY(-1px);
            box-shadow: var(--shadow-md);
        }
        
        .btn-secondary {
            background: var(--bg-hover);
            color: var(--text-primary);
            border: 1px solid var(--border);
        }
        
        .btn-secondary:hover:not(:disabled) {
            background: var(--bg-card);
            border-color: var(--accent-primary);
        }
        
        .btn-danger {
            background: var(--accent-error);
            color: white;
        }
        
        .btn-danger:hover:not(:disabled) {
            background: #dc2626;
            transform: translateY(-1px);
        }
        
        .btn-sm {
            padding: 6px 12px;
            font-size: 13px;
        }
        
        /* ========================================
           Badges
           ======================================== */
        .badge {
            display: inline-flex;
            align-items: center;
            padding: 4px 10px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.3px;
        }
        
        .badge-success {
            background: rgba(16, 185, 129, 0.2);
            color: var(--accent-success);
        }
        
        .badge-error {
            background: rgba(239, 68, 68, 0.2);
            color: var(--accent-error);
        }
        
        .badge-warning {
            background: rgba(245, 158, 11, 0.2);
            color: var(--accent-warning);
        }
        
        .badge-info {
            background: rgba(250, 126, 60, 0.2);
            color: var(--accent-primary);
        }
        
        .badge-get { background: rgba(16, 185, 129, 0.2); color: var(--accent-success); }
        .badge-post { background: rgba(250, 126, 60, 0.2); color: var(--accent-primary); }
        .badge-put { background: rgba(245, 158, 11, 0.2); color: var(--accent-warning); }
        .badge-delete { background: rgba(239, 68, 68, 0.2); color: var(--accent-error); }
        
        /* ========================================
           Form Elements
           ======================================== */
        .input, .textarea, select {
            width: 100%;
            padding: 10px 14px;
            background: var(--bg-input);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            color: var(--text-primary);
            font-size: 14px;
            font-family: inherit;
            transition: all var(--transition-fast);
        }
        
        .input:focus, .textarea:focus, select:focus {
            outline: none;
            border-color: var(--accent-primary);
            box-shadow: 0 0 0 3px rgba(250, 126, 60, 0.1);
        }
        
        .textarea {
            resize: vertical;
            min-height: 100px;
            font-family: 'SF Mono', Monaco, Consolas, monospace;
        }
        
        /* ========================================
           Toast Notifications
           ======================================== */
        .toast {
            position: fixed;
            bottom: 24px;
            right: 24px;
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            padding: 16px 20px;
            box-shadow: var(--shadow-lg);
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
            display: flex;
            align-items: center;
            gap: 12px;
            max-width: 400px;
        }
        
        .toast-success {
            border-left: 4px solid var(--accent-success);
        }
        
        .toast-error {
            border-left: 4px solid var(--accent-error);
        }
        
        .toast-info {
            border-left: 4px solid var(--accent-primary);
        }
        
        @keyframes slideIn {
            from {
                transform: translateX(400px);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        /* ========================================
           Status Indicators
           ======================================== */
        .status-indicator {
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .status-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            animation: pulse 2s ease-in-out infinite;
        }
        
        .status-dot.online {
            background: var(--accent-success);
            box-shadow: 0 0 8px var(--accent-success);
        }
        
        .status-dot.offline {
            background: var(--text-muted);
        }
        
        @keyframes pulse {
            0%, 100% {
                opacity: 1;
                transform: scale(1);
            }
            50% {
                opacity: 0.7;
                transform: scale(1.1);
            }
        }
        
        /* ========================================
           Utility Classes
           ======================================== */
        .flex { display: flex; }
        .flex-between { display: flex; justify-content: space-between; align-items: center; }
        .flex-center { display: flex; justify-content: center; align-items: center; }
        .gap-8 { gap: 8px; }
        .gap-12 { gap: 12px; }
        .gap-16 { gap: 16px; }
        .gap-24 { gap: 24px; }
        
        .mt-8 { margin-top: 8px; }
        .mt-16 { margin-top: 16px; }
        .mt-24 { margin-top: 24px; }
        .mb-8 { margin-bottom: 8px; }
        .mb-16 { margin-bottom: 16px; }
        .mb-24 { margin-bottom: 24px; }
        
        .text-muted { color: var(--text-muted); }
        .text-secondary { color: var(--text-secondary); }
        .text-success { color: var(--accent-success); }
        .text-error { color: var(--accent-error); }
        .text-warning { color: var(--accent-warning); }
        
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        
        .font-mono {
            font-family: 'SF Mono', Monaco, Consolas, monospace;
            font-size: 13px;
        }
        
        .truncate {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        /* ========================================
           Hero Section (Home Page)
           ======================================== */
        .hero {
            text-align: center;
            padding: 48px 0;
            border-bottom: 1px solid var(--border);
            margin-bottom: 32px;
        }
        
        .hero-title {
            font-size: 48px;
            font-weight: 700;
            background: linear-gradient(135deg, var(--accent-primary) 0%, #ff6b35 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 16px;
        }
        
        .hero-subtitle {
            font-size: 18px;
            color: var(--text-secondary);
            margin-bottom: 24px;
        }
        
        .hero-status {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            padding: 12px 24px;
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 24px;
        }
        
        /* ========================================
           Empty States
           ======================================== */
        .empty-state {
            text-align: center;
            padding: 64px 32px;
        }
        
        .empty-state-icon {
            font-size: 64px;
            margin-bottom: 16px;
            opacity: 0.3;
        }
        
        .empty-state-title {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 8px;
            color: var(--text-primary);
        }
        
        .empty-state-message {
            color: var(--text-muted);
            max-width: 400px;
            margin: 0 auto;
        }
        
        /* ========================================
           Code Blocks
           ======================================== */
        pre, code {
            font-family: 'SF Mono', Monaco, Consolas, monospace;
            font-size: 13px;
        }
        
        pre {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            padding: 16px;
            overflow-x: auto;
            line-height: 1.5;
        }
        
        code {
            background: var(--bg-hover);
            padding: 2px 6px;
            border-radius: 4px;
        }
        
        /* ========================================
           UserDefaults Browser
           ======================================== */
        .ud-container {
            display: flex;
            height: calc(100vh - 64px);
            gap: 16px;
        }
        
        .ud-sidebar {
            width: 320px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            background: var(--bg-card);
            border-radius: var(--border-radius);
            border: 1px solid var(--border);
            overflow: hidden;
        }
        
        .ud-controls {
            padding: 16px;
            border-bottom: 1px solid var(--border);
        }
        
        .ud-filter-group {
            margin-top: 12px;
        }
        
        .ud-filter-buttons {
            display: flex;
            gap: 6px;
        }
        
        .ud-filter-buttons .btn {
            flex: 1;
            font-size: 11px;
            padding: 6px 8px;
        }
        
        .ud-filter-buttons .btn.active {
            background: var(--accent-primary);
            color: white;
            border-color: var(--accent-primary);
        }
        
        .ud-stats {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            background: var(--bg-secondary);
        }
        
        .ud-key-list {
            flex: 1;
            overflow-y: auto;
            padding: 8px;
        }
        
        .ud-key-item {
            padding: 12px;
            margin-bottom: 6px;
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            cursor: pointer;
            transition: all var(--transition-fast);
        }
        
        .ud-key-item:hover {
            background: var(--bg-hover);
            border-color: var(--accent-primary);
            transform: translateX(2px);
        }
        
        .ud-key-item.active {
            background: var(--bg-hover);
            border-color: var(--accent-primary);
            border-width: 2px;
        }
        
        .ud-key-name {
            font-weight: 600;
            font-size: 13px;
            color: var(--text-primary);
            margin-bottom: 4px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .ud-key-value-preview {
            font-size: 12px;
            color: var(--text-muted);
            font-family: 'SF Mono', Monaco, monospace;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .ud-key-meta {
            display: flex;
            gap: 6px;
            margin-top: 6px;
        }
        
        .ud-editor {
            flex: 1;
            background: var(--bg-card);
            border-radius: var(--border-radius);
            border: 1px solid var(--border);
            padding: 24px;
            overflow-y: auto;
        }
        
        .ud-editor-header {
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--border);
        }
        
        .ud-editor-title {
            font-size: 20px;
            font-weight: 600;
            color: var(--text-primary);
            margin-bottom: 8px;
            word-break: break-all;
        }
        
        .ud-editor-badges {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }
        
        .ud-editor-body textarea {
            width: 100%;
            min-height: 200px;
            font-family: 'SF Mono', Monaco, monospace;
            font-size: 13px;
            line-height: 1.6;
        }
        
        .ud-editor-actions {
            display: flex;
            gap: 12px;
            margin-top: 16px;
        }
        
        .ud-editor-footer {
            margin-top: 32px;
            padding-top: 16px;
            border-top: 1px solid var(--border);
            display: flex;
            gap: 12px;
        }
        
        /* ========================================
           Database Browser
           ======================================== */
        .db-container {
            display: flex;
            height: calc(100vh - 64px);
            gap: 12px;
            /* Prevent the whole container from scrolling — each panel scrolls independently */
            overflow: hidden;
        }
        
        .db-left-panel {
            width: 220px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            background: var(--bg-card);
            border-radius: var(--border-radius);
            border: 1px solid var(--border);
            /* Panel itself does NOT scroll — only .db-list inside does */
            overflow: hidden;
        }
        
        .db-left-panel .panel-header {
            padding: 16px;
            border-bottom: 1px solid var(--border);
            font-weight: 600;
            font-size: 14px;
            color: var(--text-primary);
            /* Header is fixed — never scrolls */
            flex-shrink: 0;
        }
        
        .db-list {
            flex: 1;
            overflow-y: auto; /* Independent vertical scroll for DB list only */
            overflow-x: hidden;
            padding: 8px;
        }
        
        .db-card {
            padding: 12px;
            margin-bottom: 8px;
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            cursor: pointer;
            transition: all var(--transition-fast);
        }
        
        .db-card:hover {
            background: var(--bg-hover);
            border-color: var(--accent-primary);
            transform: translateX(2px);
        }
        
        .db-card.active {
            border-color: var(--accent-primary);
            border-width: 2px;
            background: var(--bg-hover);
        }
        
        .db-card-name {
            font-weight: 600;
            font-size: 13px;
            color: var(--text-primary);
            margin-bottom: 4px;
            word-break: break-all;
        }
        
        .db-card-meta {
            font-size: 11px;
            color: var(--text-muted);
            display: flex;
            gap: 8px;
        }
        
        .db-mid-panel {
            width: 200px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            background: var(--bg-card);
            border-radius: var(--border-radius);
            border: 1px solid var(--border);
            overflow: hidden;
        }
        
        .db-mid-panel .panel-header {
            flex-shrink: 0;
        }
        
        .db-table-list {
            flex: 1;
            overflow-y: auto; /* Independent vertical scroll for table list only */
            overflow-x: hidden;
            padding: 8px;
        }
        
        .db-table-item {
            padding: 10px 12px;
            margin-bottom: 4px;
            font-size: 13px;
            color: var(--text-primary);
            cursor: pointer;
            border-radius: var(--border-radius-sm);
            transition: all var(--transition-fast);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .db-table-item:hover {
            background: var(--bg-hover);
            color: var(--accent-primary);
        }
        
        .db-table-item.active {
            background: var(--bg-hover);
            color: var(--accent-primary);
            font-weight: 600;
        }
        
        .db-right-panel {
            flex: 1;
            min-width: 0; /* Critical: allows flex child to shrink below content width */
            display: flex;
            flex-direction: column;
            background: var(--bg-card);
            border-radius: var(--border-radius);
            border: 1px solid var(--border);
            overflow: hidden;
        }
        
        .db-tabs {
            display: flex;
            border-bottom: 1px solid var(--border);
            padding: 0 16px;
            flex-shrink: 0;
        }
        
        .db-tab {
            padding: 12px 20px;
            font-size: 13px;
            color: var(--text-muted);
            cursor: pointer;
            border-bottom: 2px solid transparent;
            transition: all var(--transition-fast);
            white-space: nowrap;
        }
        
        .db-tab:hover {
            color: var(--text-primary);
        }
        
        .db-tab.active {
            color: var(--accent-primary);
            border-bottom-color: var(--accent-primary);
            font-weight: 600;
        }
        
        /* Tab content: no overflow, no padding here — let the inner grid handle scroll */
        .db-tab-content {
            flex: 1;
            min-height: 0; /* Critical: allows flex child to shrink, enabling inner scroll */
            display: flex;
            flex-direction: column;
            overflow: hidden; /* NO overflow here — the .db-grid-scroll inside does it */
            padding: 0;
        }
        
        /* The actual scroll container for table data — both axes */
        .db-grid-scroll {
            flex: 1;
            overflow: auto; /* Both x and y scroll */
            /* Sticky headers require the scroll container to be THIS element */
        }
        
        .db-tab-padded {
            /* For schema and SQL tabs that need padding but not a data grid */
            flex: 1;
            overflow: auto;
            padding: 16px;
        }
        
        .db-data-table {
            border-collapse: collapse;
            font-size: 12px;
            /* Do NOT set width: 100% here — let it be as wide as the content needs */
            min-width: 100%;
        }
        
        .db-data-table th {
            background: var(--bg-secondary);
            padding: 10px 14px;
            text-align: left;
            font-weight: 600;
            color: var(--accent-primary);
            border-bottom: 2px solid var(--border);
            border-right: 1px solid var(--border);
            white-space: nowrap;
            position: sticky;
            top: 0;
            z-index: 2;
        }
        
        .db-data-table td {
            padding: 8px 14px;
            border-bottom: 1px solid var(--border);
            border-right: 1px solid var(--border);
            color: var(--text-primary);
            max-width: 220px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            cursor: pointer; /* Clickable to expand */
        }
        
        .db-data-table td:hover {
            background: color-mix(in srgb, var(--accent-primary) 10%, transparent);
            color: var(--accent-primary);
        }
        
        .db-data-table tr:hover td {
            background: var(--bg-hover);
        }
        
        .db-data-table tr:hover td:hover {
            background: color-mix(in srgb, var(--accent-primary) 15%, transparent);
        }
        
        .db-data-table td.null-value {
            color: var(--text-muted);
            font-style: italic;
            cursor: default;
        }
        
        .db-data-table td.null-value:hover {
            background: var(--bg-hover);
            color: var(--text-muted);
        }
        
        /* First column (row number / PK) — sticky left */
        .db-data-table th:first-child,
        .db-data-table td:first-child {
            position: sticky;
            left: 0;
            z-index: 1;
            background: var(--bg-secondary);
            border-right: 2px solid var(--border);
        }
        
        .db-data-table th:first-child {
            z-index: 3; /* Above both row and column stickiness */
        }
        
        .db-data-table tr:hover td:first-child {
            background: var(--bg-hover);
        }
        
        .db-pagination {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 12px 16px;
            border-top: 1px solid var(--border);
            background: var(--bg-secondary);
            flex-shrink: 0;
        }
        
        .db-pagination-info {
            font-size: 12px;
            color: var(--text-muted);
        }
        
        .db-pagination-controls {
            display: flex;
            gap: 8px;
        }
        
        .db-schema-col {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 14px;
            border-bottom: 1px solid var(--border);
        }
        
        .db-schema-col:hover {
            background: var(--bg-hover);
        }
        
        .db-schema-col-name {
            font-weight: 600;
            font-size: 13px;
            color: var(--text-primary);
            min-width: 140px;
        }
        
        .db-sql-console {
            display: flex;
            flex-direction: column;
            height: 100%;
        }
        
        .db-sql-input {
            width: 100%;
            min-height: 120px;
            font-family: 'SF Mono', Monaco, monospace;
            font-size: 13px;
            resize: vertical;
        }
        
        .db-sql-actions {
            display: flex;
            gap: 12px;
            margin: 12px 0;
            align-items: center;
            flex-shrink: 0;
        }
        
        .db-sql-results {
            flex: 1;
            min-height: 0;
            overflow: auto;
        }
        
        .db-sql-timing {
            font-size: 12px;
            color: var(--text-muted);
        }
        
        /* ----------------------------------------
           Cell Value Modal
           ---------------------------------------- */
        .db-cell-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.6);
            z-index: 1000;
            display: flex;
            align-items: center;
            justify-content: center;
            animation: fadeIn 0.15s ease;
        }
        
        .db-cell-modal {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: var(--border-radius);
            width: min(680px, 90vw);
            max-height: 70vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 24px 64px rgba(0,0,0,0.5);
            animation: slideUp 0.15s ease;
        }
        
        .db-cell-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
        }
        
        .db-cell-modal-title {
            font-weight: 600;
            font-size: 14px;
            color: var(--text-primary);
        }
        
        .db-cell-modal-meta {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 2px;
        }
        
        .db-cell-modal-body {
            flex: 1;
            overflow-y: auto;
            padding: 16px 20px;
        }
        
        .db-cell-modal-value {
            font-family: 'SF Mono', Monaco, monospace;
            font-size: 13px;
            line-height: 1.6;
            color: var(--text-primary);
            white-space: pre-wrap;
            word-break: break-all;
            background: var(--bg-secondary);
            padding: 12px;
            border-radius: var(--border-radius-sm);
            border: 1px solid var(--border);
        }
        
        .db-cell-modal-footer {
            display: flex;
            gap: 12px;
            padding: 12px 20px;
            border-top: 1px solid var(--border);
            flex-shrink: 0;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideUp {
            from { transform: translateY(16px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        
        /* Edit Row Button */
        .db-data-table .db-edit-cell {
            padding: 4px 8px;
            text-align: center;
            cursor: pointer;
            border-right: none;
            max-width: 40px;
            position: sticky;
            right: 0;
            background: var(--bg-secondary);
            border-left: 2px solid var(--border);
        }
        
        .db-data-table .db-edit-cell:hover {
            background: color-mix(in srgb, var(--accent-primary) 15%, transparent);
        }
        
        .db-data-table th.db-edit-header {
            position: sticky;
            right: 0;
            z-index: 3;
            text-align: center;
            border-right: none;
            border-left: 2px solid var(--border);
            padding: 10px 8px;
            min-width: 40px;
        }
        
        .db-edit-btn {
            background: none;
            border: none;
            cursor: pointer;
            font-size: 14px;
            padding: 4px 6px;
            border-radius: 4px;
            opacity: 0.6;
            transition: opacity 0.15s;
        }
        
        .db-edit-btn:hover {
            opacity: 1;
        }
        
        .db-data-table tr:hover .db-edit-cell {
            background: var(--bg-hover);
        }
        
        /* Edit Row Modal */
        .db-edit-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.6);
            z-index: 1000;
            display: flex;
            align-items: center;
            justify-content: center;
            animation: fadeIn 0.15s ease;
        }
        
        .db-edit-modal {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: var(--border-radius);
            width: min(600px, 90vw);
            max-height: 80vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 24px 64px rgba(0,0,0,0.5);
            animation: slideUp 0.15s ease;
        }
        
        .db-edit-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 20px;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
        }
        
        .db-edit-modal-title {
            font-weight: 600;
            font-size: 14px;
            color: var(--text-primary);
        }
        
        .db-edit-modal-subtitle {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 2px;
        }
        
        .db-edit-modal-body {
            flex: 1;
            overflow-y: auto;
            padding: 16px 20px;
        }
        
        .db-edit-field {
            margin-bottom: 14px;
        }
        
        .db-edit-field-label {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-bottom: 6px;
        }
        
        .db-edit-field-name {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
        }
        
        .db-edit-field-input {
            width: 100%;
            padding: 8px 10px;
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            color: var(--text-primary);
            font-size: 13px;
            font-family: 'SF Mono', Monaco, monospace;
            resize: vertical;
        }
        
        .db-edit-field-input:focus {
            outline: none;
            border-color: var(--accent-primary);
        }
        
        .db-edit-field-input:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        
        .db-edit-null-toggle {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-top: 4px;
        }
        
        .db-edit-null-toggle label {
            font-size: 11px;
            color: var(--text-muted);
            cursor: pointer;
        }
        
        .db-edit-modal-footer {
            display: flex;
            gap: 12px;
            padding: 12px 20px;
            border-top: 1px solid var(--border);
            flex-shrink: 0;
            justify-content: flex-end;
        }
        
        /* ======================================== */
        /* Network Inspector                         */
        /* ======================================== */
        .net-container {
            display: flex;
            flex-direction: column;
            height: calc(100vh - 64px);
            overflow: hidden;
        }
        
        .net-stats-bar {
            display: flex;
            gap: 16px;
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
            flex-wrap: wrap;
        }
        
        .net-stat {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            color: var(--text-secondary);
        }
        
        .net-stat-value {
            font-weight: 600;
            color: var(--text-primary);
        }
        
        .net-body {
            display: flex;
            flex: 1;
            overflow: hidden;
        }
        
        .net-list-panel {
            width: 380px;
            min-width: 300px;
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .net-filters {
            display: flex;
            gap: 8px;
            padding: 10px 12px;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
            flex-wrap: wrap;
        }
        
        .net-filter-input {
            flex: 1;
            min-width: 100px;
            padding: 6px 10px;
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            color: var(--text-primary);
            font-size: 12px;
        }
        
        .net-filter-input:focus {
            outline: none;
            border-color: var(--accent-primary);
        }
        
        .net-filter-select {
            padding: 6px 8px;
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius-sm);
            color: var(--text-primary);
            font-size: 12px;
        }
        
        .net-list {
            flex: 1;
            overflow-y: auto;
        }
        
        .net-list-actions {
            display: flex;
            justify-content: space-between;
            padding: 8px 12px;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
        }
        
        .net-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 12px;
            border-bottom: 1px solid var(--border);
            cursor: pointer;
            transition: background 0.1s;
        }
        
        .net-item:hover {
            background: var(--bg-hover);
        }
        
        .net-item.active {
            background: color-mix(in srgb, var(--accent-primary) 10%, transparent);
            border-left: 3px solid var(--accent-primary);
        }
        
        .net-item-method {
            font-size: 10px;
            font-weight: 700;
            padding: 2px 6px;
            border-radius: 3px;
            min-width: 36px;
            text-align: center;
            color: white;
        }
        
        .net-method-get { background: #2196f3; }
        .net-method-post { background: #4caf50; }
        .net-method-put { background: #ff9800; }
        .net-method-delete { background: #f44336; }
        .net-method-patch { background: #9c27b0; }
        .net-method-other { background: #607d8b; }
        
        .net-item-info {
            flex: 1;
            min-width: 0;
        }
        
        .net-item-path {
            font-size: 12px;
            color: var(--text-primary);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .net-item-host {
            font-size: 11px;
            color: var(--text-muted);
            margin-top: 2px;
        }
        
        .net-item-meta {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 2px;
            flex-shrink: 0;
        }
        
        .net-status-badge {
            font-size: 11px;
            font-weight: 600;
            padding: 1px 6px;
            border-radius: 3px;
        }
        
        .net-status-2xx { background: rgba(76, 175, 80, 0.15); color: #4caf50; }
        .net-status-3xx { background: rgba(33, 150, 243, 0.15); color: #2196f3; }
        .net-status-4xx { background: rgba(255, 152, 0, 0.15); color: #ff9800; }
        .net-status-5xx { background: rgba(244, 67, 54, 0.15); color: #f44336; }
        .net-status-pending { background: rgba(158, 158, 158, 0.15); color: #9e9e9e; }
        .net-status-intercepted { background: rgba(156, 39, 176, 0.15); color: #ce93d8; }
        
        .net-item-duration {
            font-size: 10px;
            color: var(--text-muted);
        }
        
        /* Detail Panel */
        .net-detail-panel {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .net-detail-header {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
        }
        
        .net-detail-url {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-primary);
            word-break: break-all;
        }
        
        .net-detail-tabs {
            display: flex;
            gap: 0;
            border-bottom: 1px solid var(--border);
            flex-shrink: 0;
        }
        
        .net-detail-tab {
            padding: 8px 16px;
            font-size: 12px;
            font-weight: 500;
            color: var(--text-muted);
            cursor: pointer;
            border-bottom: 2px solid transparent;
            transition: all 0.15s;
        }
        
        .net-detail-tab:hover {
            color: var(--text-primary);
        }
        
        .net-detail-tab.active {
            color: var(--accent-primary);
            border-bottom-color: var(--accent-primary);
        }
        
        .net-detail-body {
            flex: 1;
            overflow-y: auto;
            padding: 16px;
        }
        
        .net-headers-table {
            width: 100%;
            font-size: 12px;
            border-collapse: collapse;
        }
        
        .net-headers-table th {
            text-align: left;
            padding: 6px 10px;
            color: var(--accent-primary);
            font-weight: 600;
            border-bottom: 1px solid var(--border);
            white-space: nowrap;
        }
        
        .net-headers-table td {
            padding: 6px 10px;
            border-bottom: 1px solid var(--border);
            color: var(--text-primary);
            word-break: break-all;
        }
        
        .net-headers-table td:first-child {
            color: var(--text-secondary);
            white-space: nowrap;
            font-weight: 500;
            width: 180px;
        }
        
        .net-body-pre {
            font-family: 'SF Mono', Monaco, monospace;
            font-size: 12px;
            line-height: 1.5;
            color: var(--text-primary);
            white-space: pre-wrap;
            word-break: break-all;
            background: var(--bg-secondary);
            padding: 12px;
            border-radius: var(--border-radius-sm);
            border: 1px solid var(--border);
            max-height: 400px;
            overflow-y: auto;
        }
        
        /* Interceptor Section */
        .net-interceptor {
            padding: 16px;
        }
        
        .net-interceptor-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
        }
        
        .net-toggle-switch {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .net-toggle-label {
            font-size: 13px;
            color: var(--text-secondary);
        }
        
        .net-toggle-btn {
            width: 44px;
            height: 24px;
            border-radius: 12px;
            border: none;
            cursor: pointer;
            position: relative;
            transition: background 0.2s;
            background: var(--border);
        }
        
        .net-toggle-btn.active {
            background: var(--accent-primary);
        }
        
        .net-toggle-btn::after {
            content: '';
            position: absolute;
            top: 3px;
            left: 3px;
            width: 18px;
            height: 18px;
            border-radius: 50%;
            background: white;
            transition: transform 0.2s;
        }
        
        .net-toggle-btn.active::after {
            transform: translateX(20px);
        }
        
        .net-rule-card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: var(--border-radius);
            padding: 12px 16px;
            margin-bottom: 10px;
        }
        
        .net-rule-card.disabled {
            opacity: 0.5;
        }
        
        .net-rule-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 6px;
        }
        
        .net-rule-label {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-primary);
        }
        
        .net-rule-actions {
            display: flex;
            gap: 6px;
        }
        
        .net-rule-meta {
            font-size: 11px;
            color: var(--text-muted);
            display: flex;
            gap: 12px;
        }
        
        /* ======================================== */
        /* Interceptor Page                         */
        /* ======================================== */
        
        .interceptor-modal-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.6);
            z-index: 1000;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .interceptor-modal-card {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            width: 520px;
            max-width: 90vw;
            max-height: 88vh;
            overflow-y: auto;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        }
        
        .interceptor-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 18px 20px 14px;
            border-bottom: 1px solid var(--border);
        }
        
        .interceptor-modal-header h3 {
            margin: 0;
            font-size: 16px;
        }
        
        .interceptor-form-body {
            padding: 16px 20px;
        }
        
        .interceptor-modal-footer {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            padding: 12px 20px 18px;
            border-top: 1px solid var(--border);
        }
        
        .form-row {
            margin-bottom: 14px;
        }
        
        .form-label {
            display: block;
            font-size: 12px;
            color: var(--text-secondary);
            margin-bottom: 5px;
            font-weight: 500;
        }
        
        /* ======================================== */
        /* Scrollbar Styling                        */
            width: 10px;
            height: 10px;
        }
        
        ::-webkit-scrollbar-track {
            background: var(--bg-secondary);
        }
        
        ::-webkit-scrollbar-thumb {
            background: var(--border);
            border-radius: 5px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
            background: var(--text-muted);
        }
        """
    }
    
    // MARK: - HTML Structure
    
    private static func htmlStructure(port: UInt16, localIP: String) -> String {
        return """
        <div class="app-container">
            <!-- Sidebar Navigation -->
            <nav class="sidebar">
                <div class="sidebar-header">
                    <div class="logo">
                        <div class="logo-icon">DD</div>
                        <div class="logo-text">
                            <div class="logo-title">DebugDash</div>
                            <div class="logo-subtitle">iOS Inspector</div>
                        </div>
                    </div>
                </div>
                
                <div class="nav-items">
                    <div class="nav-item active" data-page="page-home">
                        <span class="nav-item-icon">🏠</span>
                        <span class="nav-item-label">Home</span>
                    </div>
                    <div class="nav-item" data-page="page-userdefaults">
                        <span class="nav-item-icon">📦</span>
                        <span class="nav-item-label">UserDefaults</span>
                    </div>
                    <div class="nav-item" data-page="page-database">
                        <span class="nav-item-icon">🗄️</span>
                        <span class="nav-item-label">Database</span>
                    </div>
                    <div class="nav-item" data-page="page-network">
                        <span class="nav-item-icon">🌐</span>
                        <span class="nav-item-label">Network Browser</span>
                    </div>
                    <div class="nav-item" data-page="page-interceptor">
                        <span class="nav-item-icon">🛡️</span>
                        <span class="nav-item-label">Interceptor</span>
                    </div>
                </div>
            </nav>
            
            <!-- Main Content Area -->
            <main class="main-content">
                <!-- Home Page -->
                <div id="page-home" class="page active">
                    <div class="hero">
                        <h1 class="hero-title">DebugDash</h1>
                        <p class="hero-subtitle">iOS debugging server is running</p>
                        <div class="hero-status">
                            <span class="status-dot online"></span>
                            <span>Port \(port)</span>
                            <span class="badge badge-success">Online</span>
                        </div>
                    </div>
                    
                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-value" id="uptime-display">0s</div>
                            <div class="stat-label">Uptime</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value" id="device-ip">\(localIP)</div>
                            <div class="stat-label">Device IP</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value" id="db-count">0</div>
                            <div class="stat-label">Databases</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value" id="request-count">0</div>
                            <div class="stat-label">Requests</div>
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">Dashboard URL</h3>
                            <button class="btn btn-sm btn-primary" onclick="copyDashboardURL()">
                                📋 Copy URL
                            </button>
                        </div>
                        <div class="flex gap-12" style="align-items: center;">
                            <code style="flex: 1; padding: 12px; background: var(--bg-secondary); border-radius: 8px;" id="dashboard-url">http://\(localIP):\(port)/dashboard</code>
                        </div>
                    </div>
                    
                    <div class="card mt-24">
                        <h3 class="card-title mb-16">Quick Start</h3>
                        <div style="display: flex; flex-direction: column; gap: 16px;">
                            <div style="display: flex; gap: 12px; align-items: start;">
                                <div class="badge badge-info" style="margin-top: 4px;">1</div>
                                <div>
                                    <strong style="display: block; margin-bottom: 4px;">Network Capture</strong>
                                    <span class="text-muted">Use the example app to make sample network requests. They'll appear in the Network tab.</span>
                                </div>
                            </div>
                            <div style="display: flex; gap: 12px; align-items: start;">
                                <div class="badge badge-info" style="margin-top: 4px;">2</div>
                                <div>
                                    <strong style="display: block; margin-bottom: 4px;">UserDefaults Browser</strong>
                                    <span class="text-muted">Write sample UserDefaults data from the app, then explore them in the UserDefaults tab.</span>
                                </div>
                            </div>
                            <div style="display: flex; gap: 12px; align-items: start;">
                                <div class="badge badge-info" style="margin-top: 4px;">3</div>
                                <div>
                                    <strong style="display: block; margin-bottom: 4px;">Database Inspector</strong>
                                    <span class="text-muted">Browse SQLite databases in real-time. Tables and data will be shown in the Database tab.</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- UserDefaults Page -->
                <div id="page-userdefaults" class="page">
                    <div class="ud-container">
                        <!-- Left Sidebar -->
                        <div class="ud-sidebar">
                            <div class="ud-controls">
                                <select id="ud-suite-select" class="input">
                                    <option value="">All Suites</option>
                                </select>
                                
                                <div class="ud-filter-group">
                                    <label style="font-size: 12px; color: var(--text-muted); margin-bottom: 4px; display: block;">Filter:</label>
                                    <div class="ud-filter-buttons">
                                        <button class="btn btn-sm btn-secondary active" data-filter="app" title="Show only app-specific keys">
                                            📱 App Keys
                                        </button>
                                        <button class="btn btn-sm btn-secondary" data-filter="all" title="Show all keys">
                                            🔍 All
                                        </button>
                                        <button class="btn btn-sm btn-secondary" data-filter="system" title="Show only iOS system keys">
                                            ⚙️ System
                                        </button>
                                    </div>
                                </div>
                                
                                <input 
                                    type="text" 
                                    id="ud-search" 
                                    class="input" 
                                    placeholder="Search keys or values..."
                                    style="margin-top: 8px;"
                                />
                            </div>
                            
                            <div class="ud-stats" id="ud-stats">
                                <span class="text-muted" style="font-size: 12px;">Loading...</span>
                            </div>
                            
                            <div class="ud-key-list" id="ud-key-list">
                                <div class="empty-state" style="padding: 32px 16px;">
                                    <div class="empty-state-icon" style="font-size: 48px;">📦</div>
                                    <p class="empty-state-message" style="font-size: 13px;">
                                        No keys found. Use the example app to write some UserDefaults data.
                                    </p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Right Editor Panel -->
                        <div class="ud-editor" id="ud-editor">
                            <div class="empty-state">
                                <div class="empty-state-icon">👈</div>
                                <h3 class="empty-state-title">No Key Selected</h3>
                                <p class="empty-state-message">
                                    Select a key from the left sidebar to view and edit its value.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Database Page -->
                <div id="page-database" class="page">
                    <div class="db-container">
                        <!-- Left: Database List -->
                        <div class="db-left-panel">
                            <div class="panel-header">Databases</div>
                            <div class="db-list" id="db-list">
                                <div class="empty-state" style="padding: 24px 12px;">
                                    <div class="empty-state-icon" style="font-size: 36px;">🗄️</div>
                                    <p class="empty-state-message" style="font-size: 12px;">No databases found.</p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Middle: Table List -->
                        <div class="db-mid-panel">
                            <div class="panel-header">Tables</div>
                            <div class="db-table-list" id="db-table-list">
                                <div class="empty-state" style="padding: 24px 12px;">
                                    <p class="empty-state-message" style="font-size: 12px;">Select a database</p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Right: Content Area -->
                        <div class="db-right-panel">
                            <div class="db-tabs" id="db-tabs" style="display: none;">
                                <div class="db-tab active" data-tab="browse">📋 Browse</div>
                                <div class="db-tab" data-tab="schema">🏗️ Schema</div>
                                <div class="db-tab" data-tab="sql">⌨️ SQL Console</div>
                            </div>
                            
                            <div class="db-tab-content" id="db-tab-content">
                                <div class="empty-state">
                                    <div class="empty-state-icon">👈</div>
                                    <h3 class="empty-state-title">Select a Table</h3>
                                    <p class="empty-state-message">Choose a database and table from the left to browse data, view schema, or run SQL queries.</p>
                                </div>
                            </div>
                            
                            <div class="db-pagination" id="db-pagination" style="display: none;">
                                <div class="db-pagination-info" id="db-page-info">Page 1 of 1</div>
                                <div class="db-pagination-controls">
                                    <button class="btn btn-sm btn-secondary" id="db-prev-btn" disabled>← Prev</button>
                                    <button class="btn btn-sm btn-secondary" id="db-next-btn" disabled>Next →</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Network Page -->
                <div id="page-network" class="page">
                    <div class="net-container">
                        <div class="net-stats-bar" id="net-stats-bar">
                            <div class="net-stat">Total: <span class="net-stat-value" id="net-stat-total">0</span></div>
                            <div class="net-stat">Success: <span class="net-stat-value" id="net-stat-success">0</span></div>
                            <div class="net-stat">Failed: <span class="net-stat-value" id="net-stat-error">0</span></div>
                            <div class="net-stat">Intercepted: <span class="net-stat-value" id="net-stat-intercepted">0</span></div>
                            <div class="net-stat">Avg: <span class="net-stat-value" id="net-stat-avg">0ms</span></div>
                        </div>
                        <div class="net-body">
                            <div class="net-list-panel">
                                <div class="net-filters">
                                    <input class="net-filter-input" id="net-filter-path" type="text" placeholder="Filter by path...">
                                    <select class="net-filter-select" id="net-filter-method">
                                        <option value="">All Methods</option>
                                        <option value="GET">GET</option>
                                        <option value="POST">POST</option>
                                        <option value="PUT">PUT</option>
                                        <option value="DELETE">DELETE</option>
                                        <option value="PATCH">PATCH</option>
                                    </select>
                                </div>
                                <div class="net-list-actions">
                                    <span class="text-muted" style="font-size: 11px;" id="net-list-count">0 requests</span>
                                    <button class="btn btn-sm btn-secondary" id="net-clear-btn">🗑 Clear</button>
                                </div>
                                <div class="net-list" id="net-list"></div>
                            </div>
                            <div class="net-detail-panel" id="net-detail-panel">
                                <div class="empty-state" style="margin: auto;">
                                    <div class="empty-state-icon">👈</div>
                                    <p class="empty-state-message">Select a request to view details</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Interceptor Page -->
                <div id="page-interceptor" class="page">
                    <div class="net-interceptor">
                        <div class="net-interceptor-header">
                            <div>
                                <h2 style="margin:0;font-size:18px;">Network Interceptor</h2>
                                <p style="margin:4px 0 0;font-size:12px;color:var(--text-muted);">Mock HTTP responses with custom rules</p>
                            </div>
                            <div style="display:flex;align-items:center;gap:12px;">
                                <span id="interceptor-active-count" class="badge" style="background:var(--bg-secondary);color:var(--text-secondary);">0 active</span>
                                <div class="net-toggle-switch">
                                    <span class="net-toggle-label" id="interceptor-status-label">Off</span>
                                    <button class="net-toggle-btn" id="interceptor-master-toggle" onclick="toggleInterceptorMaster()"></button>
                                </div>
                                <button class="btn btn-primary" onclick="openRuleForm(null)" style="font-size:12px;padding:6px 14px;">+ Add Rule</button>
                            </div>
                        </div>
                        <div id="interceptor-rule-list"></div>
                        <div id="interceptor-empty" class="empty-state" style="display:none;">
                            <div class="empty-state-icon">🛡️</div>
                            <h3 class="empty-state-title">No Intercept Rules</h3>
                            <p class="empty-state-message">Add a rule to mock HTTP responses for specific URL patterns.</p>
                        </div>
                    </div>
                    <!-- Add/Edit Rule Modal -->
                    <div id="rule-form-modal" class="interceptor-modal-overlay" style="display:none;">
                        <div class="interceptor-modal-card">
                            <div class="interceptor-modal-header">
                                <h3 id="rule-form-title">Add Rule</h3>
                                <button class="btn btn-secondary" style="padding:4px 10px;font-size:12px;" onclick="closeRuleForm()">✕</button>
                            </div>
                            <div class="interceptor-form-body">
                                <div class="form-row">
                                    <label class="form-label">Label</label>
                                    <input type="text" id="rule-label" class="input" placeholder="e.g. Mock User API">
                                </div>
                                <div class="form-row">
                                    <label class="form-label">Path Pattern</label>
                                    <input type="text" id="rule-path" class="input" placeholder="/api/users">
                                </div>
                                <div class="form-row">
                                    <label class="form-label">Method</label>
                                    <select id="rule-method" class="input">
                                        <option value="ANY">ANY</option>
                                        <option value="GET">GET</option>
                                        <option value="POST">POST</option>
                                        <option value="PUT">PUT</option>
                                        <option value="DELETE">DELETE</option>
                                    </select>
                                </div>
                                <div class="form-row">
                                    <label class="form-label">Mock Status Code</label>
                                    <input type="number" id="rule-status-code" class="input" value="200" min="100" max="599">
                                </div>
                                <div class="form-row">
                                    <label class="form-label">Response Body</label>
                                    <textarea id="rule-response-body" class="textarea" rows="5" placeholder='{"key": "value"}'></textarea>
                                </div>
                                <div class="form-row">
                                    <label class="form-label">Response Headers <span style="color:var(--text-muted);font-size:11px;">(one per line: Key: Value)</span></label>
                                    <textarea id="rule-response-headers" class="textarea" rows="3" placeholder="Content-Type: application/json"></textarea>
                                </div>
                                <input type="hidden" id="rule-editing-id">
                            </div>
                            <div class="interceptor-modal-footer">
                                <button class="btn btn-secondary" onclick="closeRuleForm()">Cancel</button>
                                <button class="btn btn-primary" onclick="submitRuleForm()">Save Rule</button>
                            </div>
                        </div>
                    </div>
                </div>
                
            </main>
        </div>
        """
    }
    
    // MARK: - Core JavaScript
    
    private static func coreJS() -> String {
        return """
        // ========================================
        // Global State
        // ========================================
        const state = {
            activePollers: {},
            uptimeStart: Date.now(),
            requestCount: 0
        };
        
        // ========================================
        // Navigation System
        // ========================================
        function navigateTo(pageId) {
            // Hide all pages
            document.querySelectorAll('.page').forEach(page => {
                page.classList.remove('active');
            });
            
            // Show target page
            const targetPage = document.getElementById(pageId);
            if (targetPage) {
                targetPage.classList.add('active');
            }
            
            // Update nav items
            document.querySelectorAll('.nav-item').forEach(item => {
                item.classList.remove('active');
            });
            
            const activeNavItem = document.querySelector(`[data-page="${pageId}"]`);
            if (activeNavItem) {
                activeNavItem.classList.add('active');
            }
            
            // Call page init functions
            const initFunctions = {
                'page-home': initHome,
                'page-userdefaults': initUserDefaults,
                'page-database': initDatabase,
                'page-network': initNetwork,
                'page-interceptor': initInterceptor
            };
            
            const initFn = initFunctions[pageId];
            if (initFn) {
                initFn();
            }
        }
        
        // ========================================
        // API Communication
        // ========================================
        async function apiFetch(path, options = {}) {
            try {
                const url = window.location.origin + path;
                const response = await fetch(url, {
                    ...options,
                    headers: {
                        'Content-Type': 'application/json',
                        ...options.headers
                    }
                });
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
                
                const data = await response.json();
                return data;
            } catch (error) {
                console.error('API fetch error:', error);
                showToast('Connection lost. Is the server running?', 'error');
                return null;
            }
        }
        
        // ========================================
        // Polling Manager
        // ========================================
        function startPolling(name, fn, intervalMs) {
            // Clear existing poller
            stopPolling(name);
            
            // Call immediately
            fn();
            
            // Set up interval
            state.activePollers[name] = setInterval(fn, intervalMs);
        }
        
        function stopPolling(name) {
            if (state.activePollers[name]) {
                clearInterval(state.activePollers[name]);
                delete state.activePollers[name];
            }
        }
        
        function stopAllPolling() {
            Object.keys(state.activePollers).forEach(name => {
                stopPolling(name);
            });
        }
        
        // ========================================
        // Clipboard Utilities
        // ========================================
        async function copyToClipboard(text) {
            try {
                if (navigator.clipboard && window.isSecureContext) {
                    await navigator.clipboard.writeText(text);
                    showToast('Copied to clipboard!', 'success');
                } else {
                    // Fallback for older browsers
                    const textArea = document.createElement('textarea');
                    textArea.value = text;
                    textArea.style.position = 'fixed';
                    textArea.style.left = '-999999px';
                    document.body.appendChild(textArea);
                    textArea.focus();
                    textArea.select();
                    
                    try {
                        document.execCommand('copy');
                        showToast('Copied to clipboard!', 'success');
                    } catch (err) {
                        showToast('Failed to copy', 'error');
                    }
                    
                    document.body.removeChild(textArea);
                }
            } catch (error) {
                console.error('Copy failed:', error);
                showToast('Failed to copy', 'error');
            }
        }
        
        function copyDashboardURL() {
            const urlElement = document.getElementById('dashboard-url');
            if (urlElement) {
                copyToClipboard(urlElement.textContent);
            }
        }
        
        // ========================================
        // String Utilities
        // ========================================
        function truncate(str, maxLength) {
            if (str.length <= maxLength) return str;
            return str.substring(0, maxLength) + '...';
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // ========================================
        // Toast Notifications
        // ========================================
        function showToast(message, type = 'success') {
            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;
            
            const icon = type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ';
            toast.innerHTML = `
                <span style="font-size: 20px;">${icon}</span>
                <span>${message}</span>
            `;
            
            document.body.appendChild(toast);
            
            // Auto-remove after 3 seconds
            setTimeout(() => {
                toast.style.animation = 'slideIn 0.3s ease-out reverse';
                setTimeout(() => {
                    document.body.removeChild(toast);
                }, 300);
            }, 3000);
        }
        
        // ========================================
        // Home Page Functions
        // ========================================
        function initHome() {
            startPolling('status', fetchStatus, 5000);
        }
        
        async function fetchStatus() {
            const data = await apiFetch('/api/status');
            if (data) {
                // Update UI with status data
                const deviceIP = document.getElementById('device-ip');
                const dbCount = document.getElementById('db-count');
                const requestCount = document.getElementById('request-count');
                
                if (deviceIP && data.ip) {
                    deviceIP.textContent = data.ip;
                }
                
                if (dbCount && typeof data.dbCount !== 'undefined') {
                    dbCount.textContent = data.dbCount;
                }
                
                if (requestCount && typeof data.requestCount !== 'undefined') {
                    requestCount.textContent = data.requestCount;
                }
            }
        }
        
        function startUptimeCounter() {
            setInterval(() => {
                const elapsed = Math.floor((Date.now() - state.uptimeStart) / 1000);
                const hours = Math.floor(elapsed / 3600);
                const minutes = Math.floor((elapsed % 3600) / 60);
                const seconds = elapsed % 60;
                
                let uptimeStr = '';
                if (hours > 0) {
                    uptimeStr += `${hours}h `;
                }
                if (minutes > 0 || hours > 0) {
                    uptimeStr += `${minutes}m `;
                }
                uptimeStr += `${seconds}s`;
                
                const uptimeDisplay = document.getElementById('uptime-display');
                if (uptimeDisplay) {
                    uptimeDisplay.textContent = uptimeStr;
                }
            }, 1000);
        }
        
        // ========================================
        // Page Init Stubs (will be implemented in future phases)
        // ========================================
        function initUserDefaults() {
            stopAllPolling();
            console.log('UserDefaults page initialized');
            
            let currentSuite = '';
            let currentFilter = 'app'; // Default to showing app keys only
            let currentSearchTerm = '';
            let selectedKey = null;
            let allKeys = [];
            let pollingInterval = null;
            
            // DOM elements
            const suiteSelect = document.getElementById('ud-suite-select');
            const searchInput = document.getElementById('ud-search');
            const keyList = document.getElementById('ud-key-list');
            const editor = document.getElementById('ud-editor');
            const stats = document.getElementById('ud-stats');
            const filterButtons = document.querySelectorAll('.ud-filter-buttons .btn');
            
            // Load suites
            async function loadSuites() {
                try {
                    const data = await apiFetch('/api/suites');
                    suiteSelect.innerHTML = '<option value="">All Suites</option>';
                    data.suites.forEach(suite => {
                        const option = document.createElement('option');
                        option.value = suite;
                        option.textContent = suite;
                        suiteSelect.appendChild(option);
                    });
                } catch (err) {
                    console.error('Failed to load suites:', err);
                }
            }
            
            // Load keys
            async function loadKeys() {
                try {
                    const params = new URLSearchParams();
                    if (currentSuite) params.append('suite', currentSuite);
                    params.append('filter', currentFilter);
                    
                    const data = await apiFetch('/api/defaults?' + params.toString());
                    
                    // API returns array of suite objects: [{ suite: "standard", entries: [...] }]
                    // Flatten all entries into a single array
                    allKeys = [];
                    if (Array.isArray(data)) {
                        data.forEach(suiteObj => {
                            if (suiteObj.entries && Array.isArray(suiteObj.entries)) {
                                allKeys = allKeys.concat(suiteObj.entries);
                            }
                        });
                    }
                    
                    renderKeys();
                    updateStats();
                } catch (err) {
                    console.error('Failed to load keys:', err);
                    showToast('Failed to load UserDefaults', 'error');
                }
            }
            
            // Filter keys by search term (client-side)
            function getFilteredKeys() {
                if (!currentSearchTerm) return allKeys;
                const term = currentSearchTerm.toLowerCase();
                return allKeys.filter(entry => 
                    entry.key.toLowerCase().includes(term) || 
                    (entry.value || '').toLowerCase().includes(term)
                );
            }
            
            // Render key list
            function renderKeys() {
                const filtered = getFilteredKeys();
                
                if (filtered.length === 0) {
                    keyList.innerHTML = `
                        <div class="empty-state" style="padding: 32px 16px;">
                            <div class="empty-state-icon" style="font-size: 48px;">🔍</div>
                            <p class="empty-state-message" style="font-size: 13px;">
                                ${currentSearchTerm ? 'No keys match your search.' : 'No keys found.'}
                            </p>
                        </div>
                    `;
                    return;
                }
                
                keyList.innerHTML = filtered.map(entry => {
                    const isSelected = selectedKey && selectedKey.key === entry.key && selectedKey.suite === entry.suite;
                    const systemBadge = entry.isSystemKey ? '<span class="badge badge-secondary">🔒 System</span>' : '';
                    
                    return `
                        <div class="ud-key-item ${isSelected ? 'active' : ''}" 
                             data-key="${escapeHtml(entry.key)}" 
                             data-suite="${escapeHtml(entry.suite)}">
                            <div class="ud-key-name">
                                ${escapeHtml(entry.key)}
                            </div>
                            <div class="ud-key-value-preview">
                                ${escapeHtml(truncate(entry.value || '', 50))}
                            </div>
                            <div class="ud-key-meta">
                                <span class="badge">${escapeHtml(entry.type)}</span>
                                <span class="badge badge-secondary">${escapeHtml(entry.suite || 'standard')}</span>
                                ${systemBadge}
                            </div>
                        </div>
                    `;
                }).join('');
                
                // Add click listeners
                keyList.querySelectorAll('.ud-key-item').forEach(item => {
                    item.addEventListener('click', () => {
                        const key = item.dataset.key;
                        const suite = item.dataset.suite;
                        selectKey(key, suite);
                    });
                });
            }
            
            // Update stats
            function updateStats() {
                const filtered = getFilteredKeys();
                const filterName = currentFilter === 'app' ? 'App' : currentFilter === 'system' ? 'System' : 'All';
                stats.innerHTML = `
                    <span class="text-muted" style="font-size: 12px;">
                        ${filtered.length} ${filterName} key${filtered.length !== 1 ? 's' : ''}
                        ${currentSearchTerm ? '(filtered)' : ''}
                    </span>
                `;
            }
            
            // Select a key
            async function selectKey(key, suite) {
                try {
                    const params = new URLSearchParams();
                    if (suite) params.append('suite', suite);
                    
                    const entry = await apiFetch(`/api/defaults/${encodeURIComponent(key)}?` + params.toString());
                    selectedKey = entry;
                    renderEditor(entry);
                    renderKeys(); // Re-render to update selection highlight
                } catch (err) {
                    console.error('Failed to load key:', err);
                    showToast('Failed to load key details', 'error');
                }
            }
            
            // Render editor
            function renderEditor(entry) {
                const systemWarning = entry.isSystemKey ? `
                    <div class="status-message status-warning" style="margin-bottom: 16px;">
                        <span class="status-icon">⚠️</span>
                        <span>This is an iOS system key. Modifying it may affect app behavior.</span>
                    </div>
                ` : '';
                
                editor.innerHTML = `
                    <div class="ud-editor-header">
                        <div class="ud-editor-title">${escapeHtml(entry.key)}</div>
                        <div class="ud-editor-badges">
                            <span class="badge">${escapeHtml(entry.type)}</span>
                            <span class="badge badge-secondary">Suite: ${escapeHtml(entry.suite || 'standard')}</span>
                            ${entry.isSystemKey ? '<span class="badge badge-secondary">🔒 System Key</span>' : ''}
                        </div>
                    </div>
                    
                    ${systemWarning}
                    
                    <div class="ud-editor-body">
                        <label class="input-label">Value</label>
                        <textarea id="ud-value-input" class="input" style="font-family: 'SF Mono', Monaco, monospace;">${escapeHtml(entry.value || '')}</textarea>
                        
                        <label class="input-label" style="margin-top: 16px;">Type</label>
                        <select id="ud-type-input" class="input">
                            <option value="String" ${entry.type === 'String' ? 'selected' : ''}>String</option>
                            <option value="Int" ${entry.type === 'Int' ? 'selected' : ''}>Int</option>
                            <option value="Bool" ${entry.type === 'Bool' ? 'selected' : ''}>Bool</option>
                            <option value="Double" ${entry.type === 'Double' ? 'selected' : ''}>Double</option>
                            <option value="Date" ${entry.type === 'Date' ? 'selected' : ''}>Date</option>
                            <option value="Data" ${entry.type === 'Data' ? 'selected' : ''}>Data</option>
                            <option value="Array" ${entry.type === 'Array' ? 'selected' : ''}>Array</option>
                            <option value="Dictionary" ${entry.type === 'Dictionary' ? 'selected' : ''}>Dictionary</option>
                        </select>
                        
                        <div class="ud-editor-actions">
                            <button class="btn btn-primary" onclick="window.udSaveKey()">
                                💾 Save Changes
                            </button>
                            <button class="btn btn-danger" onclick="window.udDeleteKey()">
                                🗑️ Delete Key
                            </button>
                            <button class="btn btn-secondary" onclick="window.udClearSelection()">
                                Cancel
                            </button>
                        </div>
                    </div>
                    
                    <div class="ud-editor-footer">
                        <button class="btn btn-secondary" onclick="window.udCopyValue()">
                            📋 Copy Value
                        </button>
                        <button class="btn btn-secondary" onclick="window.udExportAll()">
                            📤 Export All
                        </button>
                    </div>
                `;
            }
            
            // Save key
            window.udSaveKey = async function() {
                if (!selectedKey) return;
                
                const newValue = document.getElementById('ud-value-input').value;
                const newType = document.getElementById('ud-type-input').value;
                
                try {
                    await apiFetch(`/api/defaults/${encodeURIComponent(selectedKey.key)}`, {
                        method: 'PUT',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            value: newValue,
                            type: newType,
                            suite: selectedKey.suite
                        })
                    });
                    
                    showToast('Key saved successfully', 'success');
                    await loadKeys();
                    selectKey(selectedKey.key, selectedKey.suite); // Refresh editor
                } catch (err) {
                    console.error('Failed to save key:', err);
                    showToast('Failed to save key', 'error');
                }
            };
            
            // Delete key
            window.udDeleteKey = async function() {
                if (!selectedKey) return;
                
                if (!confirm(`Are you sure you want to delete "${selectedKey.key}"?`)) {
                    return;
                }
                
                try {
                    const params = new URLSearchParams();
                    if (selectedKey.suite) params.append('suite', selectedKey.suite);
                    
                    await apiFetch(`/api/defaults/${encodeURIComponent(selectedKey.key)}?` + params.toString(), {
                        method: 'DELETE'
                    });
                    
                    showToast('Key deleted successfully', 'success');
                    selectedKey = null;
                    editor.innerHTML = `
                        <div class="empty-state">
                            <div class="empty-state-icon">👈</div>
                            <h3 class="empty-state-title">No Key Selected</h3>
                            <p class="empty-state-message">
                                Select a key from the left sidebar to view and edit its value.
                            </p>
                        </div>
                    `;
                    await loadKeys();
                } catch (err) {
                    console.error('Failed to delete key:', err);
                    showToast('Failed to delete key', 'error');
                }
            };
            
            // Clear selection
            window.udClearSelection = function() {
                selectedKey = null;
                editor.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">👈</div>
                        <h3 class="empty-state-title">No Key Selected</h3>
                        <p class="empty-state-message">
                            Select a key from the left sidebar to view and edit its value.
                        </p>
                    </div>
                `;
                renderKeys(); // Remove selection highlight
            };
            
            // Copy value
            window.udCopyValue = function() {
                if (!selectedKey) return;
                const value = document.getElementById('ud-value-input').value;
                copyToClipboard(value, 'Value copied to clipboard');
            };
            
            // Export all
            window.udExportAll = function() {
                window.open('/api/export', '_blank');
            };
            
            // Event listeners
            suiteSelect.addEventListener('change', (e) => {
                currentSuite = e.target.value;
                loadKeys();
            });
            
            filterButtons.forEach(btn => {
                btn.addEventListener('click', (e) => {
                    filterButtons.forEach(b => b.classList.remove('active'));
                    e.target.classList.add('active');
                    currentFilter = e.target.dataset.filter;
                    loadKeys();
                });
            });
            
            // Search with debounce
            let searchTimeout;
            searchInput.addEventListener('input', (e) => {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(() => {
                    currentSearchTerm = e.target.value;
                    renderKeys();
                    updateStats();
                }, 300);
            });
            
            // Initial load
            loadSuites();
            loadKeys();
            
            // Start polling
            pollingInterval = setInterval(loadKeys, 3000);
            registerPolling(pollingInterval);
        }
        
        function initDatabase() {
            stopAllPolling();
            console.log('Database page initialized');
            
            let selectedDbPath = null;
            let selectedTable = null;
            let currentTab = 'browse';
            let currentPage = 1;
            let totalPages = 1;
            const pageSize = 50;
            
            const dbList = document.getElementById('db-list');
            const tableList = document.getElementById('db-table-list');
            const tabContent = document.getElementById('db-tab-content');
            const tabsBar = document.getElementById('db-tabs');
            const pagination = document.getElementById('db-pagination');
            const pageInfo = document.getElementById('db-page-info');
            const prevBtn = document.getElementById('db-prev-btn');
            const nextBtn = document.getElementById('db-next-btn');
            
            // Tab switching
            document.querySelectorAll('.db-tab').forEach(tab => {
                tab.addEventListener('click', () => {
                    document.querySelectorAll('.db-tab').forEach(t => t.classList.remove('active'));
                    tab.classList.add('active');
                    currentTab = tab.dataset.tab;
                    loadTabContent();
                });
            });
            
            prevBtn.addEventListener('click', () => {
                if (currentPage > 1) { currentPage--; loadBrowseData(); }
            });
            nextBtn.addEventListener('click', () => {
                if (currentPage < totalPages) { currentPage++; loadBrowseData(); }
            });
            
            // Fetch databases
            async function fetchDatabases() {
                try {
                    const data = await apiFetch('/api/databases');
                    if (!data || data.length === 0) {
                        dbList.innerHTML = '<div class="empty-state" style="padding: 24px 12px;"><div class="empty-state-icon" style="font-size: 36px;">🗄️</div><p class="empty-state-message" style="font-size: 12px;">No databases found. Create one from the example app.</p></div>';
                        return;
                    }
                    
                    dbList.innerHTML = data.map(db => `
                        <div class="db-card ${selectedDbPath === db.path ? 'active' : ''}" data-path="${escapeHtml(db.path)}">
                            <div class="db-card-name">${escapeHtml(db.name)}</div>
                            <div class="db-card-meta">
                                <span>${db.sizeFormatted}</span>
                                <span>${db.tableCount} table${db.tableCount !== 1 ? 's' : ''}</span>
                            </div>
                        </div>
                    `).join('');
                    
                    dbList.querySelectorAll('.db-card').forEach(card => {
                        card.addEventListener('click', () => selectDatabase(card.dataset.path));
                    });
                } catch (err) {
                    console.error('Failed to load databases:', err);
                }
            }
            
            // Select database
            async function selectDatabase(path) {
                selectedDbPath = path;
                selectedTable = null;
                currentPage = 1;
                
                // Update DB list selection
                dbList.querySelectorAll('.db-card').forEach(c => c.classList.remove('active'));
                const active = dbList.querySelector(`[data-path="${CSS.escape(path)}"]`);
                if (active) active.classList.add('active');
                
                // Fetch tables
                try {
                    const data = await apiFetch('/api/databases/tables?dbPath=' + encodeURIComponent(path));
                    const tables = data.tables || [];
                    
                    if (tables.length === 0) {
                        tableList.innerHTML = '<div class="empty-state" style="padding: 24px 12px;"><p class="empty-state-message" style="font-size: 12px;">No tables found</p></div>';
                        tabsBar.style.display = 'none';
                        pagination.style.display = 'none';
                        return;
                    }
                    
                    tableList.innerHTML = tables.map(t => `
                        <div class="db-table-item" data-table="${escapeHtml(t)}">
                            <span>📋 ${escapeHtml(t)}</span>
                        </div>
                    `).join('');
                    
                    tableList.querySelectorAll('.db-table-item').forEach(item => {
                        item.addEventListener('click', () => selectTable(item.dataset.table));
                    });
                } catch (err) {
                    console.error('Failed to load tables:', err);
                    showToast('Failed to load tables', 'error');
                }
            }
            
            // Select table
            function selectTable(table) {
                selectedTable = table;
                currentPage = 1;
                
                tableList.querySelectorAll('.db-table-item').forEach(i => i.classList.remove('active'));
                const active = tableList.querySelector(`[data-table="${CSS.escape(table)}"]`);
                if (active) active.classList.add('active');
                
                tabsBar.style.display = 'flex';
                loadTabContent();
            }
            
            // Load content for current tab
            function loadTabContent() {
                if (!selectedDbPath || !selectedTable) return;
                
                switch (currentTab) {
                    case 'browse': loadBrowseData(); break;
                    case 'schema': loadSchema(); break;
                    case 'sql': loadSQLConsole(); break;
                }
            }
            
            // -----------------------------------------------
            // Cell Value Modal
            // -----------------------------------------------
            function showCellModal(colName, rawValue) {
                // Remove existing modal if any
                const existing = document.getElementById('db-cell-modal-overlay');
                if (existing) existing.remove();
                
                const isNull = rawValue === null || rawValue === undefined;
                const displayValue = isNull ? 'NULL' : String(rawValue);
                
                // Try to pretty-print JSON
                let formatted = displayValue;
                let isJSON = false;
                if (!isNull) {
                    try {
                        const parsed = JSON.parse(displayValue);
                        formatted = JSON.stringify(parsed, null, 2);
                        isJSON = true;
                    } catch (_) {}
                }
                
                const overlay = document.createElement('div');
                overlay.id = 'db-cell-modal-overlay';
                overlay.className = 'db-cell-modal-overlay';
                overlay.innerHTML = `
                    <div class="db-cell-modal">
                        <div class="db-cell-modal-header">
                            <div>
                                <div class="db-cell-modal-title">${escapeHtml(colName)}</div>
                                <div class="db-cell-modal-meta">
                                    ${isNull ? 'NULL value' : isJSON ? 'JSON • ' + displayValue.length + ' chars' : displayValue.length + ' chars'}
                                </div>
                            </div>
                            <button class="btn btn-sm btn-secondary" id="db-modal-close-btn">✕ Close</button>
                        </div>
                        <div class="db-cell-modal-body">
                            <pre class="db-cell-modal-value">${isNull ? '<span style="color: var(--text-muted); font-style: italic;">NULL</span>' : escapeHtml(formatted)}</pre>
                        </div>
                        <div class="db-cell-modal-footer">
                            ${!isNull ? '<button class="btn btn-secondary" id="db-modal-copy-btn">📋 Copy Value</button>' : ''}
                            ${isJSON ? '<button class="btn btn-secondary" id="db-modal-copy-formatted-btn">📋 Copy Formatted</button>' : ''}
                        </div>
                    </div>
                `;
                
                // Prevent clicks inside modal from closing it
                overlay.querySelector('.db-cell-modal').addEventListener('click', (e) => e.stopPropagation());
                // Close button
                overlay.querySelector('#db-modal-close-btn').addEventListener('click', () => overlay.remove());
                // Copy buttons
                const copyBtn = overlay.querySelector('#db-modal-copy-btn');
                if (copyBtn) copyBtn.addEventListener('click', () => copyToClipboard(displayValue, 'Copied!'));
                const copyFmtBtn = overlay.querySelector('#db-modal-copy-formatted-btn');
                if (copyFmtBtn) copyFmtBtn.addEventListener('click', () => copyToClipboard(formatted, 'Copied formatted JSON!'));
                // Click outside to close
                overlay.addEventListener('click', () => overlay.remove());
                // Escape to close
                const handler = (e) => { if (e.key === 'Escape') { overlay.remove(); document.removeEventListener('keydown', handler); } };
                document.addEventListener('keydown', handler);
                
                document.body.appendChild(overlay);
            }
            
            // -----------------------------------------------
            // Edit Row Modal
            // -----------------------------------------------
            function showEditModal(columns, rowData, tableName, rowid) {
                // Remove existing modal
                const existing = document.getElementById('db-edit-modal-overlay');
                if (existing) existing.remove();
                
                const overlay = document.createElement('div');
                overlay.id = 'db-edit-modal-overlay';
                overlay.className = 'db-edit-modal-overlay';
                
                let fieldsHTML = '';
                columns.forEach((col, idx) => {
                    const val = rowData[idx];
                    const isNull = val === null || val === undefined;
                    const displayVal = isNull ? '' : String(val);
                    const needsTextarea = displayVal.length > 60 || displayVal.includes('\\n');
                    
                    fieldsHTML += '<div class="db-edit-field">';
                    fieldsHTML += '<div class="db-edit-field-label">';
                    fieldsHTML += '<span class="db-edit-field-name">' + escapeHtml(col) + '</span>';
                    fieldsHTML += '</div>';
                    
                    if (needsTextarea) {
                        fieldsHTML += '<textarea class="db-edit-field-input" data-col="' + escapeHtml(col) + '" rows="3"' + (isNull ? ' disabled placeholder="NULL"' : '') + '>' + escapeHtml(displayVal) + '</textarea>';
                    } else {
                        fieldsHTML += '<input class="db-edit-field-input" type="text" data-col="' + escapeHtml(col) + '" value="' + escapeHtml(displayVal) + '"' + (isNull ? ' disabled placeholder="NULL"' : '') + '>';
                    }
                    
                    fieldsHTML += '<div class="db-edit-null-toggle">';
                    fieldsHTML += '<input type="checkbox" id="null-' + idx + '" data-col-idx="' + idx + '"' + (isNull ? ' checked' : '') + '>';
                    fieldsHTML += '<label for="null-' + idx + '">Set NULL</label>';
                    fieldsHTML += '</div>';
                    fieldsHTML += '</div>';
                });
                
                overlay.innerHTML = '<div class="db-edit-modal">'
                    + '<div class="db-edit-modal-header">'
                    + '<div>'
                    + '<div class="db-edit-modal-title">Edit Row</div>'
                    + '<div class="db-edit-modal-subtitle">' + escapeHtml(tableName || 'Unknown table') + (rowid != null ? ' • rowid ' + rowid : '') + '</div>'
                    + '</div>'
                    + '<button class="btn btn-sm btn-secondary" id="db-edit-close-btn">✕ Close</button>'
                    + '</div>'
                    + '<div class="db-edit-modal-body">' + fieldsHTML + '</div>'
                    + '<div class="db-edit-modal-footer">'
                    + '<button class="btn btn-secondary" id="db-edit-cancel-btn">Cancel</button>'
                    + '<button class="btn btn-primary" id="db-edit-submit-btn">💾 Save Changes</button>'
                    + '</div>'
                    + '</div>';
                
                document.body.appendChild(overlay);
                
                // Prevent clicks inside modal from closing
                overlay.querySelector('.db-edit-modal').addEventListener('click', (e) => e.stopPropagation());
                
                // Close handlers
                const closeModal = () => overlay.remove();
                overlay.addEventListener('click', closeModal);
                overlay.querySelector('#db-edit-close-btn').addEventListener('click', closeModal);
                overlay.querySelector('#db-edit-cancel-btn').addEventListener('click', closeModal);
                const escHandler = (e) => { if (e.key === 'Escape') { closeModal(); document.removeEventListener('keydown', escHandler); } };
                document.addEventListener('keydown', escHandler);
                
                // NULL toggle logic
                overlay.querySelectorAll('.db-edit-null-toggle input[type="checkbox"]').forEach(cb => {
                    cb.addEventListener('change', () => {
                        const colIdx = parseInt(cb.dataset.colIdx);
                        const input = overlay.querySelector('.db-edit-field-input[data-col="' + CSS.escape(columns[colIdx]) + '"]');
                        if (cb.checked) {
                            input.disabled = true;
                            input.value = '';
                            input.placeholder = 'NULL';
                        } else {
                            input.disabled = false;
                            input.placeholder = '';
                            input.focus();
                        }
                    });
                });
                
                // Submit handler
                overlay.querySelector('#db-edit-submit-btn').addEventListener('click', async () => {
                    const updates = {};
                    let hasChanges = false;
                    
                    columns.forEach((col, idx) => {
                        const nullCb = overlay.querySelector('#null-' + idx);
                        const input = overlay.querySelector('.db-edit-field-input[data-col="' + CSS.escape(col) + '"]');
                        const originalVal = rowData[idx];
                        const originalIsNull = originalVal === null || originalVal === undefined;
                        
                        if (nullCb.checked) {
                            if (!originalIsNull) {
                                updates[col] = null;
                                hasChanges = true;
                            }
                        } else {
                            const newVal = input.value;
                            if (originalIsNull || newVal !== String(originalVal)) {
                                updates[col] = newVal;
                                hasChanges = true;
                            }
                        }
                    });
                    
                    if (!hasChanges) {
                        showToast('No changes detected', 'error');
                        return;
                    }
                    
                    if (!selectedDbPath) {
                        showToast('No database selected', 'error');
                        return;
                    }
                    
                    const submitBtn = overlay.querySelector('#db-edit-submit-btn');
                    submitBtn.disabled = true;
                    submitBtn.textContent = 'Saving...';
                    
                    try {
                        if (rowid != null && tableName) {
                            // Direct update via rowid
                            const result = await apiFetch('/api/databases/update-row', {
                                method: 'POST',
                                body: JSON.stringify({
                                    dbPath: selectedDbPath,
                                    table: tableName,
                                    rowid: rowid,
                                    updates: updates
                                })
                            });
                            
                            if (result.error) {
                                showToast('Update failed: ' + result.error, 'error');
                                submitBtn.disabled = false;
                                submitBtn.textContent = '💾 Save Changes';
                                return;
                            }
                            
                            showToast('Row updated successfully');
                            closeModal();
                            // Refresh data
                            if (currentTab === 'browse') loadBrowseData();
                        } else {
                            // Fallback: no rowid (SQL console result) — build UPDATE query
                            const setClauses = Object.entries(updates).map(([col, val]) => {
                                if (val === null) return col + ' = NULL';
                                return col + " = '" + String(val).replace(/'/g, "''") + "'";
                            }).join(', ');
                            
                            // Build WHERE from original values
                            const whereClauses = columns.map((col, idx) => {
                                const val = rowData[idx];
                                if (val === null || val === undefined) return col + ' IS NULL';
                                return col + " = '" + String(val).replace(/'/g, "''") + "'";
                            }).join(' AND ');
                            
                            const updateSQL = 'UPDATE ' + tableName + ' SET ' + setClauses + ' WHERE ' + whereClauses + ' LIMIT 1';
                            
                            // Execute as raw SQL (need write access)
                            const result = await apiFetch('/api/databases/execute-update', {
                                method: 'POST',
                                body: JSON.stringify({
                                    dbPath: selectedDbPath,
                                    sql: updateSQL
                                })
                            });
                            
                            if (result.error) {
                                showToast('Update failed: ' + result.error, 'error');
                                submitBtn.disabled = false;
                                submitBtn.textContent = '💾 Save Changes';
                                return;
                            }
                            
                            showToast('Row updated successfully');
                            closeModal();
                            // Re-run the query to refresh
                            executeQuery();
                        }
                    } catch (err) {
                        showToast('Update failed: ' + err.message, 'error');
                        submitBtn.disabled = false;
                        submitBtn.textContent = '💾 Save Changes';
                    }
                });
            }
            
            // -----------------------------------------------
            // Shared table renderer — used by Browse and SQL
            // opts: { editable, tableName, rowids }
            // -----------------------------------------------
            function renderDataTable(columns, rows, opts = {}) {
                const editable = opts.editable || false;
                let html = '<table class="db-data-table"><thead><tr>';
                columns.forEach(col => {
                    html += `<th>${escapeHtml(col)}</th>`;
                });
                if (editable) html += '<th class="db-edit-header">Edit</th>';
                html += '</tr></thead><tbody>';
                
                rows.forEach((row, rowIdx) => {
                    html += '<tr>';
                    row.forEach((val, colIdx) => {
                        if (val === null || val === undefined) {
                            html += `<td class="null-value" data-row="${rowIdx}" data-col="${colIdx}">NULL</td>`;
                        } else {
                            const truncated = truncate(String(val), 40);
                            const isTruncated = truncated.length < String(val).length;
                            html += `<td data-row="${rowIdx}" data-col="${colIdx}" ${isTruncated ? 'style="font-style: italic;"' : ''}>${escapeHtml(truncated)}${isTruncated ? ' <span style="color: var(--text-muted); font-size: 10px;">↗</span>' : ''}</td>`;
                        }
                    });
                    if (editable) html += `<td class="db-edit-cell" data-row="${rowIdx}"><button class="db-edit-btn" title="Edit row">✏️</button></td>`;
                    html += '</tr>';
                });
                html += '</tbody></table>';
                
                return {
                    html,
                    bindCells(container) {
                        container.querySelectorAll('td[data-col]').forEach(td => {
                            td.addEventListener('click', () => {
                                const colIdx = parseInt(td.dataset.col);
                                const rowIdx = parseInt(td.dataset.row);
                                const colName = columns[colIdx] || 'column';
                                const rawValue = rows[rowIdx][colIdx];
                                showCellModal(colName, rawValue);
                            });
                        });
                        if (editable) {
                            container.querySelectorAll('.db-edit-cell').forEach(cell => {
                                cell.addEventListener('click', (e) => {
                                    e.stopPropagation();
                                    const rowIdx = parseInt(cell.dataset.row);
                                    showEditModal(columns, rows[rowIdx], opts.tableName, opts.rowids ? opts.rowids[rowIdx] : null);
                                });
                            });
                        }
                    }
                };
            }
            
            // Browse Data tab
            async function loadBrowseData() {
                if (!selectedDbPath || !selectedTable) return;
                
                try {
                    const params = new URLSearchParams({
                        dbPath: selectedDbPath,
                        table: selectedTable,
                        page: currentPage,
                        pageSize: pageSize
                    });
                    const data = await apiFetch('/api/databases/table-data?' + params.toString());
                    
                    totalPages = data.totalPages || 1;
                    
                    if (data.columns.length === 0) {
                        tabContent.innerHTML = '<div class="db-tab-padded"><div class="empty-state"><p class="empty-state-message">Table is empty</p></div></div>';
                        pagination.style.display = 'none';
                        return;
                    }
                    
                    // Use a dedicated scroll container — no padding here, padding breaks sticky headers
                    tabContent.innerHTML = '<div class="db-grid-scroll" id="db-grid-scroll"></div>';
                    const grid = document.getElementById('db-grid-scroll');
                    
                    const { html, bindCells } = renderDataTable(data.columns, data.rows, {
                        editable: true,
                        tableName: selectedTable,
                        rowids: data.rowids
                    });
                    grid.innerHTML = html;
                    bindCells(grid);
                    
                    // Update pagination
                    pagination.style.display = 'flex';
                    pageInfo.textContent = `Page ${data.page} of ${totalPages} (${data.totalRows.toLocaleString()} rows)`;
                    prevBtn.disabled = currentPage <= 1;
                    nextBtn.disabled = currentPage >= totalPages;
                    
                } catch (err) {
                    console.error('Failed to load table data:', err);
                    showToast('Failed to load table data', 'error');
                }
            }
            
            // Schema tab
            async function loadSchema() {
                if (!selectedDbPath || !selectedTable) return;
                
                try {
                    const params = new URLSearchParams({ dbPath: selectedDbPath, table: selectedTable });
                    const data = await apiFetch('/api/databases/table-info?' + params.toString());
                    
                    let html = '<div class="db-tab-padded">';
                    html += '<div style="margin-bottom: 16px;">';
                    html += `<h3 style="color: var(--text-primary); margin-bottom: 4px;">${escapeHtml(data.name)}</h3>`;
                    html += `<span class="text-muted" style="font-size: 13px;">${data.rowCount.toLocaleString()} rows • ${data.columns.length} columns</span>`;
                    html += '</div>';
                    
                    data.columns.forEach(col => {
                        html += `<div class="db-schema-col">`;
                        html += `<span class="db-schema-col-name">${escapeHtml(col.name)}</span>`;
                        html += `<span class="badge">${escapeHtml(col.type || 'ANY')}</span>`;
                        if (col.isPrimaryKey) html += '<span class="badge" style="background: var(--accent-primary); color: white;">PK</span>';
                        if (!col.isNullable) html += '<span class="badge badge-secondary">NOT NULL</span>';
                        if (col.defaultValue) html += `<span class="badge badge-secondary">Default: ${escapeHtml(col.defaultValue)}</span>`;
                        html += '</div>';
                    });
                    
                    html += '</div>';
                    tabContent.innerHTML = html;
                    pagination.style.display = 'none';
                } catch (err) {
                    console.error('Failed to load schema:', err);
                    showToast('Failed to load schema', 'error');
                }
            }
            
            // SQL Console tab
            function loadSQLConsole() {
                pagination.style.display = 'none';
                
                tabContent.innerHTML = `
                    <div class="db-tab-padded db-sql-console">
                        <textarea id="db-sql-input" class="input db-sql-input" placeholder="SELECT * FROM ${escapeHtml(selectedTable || 'table_name')} LIMIT 10;"></textarea>
                        <div class="db-sql-actions">
                            <button class="btn btn-primary" id="db-sql-run">▶️ Execute</button>
                            <span class="db-sql-timing" id="db-sql-timing"></span>
                        </div>
                        <div class="db-sql-results" id="db-sql-results">
                            <div class="empty-state" style="padding: 24px;">
                                <p class="empty-state-message" style="font-size: 13px;">Write a SELECT query and click Execute<br><span style="color: var(--text-muted); font-size: 11px;">Tip: Cmd+Enter to run</span></p>
                            </div>
                        </div>
                    </div>
                `;
                
                document.getElementById('db-sql-run').addEventListener('click', executeQuery);
                document.getElementById('db-sql-input').addEventListener('keydown', (e) => {
                    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') executeQuery();
                });
            }
            
            // Execute SQL query
            async function executeQuery() {
                const sqlInput = document.getElementById('db-sql-input');
                const resultsDiv = document.getElementById('db-sql-results');
                const timingSpan = document.getElementById('db-sql-timing');
                const sql = sqlInput.value.trim();
                
                if (!sql) { showToast('Enter a SQL query', 'error'); return; }
                if (!selectedDbPath) { showToast('Select a database first', 'error'); return; }
                
                resultsDiv.innerHTML = '<p class="text-muted" style="padding: 16px;">Executing...</p>';
                
                try {
                    const data = await apiFetch('/api/databases/query', {
                        method: 'POST',
                        body: JSON.stringify({ dbPath: selectedDbPath, sql: sql })
                    });
                    
                    if (data.error) {
                        resultsDiv.innerHTML = `<div class="status-message status-error" style="margin: 8px 0;"><span class="status-icon">❌</span><span>${escapeHtml(data.error)}</span></div>`;
                        timingSpan.textContent = '';
                        return;
                    }
                    
                    timingSpan.textContent = `${data.rowCount} rows in ${data.executionTimeMs}ms`;
                    
                    if (data.columns.length === 0) {
                        resultsDiv.innerHTML = '<p class="text-muted" style="padding: 8px;">Query returned no results.</p>';
                        return;
                    }
                    
                    // Try to detect table name from SQL for edit support
                    const tableMatch = sql.match(/FROM\\s+([\\w]+)/i);
                    const detectedTable = tableMatch ? tableMatch[1] : selectedTable;
                    
                    const { html, bindCells } = renderDataTable(data.columns, data.rows, {
                        editable: !!detectedTable,
                        tableName: detectedTable,
                        rowids: null
                    });
                    resultsDiv.innerHTML = html;
                    bindCells(resultsDiv);
                } catch (err) {
                    resultsDiv.innerHTML = `<div class="status-message status-error"><span>❌ ${escapeHtml(err.message)}</span></div>`;
                    timingSpan.textContent = '';
                }
            }
            
            // Initial load
            fetchDatabases();
        }
        
        function initNetwork() {
            stopAllPolling();
            console.log('Network page initialized');
            
            let allRequests = [];
            let selectedRequestId = null;
            let currentDetailTab = 'request';
            
            const netList = document.getElementById('net-list');
            const detailPanel = document.getElementById('net-detail-panel');
            const filterPath = document.getElementById('net-filter-path');
            const filterMethod = document.getElementById('net-filter-method');
            const clearBtn = document.getElementById('net-clear-btn');
            const listCount = document.getElementById('net-list-count');
            
            // Stats elements
            const statTotal = document.getElementById('net-stat-total');
            const statSuccess = document.getElementById('net-stat-success');
            const statError = document.getElementById('net-stat-error');
            const statIntercepted = document.getElementById('net-stat-intercepted');
            const statAvg = document.getElementById('net-stat-avg');
            
            // Filters
            filterPath.addEventListener('input', renderList);
            filterMethod.addEventListener('change', renderList);
            
            // Clear button
            clearBtn.addEventListener('click', async () => {
                try {
                    await apiFetch('/api/network', { method: 'DELETE' });
                    allRequests = [];
                    selectedRequestId = null;
                    renderList();
                    renderDetail();
                    loadStats();
                    showToast('Network log cleared');
                } catch (e) {
                    showToast('Failed to clear', 'error');
                }
            });
            
            function getMethodClass(method) {
                switch(method.toUpperCase()) {
                    case 'GET': return 'net-method-get';
                    case 'POST': return 'net-method-post';
                    case 'PUT': return 'net-method-put';
                    case 'DELETE': return 'net-method-delete';
                    case 'PATCH': return 'net-method-patch';
                    default: return 'net-method-other';
                }
            }
            
            function getStatusClass(statusCode, state) {
                if (state === 'intercepted') return 'net-status-intercepted';
                if (state === 'pending' || state === 'failed') return 'net-status-pending';
                if (statusCode >= 200 && statusCode < 300) return 'net-status-2xx';
                if (statusCode >= 300 && statusCode < 400) return 'net-status-3xx';
                if (statusCode >= 400 && statusCode < 500) return 'net-status-4xx';
                if (statusCode >= 500) return 'net-status-5xx';
                return 'net-status-pending';
            }
            
            function getStatusText(statusCode, state) {
                if (state === 'intercepted') return 'MOCK';
                if (state === 'pending') return '...';
                if (state === 'failed') return 'ERR';
                return String(statusCode);
            }
            
            function formatDuration(ms) {
                if (ms === null || ms === undefined) return '';
                if (ms < 1) return '<1ms';
                if (ms < 1000) return Math.round(ms) + 'ms';
                return (ms / 1000).toFixed(1) + 's';
            }
            
            function filteredRequests() {
                const pathFilter = filterPath.value.toLowerCase();
                const methodFilter = filterMethod.value;
                
                return allRequests.filter(r => {
                    if (pathFilter && !r.url.toLowerCase().includes(pathFilter) && !r.path.toLowerCase().includes(pathFilter)) return false;
                    if (methodFilter && r.method !== methodFilter) return false;
                    return true;
                });
            }
            
            function renderList() {
                const filtered = filteredRequests();
                listCount.textContent = filtered.length + ' request' + (filtered.length !== 1 ? 's' : '');
                
                if (filtered.length === 0) {
                    netList.innerHTML = '<div class="empty-state" style="padding: 40px 16px;"><div class="empty-state-icon" style="font-size: 32px;">🌐</div><p class="empty-state-message" style="font-size: 12px;">No captured requests yet.<br>Make HTTP requests from your app.</p></div>';
                    return;
                }
                
                netList.innerHTML = filtered.map(r => {
                    const isActive = r.id === selectedRequestId;
                    return '<div class="net-item' + (isActive ? ' active' : '') + '" data-id="' + r.id + '">'
                        + '<span class="net-item-method ' + getMethodClass(r.method) + '">' + escapeHtml(r.method) + '</span>'
                        + '<div class="net-item-info">'
                        + '<div class="net-item-path">' + escapeHtml(r.path || '/') + '</div>'
                        + '<div class="net-item-host">' + escapeHtml(r.host) + '</div>'
                        + '</div>'
                        + '<div class="net-item-meta">'
                        + '<span class="net-status-badge ' + getStatusClass(r.statusCode, r.state) + '">' + getStatusText(r.statusCode, r.state) + '</span>'
                        + '<span class="net-item-duration">' + formatDuration(r.duration) + '</span>'
                        + '</div>'
                        + '</div>';
                }).join('');
                
                // Bind click
                netList.querySelectorAll('.net-item').forEach(el => {
                    el.addEventListener('click', () => {
                        selectedRequestId = el.dataset.id;
                        renderList();
                        loadDetail(el.dataset.id);
                    });
                });
            }
            
            async function loadStats() {
                try {
                    const data = await apiFetch('/api/network/stats');
                    statTotal.textContent = data.totalRequests;
                    statSuccess.textContent = data.successCount;
                    statError.textContent = data.errorCount;
                    statIntercepted.textContent = data.interceptedCount;
                    statAvg.textContent = formatDuration(data.avgResponseTime);
                } catch (e) {}
            }
            
            async function loadRequests() {
                try {
                    const data = await apiFetch('/api/network');
                    allRequests = data || [];
                    renderList();
                    loadStats();
                } catch (e) {
                    console.error('Failed to load network data:', e);
                }
            }
            
            async function loadDetail(id) {
                try {
                    const data = await apiFetch('/api/network/' + id);
                    renderDetailView(data);
                } catch (e) {
                    detailPanel.innerHTML = '<div class="empty-state" style="margin: auto;"><p class="empty-state-message">Failed to load request details</p></div>';
                }
            }
            
            function renderDetailView(entry) {
                let html = '<div class="net-detail-header">';
                html += '<div class="net-detail-url"><span class="net-item-method ' + getMethodClass(entry.method) + '" style="margin-right: 8px;">' + escapeHtml(entry.method) + '</span>' + escapeHtml(entry.url) + '</div>';
                html += '</div>';
                
                html += '<div class="net-detail-tabs">';
                html += '<div class="net-detail-tab' + (currentDetailTab === 'request' ? ' active' : '') + '" data-tab="request">Request</div>';
                html += '<div class="net-detail-tab' + (currentDetailTab === 'response' ? ' active' : '') + '" data-tab="response">Response</div>';
                html += '<div class="net-detail-tab' + (currentDetailTab === 'curl' ? ' active' : '') + '" data-tab="curl">cURL</div>';
                html += '</div>';
                
                html += '<div class="net-detail-body">';
                
                if (currentDetailTab === 'request') {
                    html += '<h4 style="color: var(--text-secondary); font-size: 11px; text-transform: uppercase; margin-bottom: 8px;">Headers</h4>';
                    html += renderHeadersTable(entry.requestHeaders || {});
                    if (entry.requestBody) {
                        html += '<h4 style="color: var(--text-secondary); font-size: 11px; text-transform: uppercase; margin: 16px 0 8px;">Body (' + formatBytes(entry.requestBodySize) + ')</h4>';
                        html += '<pre class="net-body-pre">' + escapeHtml(tryPrettyJSON(entry.requestBody)) + '</pre>';
                    }
                } else if (currentDetailTab === 'response') {
                    html += '<div style="margin-bottom: 12px;">';
                    html += '<span class="net-status-badge ' + getStatusClass(entry.statusCode, entry.state) + '" style="font-size: 13px; padding: 3px 10px;">' + entry.statusCode + ' ' + entry.state + '</span>';
                    if (entry.duration) html += '<span style="color: var(--text-muted); font-size: 12px; margin-left: 12px;">' + formatDuration(entry.duration) + '</span>';
                    html += '</div>';
                    html += '<h4 style="color: var(--text-secondary); font-size: 11px; text-transform: uppercase; margin-bottom: 8px;">Headers</h4>';
                    html += renderHeadersTable(entry.responseHeaders || {});
                    if (entry.responseBody) {
                        html += '<h4 style="color: var(--text-secondary); font-size: 11px; text-transform: uppercase; margin: 16px 0 8px;">Body (' + formatBytes(entry.responseBodySize) + ')</h4>';
                        html += '<pre class="net-body-pre">' + escapeHtml(tryPrettyJSON(entry.responseBody)) + '</pre>';
                    }
                    if (entry.errorMessage) {
                        html += '<div class="status-message status-error" style="margin-top: 12px;"><span class="status-icon">❌</span><span>' + escapeHtml(entry.errorMessage) + '</span></div>';
                    }
                } else if (currentDetailTab === 'curl') {
                    if (entry.curlCommand) {
                        html += '<div style="display: flex; justify-content: flex-end; margin-bottom: 8px;"><button class="btn btn-sm btn-secondary" id="net-copy-curl">📋 Copy</button></div>';
                        html += '<pre class="net-body-pre">' + escapeHtml(entry.curlCommand) + '</pre>';
                    } else {
                        html += '<p class="text-muted" style="padding: 16px;">cURL command not available yet (request may still be pending)</p>';
                    }
                }
                
                html += '</div>';
                detailPanel.innerHTML = html;
                
                // Bind detail tabs
                detailPanel.querySelectorAll('.net-detail-tab').forEach(tab => {
                    tab.addEventListener('click', () => {
                        currentDetailTab = tab.dataset.tab;
                        renderDetailView(entry);
                    });
                });
                
                // Copy cURL
                const copyBtn = detailPanel.querySelector('#net-copy-curl');
                if (copyBtn) {
                    copyBtn.addEventListener('click', () => copyToClipboard(entry.curlCommand, 'cURL copied!'));
                }
            }
            
            function renderDetail() {
                if (!selectedRequestId) {
                    detailPanel.innerHTML = '<div class="empty-state" style="margin: auto;"><div class="empty-state-icon">👈</div><p class="empty-state-message">Select a request to view details</p></div>';
                }
            }
            
            function renderHeadersTable(headers) {
                const entries = Object.entries(headers);
                if (entries.length === 0) return '<p class="text-muted" style="font-size: 12px;">No headers</p>';
                let html = '<table class="net-headers-table"><tbody>';
                entries.sort((a, b) => a[0].localeCompare(b[0]));
                entries.forEach(([key, val]) => {
                    html += '<tr><td>' + escapeHtml(key) + '</td><td>' + escapeHtml(val) + '</td></tr>';
                });
                html += '</tbody></table>';
                return html;
            }
            
            function tryPrettyJSON(str) {
                try {
                    return JSON.stringify(JSON.parse(str), null, 2);
                } catch (e) {
                    return str;
                }
            }
            
            function formatBytes(bytes) {
                if (!bytes || bytes === 0) return '0 B';
                if (bytes < 1024) return bytes + ' B';
                if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
                return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
            }
            
            // Initial load + polling
            loadRequests();
            const pollInterval = setInterval(loadRequests, 3000);
            registerPolling(pollInterval);
        }
        
        // ========================================
        // Interceptor Page
        // ========================================
        let interceptorRules = [];
        let interceptorEnabled = false;
        
        function initInterceptor() {
            stopAllPolling();
            console.log('Interceptor page initialized');
            fetchInterceptorStatus();
            fetchInterceptorRules();
            startPolling('interceptor', fetchInterceptorRules, 3000);
        }
        
        async function fetchInterceptorStatus() {
            const data = await apiFetch('/api/interceptor/status');
            if (!data) return;
            interceptorEnabled = data.isEnabled;
            updateToggleUI();
            const countEl = document.getElementById('interceptor-active-count');
            if (countEl) countEl.textContent = data.activeRuleCount + ' active';
        }
        
        function updateToggleUI() {
            const btn = document.getElementById('interceptor-master-toggle');
            const label = document.getElementById('interceptor-status-label');
            if (btn) btn.classList.toggle('active', interceptorEnabled);
            if (label) label.textContent = interceptorEnabled ? 'On' : 'Off';
        }
        
        async function toggleInterceptorMaster() {
            const data = await apiFetch('/api/interceptor/toggle', { method: 'POST' });
            if (!data) return;
            interceptorEnabled = data.isEnabled;
            updateToggleUI();
            showToast(interceptorEnabled ? 'Interceptor ON' : 'Interceptor OFF');
            fetchInterceptorStatus();
        }
        
        async function fetchInterceptorRules() {
            const rules = await apiFetch('/api/interceptor/rules');
            if (!rules) return;
            interceptorRules = rules;
            renderRuleList(rules);
        }
        
        function renderRuleList(rules) {
            const listEl = document.getElementById('interceptor-rule-list');
            const emptyEl = document.getElementById('interceptor-empty');
            if (!listEl) return;
            if (rules.length === 0) {
                listEl.innerHTML = '';
                if (emptyEl) emptyEl.style.display = 'flex';
                return;
            }
            if (emptyEl) emptyEl.style.display = 'none';
            const statusColor = (code) => {
                if (code >= 200 && code < 300) return 'var(--accent-success)';
                if (code >= 300 && code < 400) return '#f59e0b';
                return 'var(--error)';
            };
            const methodColor = (m) => ({
                'GET': 'var(--accent-success)', 'POST': 'var(--accent-primary)',
                'PUT': '#f59e0b', 'DELETE': 'var(--error)', 'PATCH': '#8b5cf6', 'ANY': 'var(--text-muted)'
            })[m.toUpperCase()] || 'var(--text-muted)';
            listEl.innerHTML = rules.map(rule => `
                <div class="net-rule-card ${rule.isEnabled ? '' : 'disabled'}" style="cursor:pointer;" onclick="openRuleForm('${rule.id}')">
                    <div class="net-rule-header">
                        <div style="display:flex;align-items:center;gap:10px;flex:1;min-width:0;">
                            <span style="width:8px;height:8px;border-radius:50%;flex-shrink:0;background:${rule.isEnabled ? 'var(--accent-success)' : 'var(--text-muted)'};display:inline-block;"></span>
                            <span class="net-rule-label" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${escapeHtml(rule.label || 'Unnamed Rule')}</span>
                        </div>
                        <div class="net-rule-actions" onclick="event.stopPropagation()">
                            <button class="net-toggle-btn ${rule.isEnabled ? 'active' : ''}" style="width:36px;height:20px;" title="${rule.isEnabled ? 'Disable rule' : 'Enable rule'}" onclick="toggleRule('${rule.id}')"></button>
                            <button class="btn btn-danger" style="font-size:11px;padding:3px 8px;" onclick="deleteRule('${rule.id}')">Delete</button>
                        </div>
                    </div>
                    <div class="net-rule-meta" style="margin-top:6px;">
                        <span style="font-size:11px;font-weight:600;padding:2px 7px;border-radius:4px;background:${methodColor(rule.method)}22;color:${methodColor(rule.method)};">${rule.method}</span>
                        <span style="font-family:monospace;font-size:12px;color:var(--text-primary);margin-left:6px;">${escapeHtml(rule.pathPattern)}</span>
                        <span style="margin-left:auto;color:${statusColor(rule.mockStatusCode)};font-weight:600;font-size:12px;">→ ${rule.mockStatusCode}</span>
                    </div>
                </div>
            `).join('');
            const countEl = document.getElementById('interceptor-active-count');
            if (countEl) {
                const activeCount = rules.filter(r => r.isEnabled).length;
                countEl.textContent = activeCount + ' of ' + rules.length + ' active';
            }
        }
        
        function openRuleForm(ruleId) {
            const modal = document.getElementById('rule-form-modal');
            const title = document.getElementById('rule-form-title');
            const editingId = document.getElementById('rule-editing-id');
            if (ruleId) {
                const rule = interceptorRules.find(r => r.id === ruleId);
                if (!rule) return;
                title.textContent = 'Edit Rule';
                editingId.value = rule.id;
                document.getElementById('rule-label').value = rule.label || '';
                document.getElementById('rule-path').value = rule.pathPattern || '';
                document.getElementById('rule-method').value = rule.method || 'ANY';
                document.getElementById('rule-status-code').value = rule.mockStatusCode || 200;
                document.getElementById('rule-response-body').value = rule.mockResponseBody || '';
                const hdrs = rule.mockResponseHeaders || {};
                document.getElementById('rule-response-headers').value = Object.entries(hdrs).map(([k, v]) => k + ': ' + v).join('\\n');
            } else {
                title.textContent = 'Add Rule';
                editingId.value = '';
                document.getElementById('rule-label').value = '';
                document.getElementById('rule-path').value = '';
                document.getElementById('rule-method').value = 'ANY';
                document.getElementById('rule-status-code').value = '200';
                document.getElementById('rule-response-body').value = '';
                document.getElementById('rule-response-headers').value = 'Content-Type: application/json';
            }
            modal.style.display = 'flex';
        }
        
        function closeRuleForm() {
            const modal = document.getElementById('rule-form-modal');
            if (modal) modal.style.display = 'none';
        }
        
        async function submitRuleForm() {
            const editingId = document.getElementById('rule-editing-id').value;
            const pathPattern = document.getElementById('rule-path').value.trim();
            if (!pathPattern) { showToast('Path pattern is required', 'error'); return; }
            const payload = {
                pathPattern,
                method: document.getElementById('rule-method').value,
                mockStatusCode: parseInt(document.getElementById('rule-status-code').value) || 200,
                mockResponseBody: document.getElementById('rule-response-body').value,
                mockResponseHeaders: parseHeadersText(document.getElementById('rule-response-headers').value),
                isEnabled: true,
                label: document.getElementById('rule-label').value.trim() || pathPattern
            };
            let result;
            if (editingId) {
                payload.id = editingId;
                result = await apiFetch('/api/interceptor/rules/' + editingId, { method: 'PUT', body: JSON.stringify(payload) });
            } else {
                result = await apiFetch('/api/interceptor/rules', { method: 'POST', body: JSON.stringify(payload) });
            }
            if (result) {
                closeRuleForm();
                fetchInterceptorRules();
                fetchInterceptorStatus();
                showToast(editingId ? 'Rule updated' : 'Rule added');
            }
        }
        
        async function toggleRule(ruleId) {
            const result = await apiFetch('/api/interceptor/rules/' + ruleId + '/toggle', { method: 'POST' });
            if (result) { fetchInterceptorRules(); fetchInterceptorStatus(); }
        }
        
        async function deleteRule(ruleId) {
            if (!confirm('Delete this rule?')) return;
            const result = await apiFetch('/api/interceptor/rules/' + ruleId, { method: 'DELETE' });
            if (result) { fetchInterceptorRules(); fetchInterceptorStatus(); showToast('Rule deleted'); }
        }
        
        function parseHeadersText(text) {
            const headers = {};
            text.split('\\n').forEach(line => {
                const idx = line.indexOf(':');
                if (idx > 0) {
                    const key = line.substring(0, idx).trim();
                    const val = line.substring(idx + 1).trim();
                    if (key) headers[key] = val;
                }
            });
            return headers;
        }
        
        // ========================================
        // App Initialization
        // ========================================
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DebugDash Dashboard loaded');
            
            // Set up navigation
            document.querySelectorAll('[data-page]').forEach(navItem => {
                navItem.addEventListener('click', () => {
                    const pageId = navItem.getAttribute('data-page');
                    navigateTo(pageId);
                });
            });
            
            // Initialize home page
            initHome();
            startUptimeCounter();
            
            // Initial status fetch
            fetchStatus();
        });
        
        // Clean up on page unload
        window.addEventListener('beforeunload', () => {
            stopAllPolling();
        });
        """
    }
}
