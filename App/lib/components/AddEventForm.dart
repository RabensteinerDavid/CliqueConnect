import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../main.dart';
import 'package:path/path.dart';



class AddEventForm extends StatefulWidget {
  const AddEventForm({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<AddEventForm> {

  DateTime? startDate;
  DateTime? endDate;
  //final TextEditingController coordinatesController = TextEditingController();
  var categories;
  String? selectedCategory;
  TextEditingController _addressController = TextEditingController();

  FocusNode _nameFocus = FocusNode();
  FocusNode _descriptionnFocuse = FocusNode();
  FocusNode _addressFocus = FocusNode();
  FocusNode _startDateFocus = FocusNode();
  FocusNode _startTimeFocus = FocusNode();
  FocusNode _endDateFocus = FocusNode();
  FocusNode _endTimeFocus = FocusNode();
  FocusNode _categoryFocus = FocusNode();

  Color _nameLabelColor = MyApp.greyDark;
  Color _descriptionlColor = MyApp.greyDark;
  Color _addressLabelColor = MyApp.greyDark;
  Color _startDateLabelColor = MyApp.greyDark;
  Color _startTimeLabelColor = MyApp.greyDark;
  Color _endDateLabelColor = MyApp.greyDark;
  Color _endTimeLabelColor = MyApp.greyDark;
  Color _categoryLabelColor = MyApp.greyDark;

  final TextEditingController activityNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  FocusNode? _lastFocused;

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    getCatergoryActivities();
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _descriptionnFocuse.dispose();
    _addressFocus.dispose();
    _startDateFocus.dispose();
    _startTimeFocus.dispose();
    _endDateFocus.dispose();
    _endTimeFocus.dispose();
    _categoryFocus.dispose();
    // Dispose of other focus nodes if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
        onTap: () {
      // Close keyboard when tapping outside text fields
      FocusScope.of(context).unfocus();

      // Reset label colors
      setState(() {
        _nameLabelColor = MyApp.greyDark;
        _descriptionlColor = MyApp.greyDark;
        _addressLabelColor = MyApp.greyDark;
        _startDateLabelColor = MyApp.greyDark;
        _startTimeLabelColor = MyApp.greyDark;
        _endDateLabelColor = MyApp.greyDark;
        _endTimeLabelColor = MyApp.greyDark;
        _categoryLabelColor = MyApp.greyDark;
      });

      // Set the last focused field to null
      _lastFocused = null;
    },
    child: Scaffold(
      body: Material(
        child: SingleChildScrollView(
          child: Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  color: MyApp.blueMain,
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.08,
                  left: MediaQuery.of(context).size.width * 0.1,
                  right: MediaQuery.of(context).size.width * 0.1,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.1,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/cliqueConnect.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40, // Adjust the top position as needed
                  left: 20, // Adjust the left position as needed
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white, // Set the color as needed
                    ),
                    onPressed: () {
                      Navigator.pop(context); // This will navigate back
                    },
                  ),
                ),
         Padding(
            padding: const EdgeInsets.fromLTRB(46.0, 380.0,46.0, 60.0),
            child: Column(
              children: [
                TextField(
                controller: activityNameController,
                focusNode: _nameFocus,
                onTap: () {
                setState(() {
                _nameLabelColor = MyApp.blueMain;
                _descriptionlColor = MyApp.greyDark;
                _addressLabelColor = MyApp.greyDark;
                _startDateLabelColor = MyApp.greyDark;
                _startTimeLabelColor = MyApp.greyDark;
                _endDateLabelColor = MyApp.greyDark;
                _endTimeLabelColor = MyApp.greyDark;
                _categoryLabelColor = MyApp.greyDark;
                _lastFocused = _nameFocus;
                });
                },
                decoration: InputDecoration(
                labelText: 'Activity name',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                labelStyle: TextStyle(
                color: _nameFocus.hasFocus ? MyApp.blueMain : _nameLabelColor,
                ),
                ),
                ),
                /*TextField(
                  controller: activityNameController,
                  decoration: InputDecoration(labelText: 'Activity name'),
                ),*/
                const SizedBox(height: 12.0),
                TextField(
                  controller: descriptionController,
                  focusNode: _descriptionnFocuse,
                  onTap: () {
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.blueMain;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _descriptionnFocuse;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _descriptionnFocuse.hasFocus ? MyApp.blueMain : _descriptionlColor,
                    ),
                  ),
                ),
            /*    TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),*/
                const SizedBox(height: 12.0),
                TextField(
                  controller: _addressController,
                  focusNode: _addressFocus,
                  onTap: () {
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.blueMain;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _descriptionnFocuse;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter an address',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _addressFocus.hasFocus ? MyApp.blueMain : _addressLabelColor,
                    ),
                  ),
                ),
             /*   TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Enter an address'),
                ),*/
                const SizedBox(height: 12.0),
         /*       InkWell(
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
                    FocusScope.of(context).requestFocus(_startDateFocus);

                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.blueMain; // Update to the desired color
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _categoryFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _startDateFocus.hasFocus ? MyApp.blueMain :  Colors.black54)),
                      labelStyle: TextStyle(
                        color: _startDateFocus.hasFocus ? MyApp.blueMain : _startDateLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          startDate != null
                              ? "${startDate!.toLocal()}".split(' ')[0]
                              : 'Select start date',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),

                ),*/
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white, // Set the background color to white
                          height: 200.0,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: DateTime.now(),
                            minimumDate: null,
                            maximumDate: DateTime(2101),
                            onDateTimeChanged: (DateTime newDate) {
                              if (newDate != null && newDate != startDate) {
                                setState(() {
                                  startDate = newDate;
                                });
                              }
                            },
                          ),
                        );
                      },
                    );
                    if (pickedDate != null && pickedDate != startDate) {
                      setState(() {
                        startDate = pickedDate;
                      });
                    }
                    FocusScope.of(context).requestFocus(_startDateFocus);

                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.blueMain;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _categoryFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _startDateFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                      labelStyle: TextStyle(
                        color: _startDateFocus.hasFocus ? MyApp.blueMain : _startDateLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          startDate != null
                              ? "${startDate!.toLocal()}".split(' ')[0]
                              : 'Select start date',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                /* InkWell(
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
                ),*/
                const SizedBox(height: 12.0),
                InkWell(
                  onTap: () async {
                    TimeOfDay? pickedTime = await showCupertinoModalPopup<TimeOfDay>(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white, // Set the background color to white
                          height: 200.0,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: DateTime.now(),
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime newTime) {
                              if (newTime != null && newTime != startDate) {
                                setState(() {
                                  startDate = DateTime(
                                    startDate!.year,
                                    startDate!.month,
                                    startDate!.day,
                                    newTime.hour,
                                    newTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        );
                      },
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
                    FocusScope.of(context).requestFocus(_startTimeFocus);

                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.blueMain; // Update to the desired color
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _startTimeFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Time', // Update to 'Start Time'
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _startTimeFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                      labelStyle: TextStyle(
                        color: _startTimeFocus.hasFocus ? MyApp.blueMain : _startTimeLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          startDate != null
                              ? '${"${startDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${startDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                              : 'Select start time',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),

                /*     InkWell(
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
                    FocusScope.of(context).requestFocus(_startTimeFocus);

                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.blueMain; // Update to the desired color
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _startTimeFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Time', // Update to 'Start Time'
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _startTimeFocus.hasFocus ? MyApp.blueMain :  Colors.black54)),
                      labelStyle: TextStyle(
                        color: _startTimeFocus.hasFocus ? MyApp.blueMain : _startTimeLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          startDate != null
                              ? '${"${startDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${startDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                              : 'Select start time',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),*/
                /* InkWell(
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
                              ? '${"${startDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${startDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                              : 'Select start time',
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),*/
                const SizedBox(height: 12.0),
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white, // Set the background color to white
                          height: 200.0,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: DateTime.now(),
                            minimumDate: null,
                            maximumDate: DateTime(2101),
                            onDateTimeChanged: (DateTime newDate) {
                              if (newDate != null && newDate != endDate) {
                                setState(() {
                                  endDate = newDate;
                                });
                              }
                            },
                          ),
                        );
                      },
                    );
                    if (pickedDate != null && pickedDate != endDate) {
                      setState(() {
                        endDate = pickedDate;
                      });

                      // Move the focus to the 'End Date' field after picking the date
                      FocusScope.of(context).requestFocus(_endDateFocus);
                    }

                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.blueMain; // Update to the desired color
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _endDateFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _endDateFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                      labelStyle: TextStyle(
                        color: _endDateFocus.hasFocus ? MyApp.blueMain : _endDateLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          endDate != null
                              ? "${endDate!.toLocal()}".split(' ')[0]
                              : 'Select end date',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),

                /* InkWell(
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

                      // Move the focus to the 'End Date' field after picking the date
                      FocusScope.of(context).requestFocus(_endDateFocus);
                    }

                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.blueMain; // Update to the desired color
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _endDateFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _endDateFocus.hasFocus ? MyApp.blueMain :  Colors.black54)),
                      labelStyle: TextStyle(
                        color: _endDateFocus.hasFocus ? MyApp.blueMain : _endDateLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          endDate != null
                              ? "${endDate!.toLocal()}".split(' ')[0]
                              : 'Select end date',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
*/
                /* InkWell(
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
                ),*/
                const SizedBox(height: 12.0),
                InkWell(
                  onTap: () async {
                    TimeOfDay? pickedTime = await showCupertinoModalPopup<TimeOfDay>(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white, // Set the background color to white
                          height: 200.0,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: DateTime.now(),
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime newDateTime) {
                              if (newDateTime != null && newDateTime != endDate) {
                                setState(() {
                                  endDate = DateTime(
                                    endDate!.year,
                                    endDate!.month,
                                    endDate!.day,
                                    newDateTime.hour,
                                    newDateTime.minute,
                                  );
                                });
                              }
                            },
                          ),
                        );
                      },
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

                    FocusScope.of(context).requestFocus(_endTimeFocus);
                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.blueMain;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _endTimeFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _endTimeFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      labelStyle: TextStyle(
                        color: _endTimeFocus.hasFocus ? MyApp.blueMain : _endTimeLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          endDate != null
                              ? '${"${endDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${endDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                              : 'Select end time',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),

                /* InkWell(
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

                    FocusScope.of(context).requestFocus(_endTimeFocus);
                    // Update the color logic
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.blueMain;
                      _categoryLabelColor = MyApp.greyDark;
                      _lastFocused = _endTimeFocus;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _endTimeFocus.hasFocus ? MyApp.blueMain :  Colors.black54)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      labelStyle: TextStyle(
                        color: _endTimeFocus.hasFocus ? MyApp.blueMain : _endTimeLabelColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          endDate != null
                              ? '${"${endDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${endDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                              : 'Select end time',
                          style: const TextStyle(
                            color: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),*/

                /*   InkWell(
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
                              ? '${"${endDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${endDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                              : 'Select end time',
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),*/
                const SizedBox(height: 12.0),
           /*     TextField(
                  controller: coordinatesController,
                  decoration: const InputDecoration(
                      labelText: 'Coordinates (e.g., 48.36611, 14.51646)'),
                ),*/
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories != null
                      ? categories.map<DropdownMenuItem<String>>((category) {
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
                  onTap: () {
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _endDateLabelColor = MyApp.greyDark;
                      _endTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.blueMain;
                      _lastFocused = _categoryFocus;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'Select your Category',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _categoryFocus.hasFocus ? MyApp.blueMain : _categoryLabelColor,
                    ),
                  ),
                ),
                // Dropdown for selecting category
               /* DropdownButtonFormField<String>(
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
                ),*/
                const SizedBox(height: 16.0),

                ElevatedButton(
                  onPressed: () => addCreativActivity(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: MyApp.blueMain, // Text color

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 3.0, // Elevation (shadow)
                  ),
                  child: const Text(
                    'Add Creativ Activity',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3 - 75,
                  left: MediaQuery.of(context).size.width * 0.5 - 125,
                  child: GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: Container(
                      width: 250,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xff8179b4),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: _photo != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: Image.file(
                          _photo!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.fitHeight,
                        ),
                      )
                          : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(0),
                        ),
                        width: 150,
                        height: 150,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),

                  ),
                ),
              ],

          ),
        ),

      ),
    ));
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  imgFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  imgFromCamera();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future _cropImage(File? imageFile) async {
    if (imageFile != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
          sourcePath: imageFile!.path,
          maxHeight: 400,
          maxWidth: 400,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          aspectRatioPresets:
          [
            CropAspectRatioPreset.square,
            //CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            //CropAspectRatioPreset.ratio4x3,
            //CropAspectRatioPreset.ratio16x9
          ],

          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Crop',
                cropGridColor: Colors.black,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: true),
            IOSUiSettings(title: 'Crop',aspectRatioLockEnabled: true)
          ]);

      if (cropped != null) {
        setState(() {
          _photo = File(cropped.path);
        });
      }
    }
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 0);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        _cropImage(File(pickedFile.path));
      } else {
        print('No img selected');
      }
    });
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 0);
    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        _cropImage(File(pickedFile.path));
      } else {
        print('No img selected');
      }
    });
  }

  Future uploadFile() async {
    if (_photo == null) {
      print('No file to upload');
      return;
    }
    final fileName = basename(_photo!.path);
    final destination = 'files/$fileName';

    try {
      final ref = storage.ref(destination);
      await ref.putFile(_photo!);
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  String _result = '';

  Future<void> _convertAddressToCoordinates() async {
    try {
      List<Location> locations = await locationFromAddress(
          _addressController.text);

      if (locations.isNotEmpty) {
        Location first = locations.first;
        setState(() {
          _result =
          'Latitude: ${first.latitude}, Longitude: ${first.longitude}';
        });
      } else {
        setState(() {
          _result = 'No coordinates found for the given address';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
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

  String extractNumbers(String input) {
    List<String> parts = input.split(RegExp(r'[^0-9.-]'));
    String result = parts.where((part) => part.isNotEmpty).join(', ');

    return result;
  }

  Future<void> addCreativActivity() async {
    await _convertAddressToCoordinates();

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
            double.parse(extractNumbers(_result.split(',')[0].trim())),
            double.parse(extractNumbers(_result.split(',')[1].trim())),
          ),
        ],
      });
      print('Creativ activity added successfully!');
      // Clear the text fields after adding the entry
      activityNameController.clear();
      descriptionController.clear();
      //coordinatesController.clear();
      _addressController.clear();
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

