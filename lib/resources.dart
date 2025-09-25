// lib/resources_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'styles.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources', style: AppTextStyles.headingWhite),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resources')
            .orderBy('title')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No resources available.', style: AppTextStyles.subText),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final resource = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final title = resource['title'] ?? 'Untitled';
              final description = resource['description'] ?? '';
              final link = resource['link'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    title,
                    style: AppTextStyles.body,
                  ),
                  subtitle: Text(
                    description,
                    style: AppTextStyles.subText,
                  ),
                  trailing: link.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                          onPressed: () => _launchURL(link),
                        )
                      : null,
                  onTap: link.isNotEmpty ? () => _launchURL(link) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
