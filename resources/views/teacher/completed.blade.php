@extends('layouts.app')

@section('page-title', 'Completed Tasks')
@section('page-subtitle', 'Tasks submitted by students')

@section('content')
@foreach($completed as $assignment)
<div class="bg-white p-4 mb-4 rounded shadow">
    <h3 class="font-medium">{{ $assignment->task->title }} - {{ $assignment->student->name }}</h3>
    <p>Submission: {{ $assignment->submission }}</p>
    <p>Status: {{ $assignment->status }}</p>
</div>
@endforeach
@endsection
