import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isloading = true;
  List<Movie> movies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Favorite Movies'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showModalBottomSheet(context: context),
        label: const Text('Add Movie'),
        icon: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (_isloading) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (movies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_creation,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No movies found',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: movies.length,
            itemBuilder: (context, index) {
              Movie movie = movies[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Image.network(
                  movie.imageUrl,
                  fit: BoxFit.cover,
                ),
                title: Text(movie.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        var snapshot = ParseObject('Movie')
                          ..objectId = movie.objectId
                          ..set('addedToWatchList', !movie.addedToWatchList);
                        await snapshot.save();
                        setState(() {
                          movies[index] = movie.copyWith(
                            addedToWatchList: !movie.addedToWatchList,
                          );
                        });
                      },
                      icon: Icon(
                        Icons.watch_later,
                        color: !movie.addedToWatchList
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showModalBottomSheet(
                          movie: movie,
                          context: context,
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete Movie'),
                              content: const Text(
                                  'Are you sure you want to delete this movie?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    var snapshot = ParseObject('Movie')
                                      ..objectId = movie.objectId;
                                    await snapshot.delete();
                                    setState(() {
                                      movies.removeAt(index);
                                    });
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showModalBottomSheet({Movie? movie, required BuildContext context}) {
    TextEditingController nameController = TextEditingController();
    TextEditingController imgUrlController = TextEditingController(
        text:
            'https://upload.wikimedia.org/wikipedia/en/4/4c/Deadpool_%26_Wolverine_poster.jpg');

    if (movie != null) {
      nameController.text = movie.title;
      imgUrlController.text = movie.imageUrl;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      elevation: 5,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(labelText: 'Movie title'),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: imgUrlController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  final movieParse = ParseObject('Movie');

                  String title = nameController.text;
                  String imageUrl = imgUrlController.text;
                  String id = DateTime.now().millisecondsSinceEpoch.toString();
                  bool addedToWatchList = false;

                  if (movie != null) {
                    var snapshot = ParseObject('Movie')
                      ..objectId = movie.objectId
                      ..set('title', title)
                      ..set('imageUrl', imageUrl);
                    await snapshot.save();
                    _loadMovies();
                  } else {
                    movieParse.set('title', title);
                    movieParse.set('imageUrl', imageUrl);
                    movieParse.set('addedToWatchList', addedToWatchList);
                    movieParse.set('movieId', id);

                    final ParseResponse parseResponse = await movieParse.save();

                    if (parseResponse.success) {
                      final movieId =
                          (parseResponse.results!.first as ParseObject)
                              .objectId!;
                      debugPrint('Object created: $movieId');

                      showSnack("Object created: $movieId");
                      setState(() {
                        movies.add(Movie(
                          id: id,
                          title: title,
                          imageUrl: imageUrl,
                          addedToWatchList: addedToWatchList,
                        ));
                      });
                    } else {
                      debugPrint(
                          'Object created with failed: ${parseResponse.error.toString()}');

                      showSnack(
                          "Object created with failed: ${parseResponse.error.toString()}");
                    }
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  showSnack(String message) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _loadMovies() async {
    final queryBuilder = QueryBuilder<ParseObject>(ParseObject('Movie'))
      ..orderByAscending('title');

    final response = await queryBuilder.query();

    if (response.success && response.results != null) {
      final List<Movie> loadedMovies = response.results!.map((parseObject) {
        return Movie(
          objectId: parseObject.get('objectId'),
          id: parseObject.get('movieId'),
          title: parseObject.get('title'),
          imageUrl: parseObject.get('imageUrl'),
          addedToWatchList: parseObject.get('addedToWatchList'),
        );
      }).toList();

      setState(() {
        _isloading = false;
        movies = loadedMovies;
      });
    } else {
      setState(() {
        _isloading = false;
        movies = [];
      });
    }
  }
}

class Movie {
  final String id;
  final String title;
  final String imageUrl;
  final bool addedToWatchList;
  final String? objectId;

  Movie({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.addedToWatchList,
    this.objectId,
  });

  Movie copyWith({
    String? id,
    String? objectId,
    String? title,
    String? imageUrl,
    bool? addedToWatchList,
  }) {
    return Movie(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      addedToWatchList: addedToWatchList ?? this.addedToWatchList,
    );
  }
}
