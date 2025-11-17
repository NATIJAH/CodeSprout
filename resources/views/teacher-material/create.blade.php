<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Teacher Material</title>
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
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }

        .header h1 {
            color: #2c3e50;
            margin: 0;
        }

        .upload-form {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .form-group {
            margin-bottom: 25px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #2c3e50;
        }

        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 1em;
            font-family: inherit;
        }

        .form-group textarea {
            resize: vertical;
            min-height: 100px;
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

        .btn-secondary {
            background: #95a5a6;
            color: white;
            margin-right: 10px;
        }

        .btn-secondary:hover {
            background: #7f8c8d;
        }

        .form-actions {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📤 Upload Teacher Material</h1>
        </div>

        <div class="upload-form">
            <form action="{{ route('teacher-material.store') }}" method="POST" enctype="multipart/form-data">
                @csrf
                
                <input type="hidden" name="class_id" value="{{ $classId }}">
                <input type="hidden" name="teacher_id" value="1"> <!-- Default teacher ID -->

                <div class="form-group">
                    <label for="title">Material Title *</label>
                    <input type="text" id="title" name="title" required>
                </div>

                <div class="form-group">
                    <label for="description">Description</label>
                    <textarea id="description" name="description" placeholder="Optional description of the material..."></textarea>
                </div>

                <div class="form-group">
                    <label for="file">File *</label>
                    <input type="file" id="file" name="file" required>
                    <small style="color: #7f8c8d; display: block; margin-top: 5px;">
                        Maximum file size: 10MB
                    </small>
                </div>

                <div class="form-actions">
                    <a href="{{ route('teacher-material.index', ['classId' => $classId]) }}" class="btn btn-secondary">
                        ← Back to Materials
                    </a>
                    <button type="submit" class="btn btn-primary">
                        📤 Upload Material
                    </button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>