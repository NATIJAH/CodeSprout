<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Task;
use App\Models\TaskAssignment;

class TeacherTaskController extends Controller
{
    public function index()
    {
        $tasks = Task::all();
        return view('teacher.tasks.index', compact('tasks'));
    }

    public function create()
    {
        return view('teacher.tasks.create');
    }

    public function store(Request $request)
    {
        $task = Task::create($request->only('title','description','due_date','teacher_id'));
        return redirect('/teacher/tasks')->with('success', 'Task assigned!');
    }

    public function completed()
    {
        $assignments = TaskAssignment::where('status', 'Completed')->with('task')->get();
        return view('teacher.tasks.completed', compact('assignments'));
    }

    public function updateStatus(Request $request, $id)
    {
        $assignment = TaskAssignment::findOrFail($id);
        $assignment->status = $request->input('status');
        $assignment->save();

        return redirect('/teacher/completed')->with('success', 'Status updated!');
    }
}
