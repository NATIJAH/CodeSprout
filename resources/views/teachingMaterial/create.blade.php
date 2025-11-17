@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">Upload Teaching Material</div>

                <div class="card-body">
                    <form action="{{ route('teachingMaterial.store') }}" method="POST" enctype="multipart/form-data">
                        @csrf
                        
                        <div class="form-group mb-3">
                            <label for="title">Title</label>
                            <input type="text" name="title" id="title" class="form-control" required>
                        </div>

                        <div class="form-group mb-3">
                            <label for="subject">Subject</label>
                            <input type="text" name="subject" id="subject" class="form-control" required>
                        </div>

                        <div class="form-group mb-3">
                            <label for="description">Description</label>
                            <textarea name="description" id="description" class="form-control" rows="3"></textarea>
                        </div>

                        <div class="form-group mb-3">
                            <label for="file">File</label>
                            <input type="file" name="file" id="file" class="form-control" required>
                            <small class="form-text text-muted">
                                Allowed: PDF, DOC, DOCX, PPT, PPTX, TXT, ZIP (Max: 10MB)
                            </small>
                        </div>

                        <button type="submit" class="btn btn-primary">Upload Material</button>
<a href="{{ route('teachingMaterial.create') }}" class="btn btn-primary">                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection