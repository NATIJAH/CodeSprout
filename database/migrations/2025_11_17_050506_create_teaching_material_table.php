<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('teaching_material', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('file_path');
            $table->string('original_file_name');
            $table->string('file_type');
            $table->unsignedBigInteger('teacher_id');
            $table->string('subject')->nullable();
            $table->timestamps();
            
            // Foreign key constraint
            $table->foreign('teacher_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('teaching_material');
    }
};