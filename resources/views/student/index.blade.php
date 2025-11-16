@extends('layouts.app')

@section('content')
<h2>Your Tasks</h2>
<table class="table table-bordered">
    <thead>
        <tr>
            <th>Task</th>
            <th>Status</th>
            <th>Due Date</th>
            <th>Action</th>
        </tr>
    </thead>
    <tbody>
        @foreach($tasks as $assignment)
        <tr>
            <td>{{ $assignment->task->title }}</td>
            <td>{{ $assignment->status }}</td>
            <td>{{ $assignment->task->due_date }}</td>
            <td>
                <a href="{{ url('/student/tasks/'.$assignment->id) }}" class="btn btn-primary btn-sm">View</a>
            </td>
        </tr>
        @endforeach
    </tbody>
</table>
@endsection
