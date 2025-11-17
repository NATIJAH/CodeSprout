<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TeacherMaterial extends Model
{
    use HasFactory;

    protected $table = 'teacher_material';

    protected $fillable = [
        'title', 
        'description', 
        'file_path', 
        'file_name', 
        'file_type',
        'file_size',
        'teacher_id', 
        'class_id'
    ];

    public function teacher()
    {
        return $this->belongsTo(Teacher::class);
    }

    public function class()
    {
        return $this->belongsTo(Classes::class);
    }
}