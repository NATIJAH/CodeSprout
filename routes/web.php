<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\StudentTaskController;

Route::get('/', function () {
    return view('welcome'); // Optional home page
});

// Teacher
Route::prefix('teacher')->group(function () {
    Route::get('/tasks', [TaskController::class, 'index'])->name('teacher.tasks');
    Route::get('/completed', [TaskController::class, 'completed'])->name('teacher.completed');
    Route::get('/create', [TaskController::class, 'create'])->name('teacher.create');
    Route::post('/store', [TaskController::class, 'store'])->name('teacher.store');
    // Teacher Material Routes
    Route::resource('teachingMaterial', TeachingMaterialController::class);
    Route::get('/teachingMaterial/{teachingMaterial}/download', [TeachingMaterialController::class, 'download'])->name('teachingMaterial.download');
});

// Student
Route::prefix('student')->group(function () {
    Route::get('/tasks', [StudentTaskController::class, 'index'])->name('student.tasks');
    Route::post('/tasks/submit/{id}', [StudentTaskController::class, 'submit'])->name('student.submit');
    Route::get('/material', [TeachingMaterialController::class, 'studentView'])->name('teachingMaterial.studentView');
});


