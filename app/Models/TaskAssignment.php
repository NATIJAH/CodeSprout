<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TaskAssignment extends Model
{
    use HasFactory;

    protected $fillable = ['task_id', 'student_id', 'status', 'submission'];

    public function task() {
    return $this->belongsTo(Task::class);
}

public function student() {
    return $this->belongsTo(User::class, 'student_id');
}

}
