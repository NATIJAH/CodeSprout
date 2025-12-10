import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/materials_provider.dart';
import '../models/teaching_material.dart';
import 'upload_material_screen.dart';

// Defined theme colors
const Color _primaryAccent = Color(0xff6b8e7c); // Soft Green/Gray
const Color _backgroundColor = Color(0xfff9f9f9); // Light background
const Color _cardHighlight = Color(0xffe8f0e8); // Very light green for subtle contrast

class TeacherTeachingMaterial extends StatefulWidget {
  const TeacherTeachingMaterial({super.key});

  @override
  State<TeacherTeachingMaterial> createState() => _TeacherTeachingMaterialState();
}

class _TeacherTeachingMaterialState extends State<TeacherTeachingMaterial> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MaterialsProvider>(context, listen: false).loadTeacherMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Changed background color
      appBar: AppBar(
        title: const Text(
          'Bahan Mengajar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _primaryAccent, // Changed AppBar color
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadMaterialScreen(),
            ),
          );
        },
        icon: const Icon(Icons.upload),
        label: const Text('Muat Naik'),
        backgroundColor: _primaryAccent, // Changed FAB color
      ),
      body: Consumer<MaterialsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.materials.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: _primaryAccent, // Changed loading indicator color
              ),
            );
          }

          if (provider.materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 100,
                    color: _primaryAccent.withOpacity(0.5), // Changed icon color
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tiada bahan mengajar lagi', 
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Mulakan dengan memuat naik bahan mengajar pertama anda\nmenggunakan butang muat naik di bawah',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xff64748b),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.materials.length,
            itemBuilder: (context, index) {
              final material = provider.materials[index];
              return _buildMaterialCard(material, context, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(TeachingMaterial material, BuildContext context, MaterialsProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GestureDetector(
        onTap: () => _showMaterialOptions(context, material, provider),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // File Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: material.fileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: material.fileColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      material.fileIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        material.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff64748b),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _cardHighlight, // Changed class badge background
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        material.className,
        style: TextStyle(
          fontSize: 12,
          color: _primaryAccent, // Changed class badge text color
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    const Spacer(),
    
    Text(
      material.readableFileSize,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xff64748b),
      ),
    ),
  ],
),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMaterialOptions(BuildContext context, TeachingMaterial material, MaterialsProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.download, color: _primaryAccent), // Changed icon color
                title: const Text('Muat Turun'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadMaterial(context, material, provider);
                },
              ),
              
              ListTile(
                leading: Icon(Icons.edit, color: _primaryAccent), // Changed icon color
                title: const Text('Sunting'),
                onTap: () {
                  Navigator.pop(context);
                  _editMaterial(context, material);
                },
              ),
              
              const Divider(),
              
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Padam',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMaterial(context, material, provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadMaterial(BuildContext context, TeachingMaterial material, MaterialsProvider provider) async {
    try {
      await provider.downloadMaterial(material);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${material.title} berjaya dimuat turun'),
            backgroundColor: _primaryAccent, // Changed snackbar color
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat turun: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editMaterial(BuildContext context, TeachingMaterial material) {
    final provider = Provider.of<MaterialsProvider>(context, listen: false);
    provider.setSelectedMaterial(material);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadMaterialScreen(isEditing: true),
      ),
    );
  }

  void _deleteMaterial(BuildContext context, TeachingMaterial material, MaterialsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Padam Bahan'),
        content: Text('Anda pasti mahu padam "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteMaterial(material.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bahan berjaya dipadam'),
                    backgroundColor: _primaryAccent, // Changed snackbar color
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Padam'),
          ),
        ],
      ),
    );
  }
}
