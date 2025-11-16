@extends('layouts.app')

@section('content')
<div class="container mt-4">
    <h2>Edit Task</h2>

    <div class="card shadow-sm mt-3">
        <div class="card-body">

            <form action="{{ route('teacher.tasks.update', $task->id) }}" method="POST">
                @csrf
                @method('PUT')

                <div class="mb-3">
                    <label class="form-label">Task Title</label>
                    <input type="text" name="title" 
                           class="form-control" 
                           value="{{ $task->title }}" required>
                </div>

                <div class="mb-3">
                    <label class="form-label">Description</label>
                    <textarea name="description" 
                              class="form-control" 
                              rows="4" required>{{ $task->description }}</textarea>
                </div>

                <div class="mb-3">
                    <label class="form-label">Due Date</label>
                    <input type="date" name="due_date" 
                           class="form-control" 
                           value="{{ $task->due_date }}" required>
                </div>

                <button type="submit" class="btn btn-primary">Update Task</button>
                <a href="{{ route('teacher.tasks.index') }}" class="btn btn-secondary">Cancel</a>

            </form>

        </div>
    </div>
</div>
@endsection
