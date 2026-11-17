import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'API Posts',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const PostsPage(),
    );
  }
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final String apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  List<Map<String, dynamic>> posts = [];
  bool isLoading = false;

  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  // GET
  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          posts = data.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } else {
        showMessage('Failed to fetch posts');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // POST: Add a new post
  Future<void> addPost() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      showMessage('Please enter title and body');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );

      if (response.statusCode == 201) {
        final newPost = Map<String, dynamic>.from(jsonDecode(response.body));

        if (!mounted) return;

        setState(() {
          // Add the returned post to the local list.
          posts.insert(0, newPost);
        });

        titleController.clear();
        bodyController.clear();

        Navigator.pop(context);
        showMessage('Post added successfully');
      } else {
        showMessage('Failed to add post');
      }
    } catch (e) {
      showMessage('Error: $e');
    }
  }

  // DELETE: Delete a post using its ID
  Future<void> deletePost(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;

        setState(() {
          posts.removeWhere((post) => post['id'] == id);
        });

        showMessage('Post deleted successfully');
      } else {
        showMessage('Failed to delete post');
      }
    } catch (e) {
      showMessage('Error: $e');
    }
  }

  // PUT: Update an existing post
  Future<void> updatePost(int id) async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      showMessage('Please enter title and body');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'id': id, 'title': title, 'body': body, 'userId': 1}),
      );

      if (response.statusCode == 200) {
        final updatedPost = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );

        if (!mounted) return;

        setState(() {
          final index = posts.indexWhere((post) => post['id'] == id);

          if (index != -1) {
            posts[index] = updatedPost;
          }
        });

        titleController.clear();
        bodyController.clear();

        Navigator.pop(context);
        showMessage('Post updated successfully');
      } else {
        showMessage('Failed to update post');
      }
    } catch (e) {
      showMessage('Error: $e');
    }
  }

  void showEditPostDialog(Map<String, dynamic> post) {
    titleController.text = post['title'] ?? '';
    bodyController.text = post['body'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => updatePost(post['id'] as int),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Open the Add Post form
  void showAddPostDialog() {
    titleController.clear();
    bodyController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(onPressed: addPost, child: const Text('Submit')),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'API Posts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: fetchPosts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh posts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddPostDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Post'),
      ),
      body: isLoading && posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(child: Text('No posts available'))
          : RefreshIndicator(
              onRefresh: fetchPosts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(child: Text('${post['id']}')),
                      title: Text(
                        post['title']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(post['body']?.toString() ?? ''),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showEditPostDialog(post);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              deletePost(post['id'] as int);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
