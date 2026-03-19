import 'package:flutter/material.dart';
import '../../models/tour.dart';
import '../../services/mock_data_service.dart';
import '../../utils/formatter.dart';

class ManageToursPage extends StatefulWidget {
  const ManageToursPage({super.key});

  @override
  State<ManageToursPage> createState() => _ManageToursPageState();
}

class _ManageToursPageState extends State<ManageToursPage> {
  final MockDataService _dataService = MockDataService();
  List<Tour> _tours = [];

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    final tours = await _dataService.getTours();
    setState(() => _tours = tours);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tours')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _tours.length,
        itemBuilder: (context, index) {
          final tour = _tours[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                tour.images.firstWhere((img) => img.isPrimary).url,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            title: Text(tour.title),
            subtitle: Text(
              '${tour.location} - ${Formatter.formatCurrency(tour.basePrice)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _navigateToEdit(tour),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTour(tour.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToEdit([Tour? tour]) async {
    await Navigator.pushNamed(context, '/edit-tour', arguments: tour);
    _loadTours();
  }

  void _deleteTour(String id) async {
    await _dataService.deleteTour(id);
    _loadTours();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tour deleted')));
  }
}
