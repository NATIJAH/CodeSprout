<?php

namespace App\Http\Controllers;

use App\Models\TeacherMaterial;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class TeacherMaterialController extends Controller
{
    /**
     * Display all teacher materials for a class
     */
    public function index($classId)
    {
        $materials = TeacherMaterial::where('class_id', $classId)
            ->with(['teacher', 'class'])
            ->orderBy('created_at', 'desc')
            ->get();

        return view('teacher-material.index', [
            'materials' => $materials,
            'classId' => $classId
        ]);
    }

    /**
     * Show the form for creating new material
     */
    public function create($classId)
    {
        return view('teacher-material.create', [
            'classId' => $classId
        ]);
    }

    /**
     * Store new teacher material
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'class_id' => 'required|exists:classes,id',
            'teacher_id' => 'required|exists:teachers,id',
            'file' => 'required|file|max:10240' // 10MB max
        ]);

        // Handle file upload
        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $fileName = time() . '_' . $file->getClientOriginalName();
            $filePath = $file->storeAs('teacher_materials', $fileName, 'public');

            // Create teacher material record
            TeacherMaterial::create([
                'title' => $validated['title'],
                'description' => $validated['description'],
                'file_path' => $filePath,
                'file_name' => $file->getClientOriginalName(),
                'file_type' => $file->getClientMimeType(),
                'file_size' => $file->getSize(),
                'teacher_id' => $validated['teacher_id'],
                'class_id' => $validated['class_id']
            ]);

            return redirect()->route('teacher-material.index', ['classId' => $validated['class_id']])
                ->with('success', 'Material uploaded successfully!');
        }

        return back()->with('error', 'File upload failed');
    }

    /**
     * Download teacher material
     */
    public function download($id)
    {
        $material = TeacherMaterial::findOrFail($id);
        $filePath = storage_path('app/public/' . $material->file_path);
        
        if (!file_exists($filePath)) {
            return back()->with('error', 'File not found');
        }

        return response()->download($filePath, $material->file_name);
    }

    /**
     * Delete teacher material
     */
    public function destroy($id)
    {
        $material = TeacherMaterial::findOrFail($id);
        $classId = $material->class_id;

        // Delete file from storage
        Storage::disk('public')->delete($material->file_path);

        // Delete record from database
        $material->delete();

        return redirect()->route('teacher-material.index', ['classId' => $classId])
            ->with('success', 'Material deleted successfully!');
    }
}