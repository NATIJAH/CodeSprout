import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/materials_provider.dart';
import '../models/teaching_material.dart';

class UploadMaterialScreen extends StatefulWidget {
  final bool isEditing;
  
  const UploadMaterialScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  List<String> _tags = [];
  String _selectedClassName = '5 Amanah';

  // Malaysian Class Names
  final List<String> _classNames = [
    '5 Amanah',
    '5 Terbilang',
    '5 Dedikasi',
    '5 Ikhlas',
    '5 Usaha',
    '6 Amanah',
    '6 Terbilang',
    '6 Dedikasi',
    '6 Ikhlas',
    '6 Usaha',
    'Form 1 Science',
    'Form 1 Arts',
    'Form 2 Science',
    'Form 2 Arts',
    'Form 3 Science',
    'Form 3 Arts',
    'Form 4 Science',
    'Form 4 Arts',
    'Form 5 Science',
    'Form 5 Arts',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadMaterialData();
    }
  }

  void _loadMaterialData() {
    final provider = Provider.of<MaterialsProvider>(context, listen: false);
    final material = provider.selectedMaterial;
    
    if (material != null) {
      _titleController.text = material.title;
      _descriptionController.text = material.description;
      _selectedClassName = material.className;
      _tags = material.tags;
      _tagsController.text = _tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final provider = Provider.of<MaterialsProvider>(context, listen: false);
    await provider.pickFile();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<MaterialsProvider>(context, listen: false);
    
    if (widget.isEditing) {
      // Update material
      final success = await provider.updateMaterial(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        className: _selectedClassName,
        tags: _tags,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Material updated successfully'),
            backgroundColor: const Color(0xff5b7cff),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      // Upload new material
      final selectedFile = provider.selectedFile;
      if (selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a file first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await provider.uploadMaterial(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        className: _selectedClassName,
        tags: _tags,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Material uploaded successfully'),
            backgroundColor: const Color(0xff5b7cff),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Color get _primaryColor => const Color(0xff5b7cff);
  Color get _backgroundColor => const Color(0xfff2f6ff);
  Color get _cardColor => const Color(0xffe0e7ff);
  Color get _textColor => const Color(0xff334155);
  Color get _subTextColor => const Color(0xff64748b);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MaterialsProvider>(context);
    final selectedFile = provider.selectedFile;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Material' : 'Upload Material'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMaterial,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Selection (only for new uploads)
              if (!widget.isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📁 Select File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      if (selectedFile != null)
                        _buildFileInfo(selectedFile)
                      else
                        _buildFilePicker(),
                      
                      if (selectedFile != null)
                        const SizedBox(height: 10),
                      
                      if (selectedFile != null)
                        TextButton(
                          onPressed: provider.clearSelectedFile,
                          child: Text(
                            'Change File',
                            style: TextStyle(color: _primaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Title and Description Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Material Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        labelStyle: TextStyle(color: _subTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _cardColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor),
                        ),
                        filled: true,
                        fillColor: _cardColor.withOpacity(0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        labelStyle: TextStyle(color: _subTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _cardColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor),
                        ),
                        filled: true,
                        fillColor: _cardColor.withOpacity(0.3),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Class Name Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏫 Class Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedClassName,
                      decoration: InputDecoration(
                        labelText: 'Class Name *',
                        labelStyle: TextStyle(color: _subTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _cardColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor),
                        ),
                        filled: true,
                        fillColor: _cardColor.withOpacity(0.3),
                      ),
                      items: _classNames.map((className) {
                        return DropdownMenuItem(
                          value: className,
                          child: Text(className),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassName = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a class';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tags Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏷️ Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add tags to help students find this material easily',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagsController,
                            decoration: InputDecoration(
                              hintText: 'e.g., homework, exam, notes, chapter-1',
                              hintStyle: TextStyle(color: _subTextColor.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _cardColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor),
                              ),
                              filled: true,
                              fillColor: _cardColor.withOpacity(0.3),
                            ),
                            onFieldSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTag,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    
                    if (_tags.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              return Chip(
                                label: Text(tag),
                                backgroundColor: _cardColor,
                                deleteIcon: Icon(Icons.close, size: 16, color: _primaryColor),
                                onDeleted: () => _removeTag(tag),
                                labelStyle: TextStyle(color: _primaryColor),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Submit Button
              ElevatedButton(
                onPressed: provider.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Update Material' : 'Upload Material',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              if (provider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfo(PlatformFile file) {
    final sizeInMB = (file.size / (1024 * 1024)).toStringAsFixed(2);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            color: _primaryColor,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${file.extension?.toUpperCase() ?? 'FILE'} • ${sizeInMB} MB',
                  style: TextStyle(
                    color: _subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.05),
          border: Border.all(
            color: _primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 48,
              color: _primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to select file',
              style: TextStyle(
                fontSize: 16,
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supports: PDF, Images, Videos, Documents',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMaterial() {
    final provider = Provider.of<MaterialsProvider>(context, listen: false);
    final material = provider.selectedMaterial;
    
    if (material == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteMaterial(material.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Material deleted successfully'),
                    backgroundColor: _primaryColor,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}