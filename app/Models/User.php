public function assignedTasks()
{
    return $this->hasMany(TaskAssignment::class, 'student_id');
}

public function createdTasks()
{
    return $this->hasMany(Task::class, 'teacher_id');
}
