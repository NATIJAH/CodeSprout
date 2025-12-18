import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

class ActivityForm extends StatefulWidget {
  final Activity? activity;
  final DateTime? selectedDate;
  final VoidCallback onActivitySaved;

  const ActivityForm({
    super.key,
    this.activity,
    this.selectedDate,
    required this.onActivitySaved,
  });

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final ActivityService _activityService = ActivityService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      // Edit mode
      _titleController.text = widget.activity!.title;
      _descriptionController.text = widget.activity!.description;
      _selectedDate = widget.activity!.date;
      
      // Parse time from string
      try {
        final timeParts = widget.activity!.time.split(':');
        if (timeParts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        _selectedTime = TimeOfDay.now();
      }
      
      _categoryController.text = widget.activity!.category ?? '';
    } else if (widget.selectedDate != null) {
      // Create mode with preselected date
      _selectedDate = widget.selectedDate!;
      _selectedTime = TimeOfDay.now();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff4f7f67),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff4f7f67),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime() {
    return '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // For now, use a default user ID or get from auth
      final userId = "user_123"; // Replace with actual user ID from auth
      
      final activity = Activity(
        id: widget.activity?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        time: _formatTime(),
        userId: userId,
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
      );

      if (widget.activity == null) {
        await _activityService.createActivityFromModel(activity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity created successfully'),
            backgroundColor: const Color(0xff4f7f67),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        await _activityService.updateActivityFromModel(activity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity updated successfully'),
            backgroundColor: const Color(0xff4f7f67),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      widget.onActivitySaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save activity: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.activity == null ? 'Create Activity' : 'Edit Activity',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff4f7f67),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Activity Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    labelStyle: const TextStyle(color: Color(0xff666666)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe0e0e0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe0e0e0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xff4f7f67), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xfff8f8f8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  style: const TextStyle(fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    labelStyle: const TextStyle(color: Color(0xff666666)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe0e0e0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe0e0e0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xff4f7f67), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xfff8f8f8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Date and Time Row
                Row(
                  children: [
                    // Date Picker
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffe0e0e0)),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xfff8f8f8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xff333333),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xff4f7f67)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Time Picker
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffe0e0e0)),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xfff8f8f8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xff333333),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.access_time, color: Color(0xff4f7f67)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Category Field
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category (optional)',
                    labelStyle: const TextStyle(color: Color(0xff666666)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe0e0e0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe0e0e0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xff4f7f67), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xfff8f8f8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4f7f67),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.activity == null ? 'Create Activity' : 'Update Activity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}