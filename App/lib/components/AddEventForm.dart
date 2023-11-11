import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventForm extends StatefulWidget {
  const AddEventForm({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<AddEventForm> {
  final TextEditingController activityNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController coordinatesController = TextEditingController();
  var categories;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    getCatergoryActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Screen Title'),
      ),
      body: Material(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(46.0, 60.0, 16.0, 46.0),
            child: Column(
              children: [
                TextField(
                  controller: activityNameController,
                  decoration: InputDecoration(labelText: 'Activity name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != startDate) {
                      setState(() {
                        startDate = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          startDate != null
                              ? "${startDate!.toLocal()}".split(' ')[0]
                              : 'Select start date',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null && pickedTime != startDate) {
                      setState(() {
                        startDate = DateTime(
                          startDate!.year,
                          startDate!.month,
                          startDate!.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          startDate != null
                              ? "${startDate!.toLocal()}".split(' ')[1]
                              : 'Select start time',
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != endDate) {
                      setState(() {
                        endDate = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          endDate != null
                              ? "${endDate!.toLocal()}".split(' ')[0]
                              : 'Select end date',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null && pickedTime != endDate) {
                      setState(() {
                        endDate = DateTime(
                          endDate!.year,
                          endDate!.month,
                          endDate!.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          endDate != null
                              ? "${endDate!.toLocal()}".split(' ')[1]
                              : 'Select end time',
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: coordinatesController,
                  decoration: const InputDecoration(
                      labelText: 'Coordinates (e.g., 48.36611, 14.51646)'),
                ),
                // Dropdown for selecting category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories != null
                      ? categories.map<DropdownMenuItem<String>>(
                          (category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () => addCreativActivity(),
                  child: const Text('Add Creativ Activity'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //48.36611, 14.51646
  Future<String?> getCatergoryActivities() async {
    try {
      final activitiesCollectionRef =
      FirebaseFirestore.instance.collection("categoriesActivities");
      final data = await activitiesCollectionRef.doc("category").get();

      if (data.exists) {
        setState(() {
          data.data()!.forEach((key, value) {
            categories = value;
            print(categories);
          });
        });
        return "Data retrieved successfully.";
      } else {
        print("Document does not exist");
        return null;
      }
    } catch (e) {
      print('Error retrieving data: $e');
      return null;
    }
  }

  Future<void> addCreativActivity() async {
    CollectionReference creativCollection =
    FirebaseFirestore.instance.collection('activities');

    String newActivity = activityNameController.text;
    try {
      await creativCollection.doc(selectedCategory).update({
        newActivity: [
          activityNameController.text,
          descriptionController.text,
          Timestamp.fromDate(startDate!),
          Timestamp.fromDate(endDate!),
          GeoPoint(
            double.parse(coordinatesController.text.split(',')[0].trim()),
            double.parse(coordinatesController.text.split(',')[1].trim()),
          ),
        ],
      });
      print('Creativ activity added successfully!');
      // Clear the text fields after adding the entry
      activityNameController.clear();
      descriptionController.clear();
      coordinatesController.clear();
      setState(() {
        startDate = null;
        endDate = null;
        selectedCategory = null;
      });
    } catch (e) {
      print('Error adding creativ activity: $e');
    }
  }
}
