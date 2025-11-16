<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TaskAssignment;

class StudentTaskController extends Controller
{
    // Show tasks assigned to student
    public function index()
    {
        $studentId = auth()->id(); // Use logged-in student
        $tasks = TaskAssignment::with('task')
                    ->where('student_id', $studentId)
                    ->get();

        return view('student.tasks', compact('tasks'));
    }

    // Submit a task
    public function submit(Request $request, $id)
    {
        $request->validate([
            'submission' => 'required|string',
        ]);

        $assignment = TaskAssignment::findOrFail($id);

        // Ensure the logged-in student can submit only their own task
        if ($assignment->student_id != auth()->id()) {
            abort(403, 'Unauthorized');
        }

        $assignment->submission = $request->input('submission');
        $assignment->status = 'Completed';
        $assignment->save();

        return redirect()->back()->with('success', 'Task submitted successfully!');
    }
}
