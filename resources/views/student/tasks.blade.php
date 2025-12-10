@extends('layouts.app')

@section('page-title', 'Your Tasks')
@section('page-subtitle', 'Tasks assigned to you')

@section('content')
@foreach($tasks as $assignment)
<div class="bg-white p-4 mb-4 rounded shadow">
    <h3 class="font-medium">{{ $assignment->task->title }}</h3>
    <p>{{ $assignment->task->description }}</p>
    <p>Due: {{ $assignment->task->due_date }}</p>

    @if($assignment->status != 'Completed')
    <form action="{{ route('student.submit', $assignment->id) }}" method="POST">
    @csrf
    <input type="text" name="submission" required>
    <button type="submit">Submit</button>
</form>

    @else
    <span class="text-green-600 font-semibold">Submitted</span>
    @endif
</div>
@endforeach
@endsection
