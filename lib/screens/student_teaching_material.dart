import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/materials_provider.dart';
import '../models/teaching_material.dart';

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
      backgroundColor: const Color(0xffdfeee7),
      appBar: AppBar(
        title: const Text(
          'Study Materials',
          style: TextStyle(
            color: Color(0xff2c4a3f),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff4f7f67),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<MaterialsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.materials.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xff4f7f67),
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
                    color: const Color(0xff6b9c7d).withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No study materials available',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff2c4a3f),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your teachers will upload materials here for you to study',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xff6b9c7d),
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
                        color: Color(0xff2c4a3f),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      material.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff6b9c7d),
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
        color: const Color(0xffdfeee7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        material.className,  // Changed to show class name
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xff4f7f67),
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    const Spacer(),
    
    IconButton(
      icon: const Icon(Icons.download, size: 20),
      color: const Color(0xff4f7f67),
      onPressed: () => _downloadMaterial(context, material, provider),
    ),
  ],
),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      'By ${material.teacherName} • ${material.readableFileSize}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xffa8c6b5),
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
            content: Text('${material.title} downloaded successfully'),
            backgroundColor: const Color(0xff4f7f67),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
