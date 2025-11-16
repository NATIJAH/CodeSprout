@extends('layouts.app')

@section('page-title', 'Create Task')
@section('page-subtitle', 'Assign task to students')

@section('content')
<form action="{{ route('teacher.store') }}" method="POST">
    @csrf
    <div>
        <label>Title</label>
        <input type="text" name="title" required>
    </div>

    <div>
        <label>Description</label>
        <textarea name="description" required></textarea>
    </div>

    <div>
        <label>Due Date</label>
        <input type="date" name="due_date" required>
    </div>

    <div>
        <label>Assign to Students</label>
        <select name="students[]" multiple required>
            @foreach($students as $student)
                <option value="{{ $student->id }}">{{ $student->name }}</option>
            @endforeach
        </select>
    </div>

    <button type="submit">Create Task</button>
</form>
@endsection
