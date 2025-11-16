@extends('layouts.app')
@section('page-title', 'All Tasks')
@section('page-subtitle', 'Tasks assigned by you')

@section('content')
@foreach($tasks as $task)
<div class="bg-white p-4 mb-4 rounded shadow">
    <h3 class="font-medium">{{ $task->title }}</h3>
    <p>{{ $task->description }}</p>
    <p>Due: {{ $task->due_date }}</p>
    <p>Assigned Students:
        @foreach($task->assignments as $assign)
            {{ $assign->student->name }} ({{ $assign->status }}),
        @endforeach
    </p>
    <a href="{{ route('teacher.edit', $task->id) }}" class="text-blue-500">Edit</a>
</div>
@endforeach
@endsection
