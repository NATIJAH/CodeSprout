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
    Route::get('/class/{classId}/teacher-material', [App\Http\Controllers\TeacherMaterialController::class, 'index'])->name('teacher-material.index');
    Route::get('/class/{classId}/teacher-material/create', [App\Http\Controllers\TeacherMaterialController::class, 'create'])->name('teacher-material.create');
    Route::post('/teacher-material', [App\Http\Controllers\TeacherMaterialController::class, 'store'])->name('teacher-material.store');
    Route::get('/teacher-material/{id}/download', [App\Http\Controllers\TeacherMaterialController::class, 'download'])->name('teacher-material.download');
    Route::delete('/teacher-material/{id}', [App\Http\Controllers\TeacherMaterialController::class, 'destroy'])->name('teacher-material.destroy');
});

// Student
Route::prefix('student')->group(function () {
    Route::get('/tasks', [StudentTaskController::class, 'index'])->name('student.tasks');
    Route::post('/tasks/submit/{id}', [StudentTaskController::class, 'submit'])->name('student.submit');
});


