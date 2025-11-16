<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Task;
use App\Models\TaskAssignment;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // --- Create teachers ---
        $teacher1 = User::create([
            'name' => 'Teacher One',
            'email' => 'teacher1@example.com',
            'password' => Hash::make('password'),
        ]);

        $teacher2 = User::create([
            'name' => 'Teacher Two',
            'email' => 'teacher2@example.com',
            'password' => Hash::make('password'),
        ]);

        // --- Create students ---
        $student1 = User::create([
            'name' => 'Student One',
            'email' => 'student1@example.com',
            'password' => Hash::make('password'),
        ]);

        $student2 = User::create([
            'name' => 'Student Two',
            'email' => 'student2@example.com',
            'password' => Hash::make('password'),
        ]);

        $student3 = User::create([
            'name' => 'Student Three',
            'email' => 'student3@example.com',
            'password' => Hash::make('password'),
        ]);

        // --- Create tasks ---
        $task1 = Task::create([
            'title' => 'Math Homework',
            'description' => 'Complete exercises 1-10',
            'due_date' => now()->addDays(3),
            'teacher_id' => $teacher1->id,
        ]);

        $task2 = Task::create([
            'title' => 'Science Project',
            'description' => 'Prepare a volcano model',
            'due_date' => now()->addDays(7),
            'teacher_id' => $teacher2->id,
        ]);

        // --- Assign tasks to students ---
        TaskAssignment::create([
            'task_id' => $task1->id,
            'student_id' => $student1->id,
            'status' => 'pending',
        ]);

        TaskAssignment::create([
            'task_id' => $task1->id,
            'student_id' => $student2->id,
            'status' => 'pending',
        ]);

        TaskAssignment::create([
            'task_id' => $task2->id,
            'student_id' => $student3->id,
            'status' => 'pending',
        ]);
    }
}
