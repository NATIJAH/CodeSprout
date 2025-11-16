@extends('layouts.app')

@section('content')
<div class="container mt-4">
    <h2>{{ $assignment->task->title }}</h2>
    <p><strong>Description:</strong> {{ $assignment->task->description }}</p>
    <p><strong>Due Date:</strong> {{ $assignment->task->due_date ? $assignment->task->due_date->format('d M Y') : 'No due date' }}</p>
    <p><strong>Status:</strong> {{ $assignment->status }}</p>

    <hr>

    <h5>Submit or Update Your Work</h5>
    <form action="{{ url('/student/tasks/'.$assignment->id.'/submit') }}" method="POST">
        @csrf
        <div class="mb-3">
            <label for="submission" class="form-label">Your Submission:</label>
            <textarea name="submission" id="submission" class="form-control" rows="5">{{ $assignment->submission ?? '' }}</textarea>
        </div>
        <button type="submit" class="btn btn-success">Submit</button>
    </form>

    @if($assignment->status === 'Completed')
        <p class="text-success mt-2">You have already submitted this task.</p>
    @endif

    <a href="{{ url('/student/tasks') }}" class="btn btn-secondary mt-3">Back to My Tasks</a>
</div>
@endsection
