<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TeachingMaterial extends Model
{
    use HasFactory;

    // Specify the table name since we're using singular
    protected $table = 'teaching_material';

    protected $fillable = [
        'title',
        'description',
        'file_path',
        'original_file_name',
        'file_type',
        'teacher_id',
        'subject'
    ];

    // Relationship with teacher
    public function teacher()
    {
        return $this->belongsTo(User::class, 'teacher_id');
    }
}