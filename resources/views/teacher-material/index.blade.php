<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Materials</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f8f9fa;
            color: #333;
            line-height: 1.6;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            color: #2c3e50;
            margin: 0;
        }

        .btn {
            display: inline-block;
            padding: 12px 24px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            text-decoration: none;
            font-size: 1em;
            transition: all 0.3s ease;
        }

        .btn-primary {
            background: #3498db;
            color: white;
        }

        .btn-primary:hover {
            background: #2980b9;
        }

        .btn-success {
            background: #27ae60;
            color: white;
        }

        .btn-success:hover {
            background: #219a52;
        }

        .btn-danger {
            background: #e74c3c;
            color: white;
        }

        .btn-danger:hover {
            background: #c0392b;
        }

        .materials-grid {
            display: grid;
            gap: 20px;
        }

        .material-card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            border-left: 4px solid #3498db;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }

        .material-info {
            flex: 1;
        }

        .material-info h3 {
            color: #2c3e50;
            margin-bottom: 10px;
        }

        .material-info p {
            color: #7f8c8d;
            margin-bottom: 15px;
        }

        .file-meta {
            font-size: 0.9em;
            color: #95a5a6;
        }

        .file-meta span {
            margin-right: 15px;
        }

        .material-actions {
            display: flex;
            gap: 10px;
        }

        .file-icon {
            font-size: 2em;
            margin-right: 15px;
        }

        .material-header {
            display: flex;
            align-items: flex-start;
            margin-bottom: 15px;
        }

        .alert {
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 20px;
        }

        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        .no-materials {
            text-align: center;
            padding: 40px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📚 Teacher Materials</h1>
            <a href="{{ route('teacher-material.create', ['classId' => $classId]) }}" class="btn btn-primary">
                + Upload Material
            </a>
        </div>

        @if(session('success'))
            <div class="alert alert-success">
                {{ session('success') }}
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-error">
                {{ session('error') }}
            </div>
        @endif

        <div class="materials-grid">
            @if($materials->count() > 0)
                @foreach($materials as $material)
                    <div class="material-card">
                        <div class="material-info">
                            <div class="material-header">
                                <span class="file-icon">
                                    @if(str_contains($material->file_type, 'pdf')) 📕
                                    @elseif(str_contains($material->file_type, 'word') || str_contains($material->file_type, 'document')) 📄
                                    @elseif(str_contains($material->file_type, 'powerpoint') || str_contains($material->file_type, 'presentation')) 📊
                                    @elseif(str_contains($material->file_type, 'image')) 🖼️
                                    @elseif(str_contains($material->file_type, 'video')) 🎬
                                    @else 📎
                                    @endif
                                </span>
                                <div>
                                    <h3>{{ $material->title }}</h3>
                                    <p>{{ $material->description }}</p>
                                    <div class="file-meta">
                                        <span><strong>File:</strong> {{ $material->file_name }}</span>
                                        <span><strong>Size:</strong> {{ number_format($material->file_size / 1024, 2) }} KB</span>
                                        <span><strong>Uploaded by:</strong> {{ $material->teacher->name }}</span>
                                        <span><strong>Date:</strong> {{ $material->created_at->format('M d, Y') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="material-actions">
                            <a href="{{ route('teacher-material.download', $material->id) }}" class="btn btn-success">
                                📥 Download
                            </a>
                            <form action="{{ route('teacher-material.destroy', $material->id) }}" method="POST" style="display: inline;">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-danger" onclick="return confirm('Are you sure?')">
                                    🗑️ Delete
                                </button>
                            </form>
                        </div>
                    </div>
                @endforeach
            @else
                <div class="no-materials">
                    <h3>No materials available yet</h3>
                    <p>Upload your first teaching material to get started!</p>
                </div>
            @endif
        </div>
    </div>
</body>
</html>