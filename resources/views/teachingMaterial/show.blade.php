@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">Teaching Material Details</div>

                <div class="card-body">
                    <h3>{{ $teachingMaterial->title }}</h3>
                    <p><strong>Subject:</strong> {{ $teachingMaterial->subject }}</p>
                    <p><strong>Description:</strong> {{ $teachingMaterial->description ?? 'No description' }}</p>
                    <p><strong>File:</strong> {{ $teachingMaterial->original_file_name }}</p>
                    <p><strong>File Type:</strong> {{ strtoupper($teachingMaterial->file_type) }}</p>
                    <p><strong>Uploaded:</strong> {{ $teachingMaterial->created_at->format('M d, Y') }}</p>
                    
                    <div class="mt-4">
                        <a href="{{ route('teachingMaterial.download', $teachingMaterial) }}" class="btn btn-success">Download File</a>
                        <a href="{{ route('teachingMaterial.index') }}" class="btn btn-secondary">Back to List</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection