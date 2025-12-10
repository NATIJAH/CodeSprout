@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row">
        <div class="col-md-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1>My Teaching Material</h1>
                <a href="{{ route('teachingMaterial.create') }}" class="btn btn-primary">                    Upload New Material
                </a>
            </div>

            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif

            @if($materialList->count() > 0)
                <div class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Title</th>
                                <th>Subject</th>
                                <th>File Type</th>
                                <th>Upload Date</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($materialList as $material)
                            <tr>
                                <td>{{ $material->title }}</td>
                                <td>{{ $material->subject }}</td>
                                <td>{{ strtoupper($material->file_type) }}</td>
                                <td>{{ $material->created_at->format('M d, Y') }}</td>
                                <td>
                                    <a href="{{ route('teachingMaterial.download', $material) }}" class="btn btn-sm btn-success">Download</a>
                                    <a href="{{ route('teachingMaterial.show', $material) }}" class="btn btn-sm btn-info">View</a>
                                    <form action="{{ route('teachingMaterial.destroy', $material) }}" method="POST" class="d-inline">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Delete this material?')">Delete</button>
                                    </form>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <div class="alert alert-info">
                    You haven't uploaded any teaching material yet.
                </div>
            @endif
        </div>
    </div>
</div>
@endsection