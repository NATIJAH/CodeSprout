import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/materials_provider.dart';
import '../models/teaching_material.dart';

// Defined theme colors
const Color _primaryAccent = Color(0xff6b8e7c); // Soft Green/Gray Accent
const Color _backgroundColor = Color(0xfff9f9f9); // Light background
const Color _cardHighlight = Color(0xffe8f0e8); // Light muted green for badges/fills
const Color _textColor = Color(0xff334155); // Dark text for contrast
const Color _subTextColor = Color(0xff64748b); // Subdued text color


class StudentTeachingMaterial extends StatefulWidget {
  const StudentTeachingMaterial({super.key});

  @override
  State<StudentTeachingMaterial> createState() => _StudentTeachingMaterialState();
}

class _StudentTeachingMaterialState extends State<StudentTeachingMaterial> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MaterialsProvider>(context, listen: false).loadPublishedMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bahan Pembelajaran',
          style: TextStyle(
            // FIX 1: Change title color to white
            color: Colors.white, 
            // FIX 2: Use heavier font weight (w700)
            fontWeight: FontWeight.w700, 
          ),
        ),
        // FIX 3: Change AppBar background to the primary accent color
        backgroundColor: _primaryAccent, 
        iconTheme: const IconThemeData(color: Colors.white), // Ensures back button is white
        elevation: 4, // Added elevation to match teacher's AppBar
      ),
      body: Consumer<MaterialsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.materials.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: _primaryAccent,
              ),
            );
          }

          if (provider.materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 100,
                    color: _primaryAccent.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tiada bahan pembelajaran tersedia',
                    style: TextStyle(
                      fontSize: 20,
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Guru anda akan memuat naik bahan di sini untuk anda belajar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _subTextColor,
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
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
                        color: _textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      material.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _subTextColor,
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
        color: _cardHighlight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        material.className,
        style: TextStyle(
          fontSize: 12,
          color: _primaryAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    const Spacer(),
    
    IconButton(
      icon: Icon(Icons.download, size: 20, color: _primaryAccent),
      onPressed: () => _downloadMaterial(context, material, provider),
    ),
  ],
),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      'Oleh ${material.teacherName} • ${material.readableFileSize}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _subTextColor,
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

  Future<void> _downloadMaterial(BuildContext context, TeachingMaterial material, MaterialsProvider provider) async {
    try {
      await provider.downloadMaterial(material);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${material.title} berjaya dimuat turun'),
            backgroundColor: _primaryAccent,
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
}
