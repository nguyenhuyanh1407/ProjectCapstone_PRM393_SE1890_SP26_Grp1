import 'package:flutter/material.dart';
import '../../models/tour.dart';
import '../../services/mock_data_service.dart';

class EditTourPage extends StatefulWidget {
  const EditTourPage({super.key});

  @override
  State<EditTourPage> createState() => _EditTourPageState();
}

class _EditTourPageState extends State<EditTourPage> {
  final _formKey = GlobalKey<FormState>();
  final MockDataService _dataService = MockDataService();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  Tour? _existingTour;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Tour) {
      _existingTour = args;
    }

    _titleController = TextEditingController(text: _existingTour?.title ?? '');
    _locationController = TextEditingController(
      text: _existingTour?.location ?? '',
    );
    _priceController = TextEditingController(
      text: _existingTour?.basePrice.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: _existingTour?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingTour == null ? 'Add New Tour' : 'Edit Tour'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Province)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Base Price'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTour,
                child: const Text('Save Tour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTour() async {
    if (_formKey.currentState!.validate()) {
      final tour = Tour(
        id: _existingTour?.id ?? 't-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        location: _locationController.text,
        basePrice: double.parse(_priceController.text),
        description: _descriptionController.text,
        maxParticipants: _existingTour?.maxParticipants ?? 10,
        tourType: _existingTour?.tourType ?? 'Group',
        durationDays: _existingTour?.durationDays ?? 1,
        status: 'Published',
        createdAt: _existingTour?.createdAt ?? DateTime.now(),
        images:
            _existingTour?.images ??
            [
              TourImage(
                url:
                    'https://images.unsplash.com/photo-1528127269322-539005d23819',
                isPrimary: true,
              ),
            ],
        itinerary: _existingTour?.itinerary,
      );

      if (_existingTour == null) {
        await _dataService.addTour(tour);
      } else {
        await _dataService.updateTour(tour);
      }

      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}
