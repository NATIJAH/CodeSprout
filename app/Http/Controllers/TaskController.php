<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Task;
use App\Models\TaskAssignment;
use App\Models\User;

class TaskController extends Controller
{
    // Show all tasks (teacher dashboard)
    public function index()
    {
        $tasks = Task::with('assignments.student')->get();
        return view('teacher.index', compact('tasks'));
    }

    // Show completed tasks (submitted by students)
    public function completed()
    {
        $completed = TaskAssignment::with(['task', 'student'])
            ->where('status', 'Completed')
            ->get();
        return view('teacher.completed', compact('completed'));
    }

    // Show create task form
    public function create()
    {
        $students = User::where('role', 'student')->get();
        return view('teacher.create', compact('students'));
    }

    // Store new task and assign to students
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
            'students' => 'required|array',
        ]);

        $task = Task::create([
            'title' => $request->title,
            'description' => $request->description,
            'due_date' => $request->due_date,
        ]);

        foreach ($request->students as $studentId) {
            TaskAssignment::create([
                'task_id' => $task->id,
                'student_id' => $studentId,
                'status' => 'Pending',
            ]);
        }

        return redirect()->route('teacher.tasks')->with('success', 'Task assigned successfully!');
    }
}
