import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:rrule/rrule.dart';
import '../helper/helper_functions.dart';
import '../main.dart';
import 'package:path/path.dart';

import '../services/database_service.dart';
import 'Event.dart';
import 'NavigationBar.dart';

class EditEventForm extends StatefulWidget {
  final String activityName;
  final String description;
  final String imageURL;
  final String location;
  final DateTime firstTime;
  final String secondTime;
  final String thirdTime;
  final String category;
  final String rrule;
  final bool moreDatesToView;
  final bool sameDate;

  // Use a constant RecurrenceRule as the default value
  const EditEventForm({
    Key? key,
    required this.activityName,
    required this.description,
    required this.location,
    required this.firstTime,
    this.secondTime="",
    this.thirdTime="",
    required this.category,
    this.rrule = "",
    this.moreDatesToView = false,
    this.sameDate = false,
    this.imageURL = ""
  }) : super(key: key);

  @override
  _EventState createState() => _EventState();
}


class _EventState extends State<EditEventForm> {

  DateTime? startDate;
  DateTime? secondStartDate;
  DateTime? thirdStartDate;

  String? selectedCategory;

  var categories;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocuse = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _startDateFocus = FocusNode();
  final FocusNode _startTimeFocus = FocusNode();
  final FocusNode _secondStartDateFocus = FocusNode();
  final FocusNode _secondEndTimeFocus = FocusNode();
  final FocusNode _thirdStartDateFocus = FocusNode();
  final FocusNode _thirdEndTimeFocus = FocusNode();
  final FocusNode _categoryFocus = FocusNode();
  final FocusNode _weeklyFocus = FocusNode();
  final FocusNode _endMonthFocus = FocusNode();
  final FocusNode _intervallFocus = FocusNode();

  Color _nameLabelColor = MyApp.greyDark;
  Color _descriptionlColor = MyApp.greyDark;
  Color _addressLabelColor = MyApp.greyDark;
  Color _startDateLabelColor = MyApp.greyDark;
  Color _startTimeLabelColor = MyApp.greyDark;
  Color _secondDateLabelColor = MyApp.greyDark;
  Color _secondTimeLabelColor = MyApp.greyDark;
  Color _thirdDateLabelColor = MyApp.greyDark;
  Color _thirdTimeLabelColor = MyApp.greyDark;
  Color _categoryLabelColor = MyApp.greyDark;
  Color _weeklyLabelColor = MyApp.greyDark;
  Color _endMonthLabelColor = MyApp.greyDark;
  Color _intervalLabelColor = MyApp.greyDark;

  bool _startDateText = false;
  bool _startTimeText = false;
  bool _secondStartDateText = false;
  bool _thirdStartDateText = false;

  final TextEditingController activityNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _intervallController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  RecurrenceRule? recurrenceRule;
  String? selectedFrequency;
  String? selectedTillMonth;
  int? selectedInterval;

  File? _photo;
  User? _user;
  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
  var rrule;

  @override
  void initState() {
    super.initState();
    getCatergoryActivities();
    rrule = parseRecurrenceRule(widget.rrule);
    if(rrule != null){
      showAdditionalFields = true;
    }
    showSecondDate = widget.moreDatesToView;
    activityNameController.text = widget.activityName;
    descriptionController.text = widget.description;
    _addressController.text = widget.location;
    _intervallController.text = rrule?.interval.toString() ?? '';
    startDate = widget.firstTime;
    secondStartDate = DateTime.parse(widget.secondTime);
    thirdStartDate = DateTime.parse(widget.thirdTime);
    selectedCategory = widget.category;
    selectedFrequency = rrule != null ? capitalizeFirstLetter(rrule?.frequency.toString() ?? '' ) : selectedFrequency;
    selectedTillMonth = rrule != null ? capitalizeFirstLetter(_getMonthNames(rrule?.byMonths)) : selectedTillMonth;

    try {
      // Validate that the input is not empty and contains only digits
      if (_intervallController.text.isNotEmpty && _intervallController.text.replaceAll(RegExp(r'\D'), '').isNotEmpty) {
        // Parse the content of _intervallController.text as an integer
        selectedInterval = int.parse(_intervallController.text);
      } else {
        // Handle the case where the input is empty or not a valid integer
        print('Invalid input for interval');
      }
    } catch (e) {
      // Handle the case where the text cannot be parsed as an integer
      print('Error parsing interval: $e');
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _descriptionFocuse.dispose();
    _addressFocus.dispose();
    _startDateFocus.dispose();
    _startTimeFocus.dispose();
    _secondStartDateFocus.dispose();
    _secondEndTimeFocus.dispose();
    _thirdStartDateFocus.dispose();
    _thirdEndTimeFocus.dispose();
    _categoryFocus.dispose();
    _weeklyFocus.dispose();
    _endMonthFocus.dispose();
    _intervallFocus.dispose();
    super.dispose();
  }

  bool showAdditionalFields = false;
  bool showSecondDate = false;

  List<String> frequencies = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  List<String> tillMonth = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  String _formatDate(DateTime dateTime) {
    String formattedMonth = dateTime.month < 10 ? '0${dateTime.month}' : '${dateTime.month}';
    String formattedDay = dateTime.day < 10 ? '0${dateTime.day}' : '${dateTime.day}';

    return '${dateTime.year}-$formattedMonth-$formattedDay';
  }

  String _formatTime(DateTime dateTime) {
    String formattedHour = dateTime.hour.toString().padLeft(2, '0');
    String formattedMinute = dateTime.minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute';
  }

  String _getMonthNames(Set<int>? monthNumbers) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final List<String>? selectedMonthNames = monthNumbers?.map((monthNumber) {
      if (monthNumber >= 1 && monthNumber <= 12) {
        return monthNames[monthNumber - 1];
      } else {
        return 'Unknown';
      }
    }).toList();

    return selectedMonthNames?.join('') ?? '';
  }

  RecurrenceRule? parseRecurrenceRule(String? rruleString) {
    try {
      if (rruleString != null) {
        return RecurrenceRule.fromString(rruleString);
      }
    } catch (e) {
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
         FocusScope.of(context).unfocus();
          setState(() {
            _nameLabelColor = MyApp.greyDark;
            _descriptionlColor = MyApp.greyDark;
            _addressLabelColor = MyApp.greyDark;
            _startDateLabelColor = MyApp.greyDark;
            _startTimeLabelColor = MyApp.greyDark;
            _secondDateLabelColor = MyApp.greyDark;
            _secondTimeLabelColor = MyApp.greyDark;
            _thirdDateLabelColor = MyApp.greyDark;
            _thirdTimeLabelColor = MyApp.greyDark;
            _categoryLabelColor = MyApp.greyDark;
            _weeklyLabelColor = MyApp.greyDark;
            _endMonthLabelColor = MyApp.greyDark;
            _intervalLabelColor = MyApp.greyDark;
          });
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
                AppBar(
                  elevation: 0.0,
                  backgroundColor: Color(0x2E148C),
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(005.0),
                      child: Image.asset(
                        'icons/arrow_white_noBG_white.png',
                        width: 30,
                        height: 30,
                      ),
                    ),
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
                      _secondDateLabelColor = MyApp.greyDark;
                      _secondTimeLabelColor = MyApp.greyDark;
                      _thirdDateLabelColor = MyApp.greyDark;
                      _thirdTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _weeklyLabelColor = MyApp.greyDark;
                      _endMonthLabelColor = MyApp.greyDark;
                      _intervalLabelColor = MyApp.greyDark;
                    });
                  },
                    decoration: InputDecoration(
                    labelText: 'Activity Name',
                    border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide:  BorderSide(color: MyApp.blueMain),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _nameFocus.hasFocus ? MyApp.blueMain : _nameLabelColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: descriptionController,
                  focusNode: _descriptionFocuse,
                  onTap: () {
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.blueMain;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.greyDark;
                      _secondDateLabelColor = MyApp.greyDark;
                      _secondTimeLabelColor = MyApp.greyDark;
                      _thirdDateLabelColor = MyApp.greyDark;
                      _thirdTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _weeklyLabelColor = MyApp.greyDark;
                      _endMonthLabelColor = MyApp.greyDark;
                      _intervalLabelColor = MyApp.greyDark;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide:  BorderSide(color: MyApp.blueMain),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _descriptionFocuse.hasFocus ? MyApp.blueMain : _descriptionlColor,
                    ),
                  ),
                ),
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
                      _secondDateLabelColor = MyApp.greyDark;
                      _secondTimeLabelColor = MyApp.greyDark;
                      _thirdDateLabelColor = MyApp.greyDark;
                      _thirdTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _weeklyLabelColor = MyApp.greyDark;
                      _endMonthLabelColor = MyApp.greyDark;
                      _intervalLabelColor = MyApp.greyDark;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Address e.g. Softwarepark 11 4232 Hagenberg',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide:  BorderSide(color: MyApp.blueMain),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _addressFocus.hasFocus ? MyApp.blueMain : _addressLabelColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white,
                          height: 200.0,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: widget.firstTime,
                            minimumDate: null,
                            maximumDate: DateTime(2101),
                            onDateTimeChanged: (DateTime newDate) {
                              if (newDate != null && newDate != startDate) {
                                setState(() {
                                  startDate = newDate;
                                  _startDateText = true;
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
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.blueMain;
                      _startTimeLabelColor = MyApp.greyDark;
                      _secondDateLabelColor = MyApp.greyDark;
                      _secondTimeLabelColor = MyApp.greyDark;
                      _thirdDateLabelColor = MyApp.greyDark;
                      _thirdTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _weeklyLabelColor = MyApp.greyDark;
                      _endMonthLabelColor = MyApp.greyDark;
                      _intervalLabelColor = MyApp.greyDark;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _startDateFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                      focusedBorder: OutlineInputBorder(
                        borderSide:  BorderSide(color: MyApp.blueMain),
                      ),
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
                              : _formatDate(widget.firstTime),
                          style: TextStyle(
                            color: _startDateText ? MyApp.black : MyApp.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                InkWell(
                  onTap: () async {
                    TimeOfDay? pickedTime = await showCupertinoModalPopup<TimeOfDay>(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.white,
                          height: 200.0,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: widget.firstTime,
                            use24hFormat: true,
                            onDateTimeChanged: (DateTime newTime) {
                              if (newTime != null && newTime != startDate) {
                                setState(() {
                                  _startTimeText = true;
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
                    setState(() {
                      _nameLabelColor = MyApp.greyDark;
                      _descriptionlColor = MyApp.greyDark;
                      _addressLabelColor = MyApp.greyDark;
                      _startDateLabelColor = MyApp.greyDark;
                      _startTimeLabelColor = MyApp.blueMain;
                      _secondDateLabelColor = MyApp.greyDark;
                      _secondTimeLabelColor = MyApp.greyDark;
                      _thirdDateLabelColor = MyApp.greyDark;
                      _thirdTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.greyDark;
                      _weeklyLabelColor = MyApp.greyDark;
                      _endMonthLabelColor = MyApp.greyDark;
                      _intervalLabelColor = MyApp.greyDark;
                    });
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _startTimeFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                      focusedBorder: OutlineInputBorder(
                        borderSide:  BorderSide(color: MyApp.blueMain),
                      ),
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
                              : _formatTime(widget.firstTime),
                          style: TextStyle(
                            color:_startTimeText ? MyApp.black: MyApp.black,
                          ),
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
             if (showSecondDate)
                  Column(
                  children: [
                    const Divider(
                      color: Colors.black12,
                      height: 20,
                      thickness: 1,
                    ),
                    const SizedBox(height: 12.0),
                    InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
                          context: context,
                          builder: (context) {
                            return Container(
                              color: Colors.white,
                              height: 200.0,
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.date,
                                initialDateTime: widget.firstTime,
                                minimumDate: null,
                                maximumDate: DateTime(2101),
                                onDateTimeChanged: (DateTime newDate) {
                                  if (newDate != null && newDate != secondStartDate) {
                                    setState(() {
                                      secondStartDate = newDate;
                                      _secondStartDateText = true;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        );
                        if (pickedDate != null && pickedDate != secondStartDate) {
                          setState(() {
                            secondStartDate = pickedDate;
                          });
                        }
                        FocusScope.of(context).requestFocus(_secondStartDateFocus);
                        setState(() {
                          _nameLabelColor = MyApp.greyDark;
                          _descriptionlColor = MyApp.greyDark;
                          _addressLabelColor = MyApp.greyDark;
                          _startDateLabelColor = MyApp.greyDark;
                          _startTimeLabelColor = MyApp.greyDark;
                          _secondDateLabelColor = _secondStartDateText ? MyApp.blueMain : MyApp.greyDark;
                          _secondTimeLabelColor = MyApp.greyDark;
                          _thirdDateLabelColor = MyApp.greyDark;
                          _thirdTimeLabelColor = MyApp.greyDark;
                          _categoryLabelColor = MyApp.greyDark;
                          _weeklyLabelColor = MyApp.greyDark;
                          _endMonthLabelColor = MyApp.greyDark;
                          _intervalLabelColor = MyApp.greyDark;
                        });
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Second Date',
                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _secondStartDateFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                          focusedBorder: OutlineInputBorder(
                            borderSide:  BorderSide(color: MyApp.blueMain),
                          ),
                          labelStyle: TextStyle(
                            color: _secondStartDateFocus.hasFocus ? MyApp.blueMain : _secondDateLabelColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              secondStartDate != null
                                  ? "${secondStartDate!.toLocal()}".split(' ')[0]
                                  : widget.sameDate ? '${_formatDate(DateTime.parse(widget.secondTime))}':'Select Second Date',
                              style: TextStyle(
                                color: _secondStartDateText ? MyApp.black : widget.sameDate ? MyApp.black : _secondDateLabelColor,
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    InkWell(
                      onTap: () async {
                        TimeOfDay? pickedTime = await showCupertinoModalPopup<TimeOfDay>(
                          context: context,
                          builder: (context) {
                            return Container(
                              color: Colors.white,
                              height: 200.0,
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.time,
                                initialDateTime: widget.firstTime,
                                use24hFormat: true,
                                onDateTimeChanged: (DateTime newDateTime) {
                                  if (newDateTime != null && newDateTime != secondStartDate) {
                                    _secondStartDateText = true;
                                    setState(() {
                                      secondStartDate = DateTime(
                                        secondStartDate!.year,
                                        secondStartDate!.month,
                                        secondStartDate!.day,
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
                        if (pickedTime != null && pickedTime != secondStartDate) {
                          setState(() {
                            secondStartDate = DateTime(
                              secondStartDate!.year,
                              secondStartDate!.month,
                              secondStartDate!.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                        FocusScope.of(context).requestFocus(_secondEndTimeFocus);
                        setState(() {
                          _nameLabelColor = MyApp.greyDark;
                          _descriptionlColor = MyApp.greyDark;
                          _addressLabelColor = MyApp.greyDark;
                          _startDateLabelColor = MyApp.greyDark;
                          _startTimeLabelColor = MyApp.greyDark;
                          _secondDateLabelColor = MyApp.greyDark;
                          _secondTimeLabelColor = MyApp.blueMain;
                          _thirdDateLabelColor = MyApp.greyDark;
                          _thirdTimeLabelColor = MyApp.greyDark;
                          _categoryLabelColor = MyApp.greyDark;
                          _weeklyLabelColor = MyApp.greyDark;
                          _endMonthLabelColor = MyApp.greyDark;
                          _intervalLabelColor = MyApp.greyDark;
                        });
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Second Time',
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _secondEndTimeFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                          focusedBorder: OutlineInputBorder(
                            borderSide:  BorderSide(color: MyApp.blueMain),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                          labelStyle: TextStyle(
                            color: _secondEndTimeFocus.hasFocus ? MyApp.blueMain : _secondTimeLabelColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              secondStartDate != null
                                  ? '${"${secondStartDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${secondStartDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                                  : widget.sameDate ? '${_formatTime(DateTime.parse(widget.secondTime))}':'Select Second Time',
                              style: TextStyle(
                                color: _secondStartDateText ? MyApp.black : widget.sameDate ? MyApp.black : _secondTimeLabelColor,
                              ),
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              DateTime? pickedDate = await showCupertinoModalPopup<DateTime>(
                                context: context,
                                builder: (context) {
                                  return Container(
                                    color: Colors.white,
                                    height: 200.0,
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.date,
                                      initialDateTime: widget.firstTime,
                                      minimumDate: null,
                                      maximumDate: DateTime(2101),
                                      onDateTimeChanged: (DateTime newDate) {
                                        if (newDate != null && newDate != thirdStartDate) {
                                          setState(() {
                                            thirdStartDate = newDate;
                                            _thirdStartDateText = true;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                },
                              );
                              if (pickedDate != null && pickedDate != thirdStartDate) {
                                setState(() {
                                  thirdStartDate = pickedDate;
                                });
                              }
                              FocusScope.of(context).requestFocus(_thirdStartDateFocus);
                              setState(() {
                                _nameLabelColor = MyApp.greyDark;
                                _descriptionlColor = MyApp.greyDark;
                                _addressLabelColor = MyApp.greyDark;
                                _startDateLabelColor = MyApp.greyDark;
                                _startTimeLabelColor = MyApp.greyDark;
                                _secondDateLabelColor = MyApp.greyDark;
                                _secondTimeLabelColor = MyApp.greyDark;
                                _thirdDateLabelColor = MyApp.blueMain;
                                _thirdTimeLabelColor = MyApp.greyDark;
                                _categoryLabelColor = MyApp.greyDark;
                                _weeklyLabelColor = MyApp.greyDark;
                                _endMonthLabelColor = MyApp.greyDark;
                                _intervalLabelColor = MyApp.greyDark;
                              });
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Third Date',
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _thirdStartDateFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(color: MyApp.blueMain),
                                ),
                                labelStyle: TextStyle(
                                  color: _thirdStartDateFocus.hasFocus ? MyApp.blueMain : _thirdDateLabelColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    thirdStartDate != null
                                        ? "${thirdStartDate!.toLocal()}".split(' ')[0]
                                        : (widget.sameDate && !isWithinTolerance(DateTime.parse(widget.secondTime), DateTime.parse(widget.thirdTime), Duration(seconds: 99)))
                                        ? '${_formatDate(DateTime.parse(widget.thirdTime))}'
                                        :"Select Third Start Date" ,
                                    style: TextStyle(
                                      color: _thirdStartDateText ? MyApp.black : widget.sameDate ? MyApp.black : _thirdDateLabelColor,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          InkWell(
                            onTap: () async {
                              TimeOfDay? pickedTime = await showCupertinoModalPopup<TimeOfDay>(
                                context: context,
                                builder: (context) {
                                  return Container(
                                    color: Colors.white,
                                    height: 200.0,
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.time,
                                      initialDateTime: widget.firstTime,
                                      use24hFormat: true,
                                      onDateTimeChanged: (DateTime newDateTime) {
                                        if (newDateTime != null && newDateTime != thirdStartDate) {
                                          _thirdStartDateText = true;
                                          setState(() {
                                            thirdStartDate = DateTime(
                                              thirdStartDate!.year,
                                              thirdStartDate!.month,
                                              thirdStartDate!.day,
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
                              if (pickedTime != null && pickedTime != thirdStartDate) {
                                setState(() {
                                  thirdStartDate = DateTime(
                                    thirdStartDate!.year,
                                    thirdStartDate!.month,
                                    thirdStartDate!.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                              FocusScope.of(context).requestFocus(_thirdEndTimeFocus);
                              setState(() {
                                _nameLabelColor = MyApp.greyDark;
                                _descriptionlColor = MyApp.greyDark;
                                _addressLabelColor = MyApp.greyDark;
                                _startDateLabelColor = MyApp.greyDark;
                                _startTimeLabelColor = MyApp.greyDark;
                                _secondDateLabelColor = MyApp.greyDark;
                                _secondTimeLabelColor = MyApp.greyDark;
                                _thirdDateLabelColor = MyApp.greyDark;
                                _thirdTimeLabelColor = MyApp.blueMain;
                                _categoryLabelColor = MyApp.greyDark;
                                _weeklyLabelColor = MyApp.greyDark;
                                _endMonthLabelColor = MyApp.greyDark;
                                _intervalLabelColor = MyApp.greyDark;
                              });
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Third Time',
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _thirdEndTimeFocus.hasFocus ? MyApp.blueMain : Colors.black54)),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:  BorderSide(color: MyApp.blueMain),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                labelStyle: TextStyle(
                                  color: _thirdEndTimeFocus.hasFocus ? MyApp.blueMain : _thirdTimeLabelColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    thirdStartDate != null
                                        ? '${"${thirdStartDate!.toLocal()}".split(' ')[1].split(":")[0]}:${"${thirdStartDate!.toLocal()}".split(' ')[1].split(":")[1]}'
                                        : (widget.sameDate && !isWithinTolerance(DateTime.parse(widget.secondTime), DateTime.parse(widget.thirdTime), Duration(seconds: 99))
                                        ? '${_formatTime(DateTime.parse(widget.thirdTime))}'
                                        : "Third Start Time"),
                                    style: TextStyle(
                                      color: _thirdStartDateText ? MyApp.black : widget.sameDate ? MyApp.black : _thirdTimeLabelColor,
                                    ),
                                  ),

                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ),
                    ]
                  ),
                const SizedBox(height: 12.0),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showSecondDate = !showSecondDate;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: MyApp.greyDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: Text(showSecondDate ? 'No additional Date' : 'Additional Date',
                      style: TextStyle(color: Colors.white,),
                    ),
                  ),
                ),
                const SizedBox(height: 22.0),
                DropdownButtonFormField<String>(
                  value: widget.category,
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
                      _secondDateLabelColor = MyApp.greyDark;
                      _secondTimeLabelColor = MyApp.greyDark;
                      _thirdDateLabelColor = MyApp.greyDark;
                      _thirdTimeLabelColor = MyApp.greyDark;
                      _categoryLabelColor = MyApp.blueMain;
                      _weeklyLabelColor = MyApp.greyDark;
                      _endMonthLabelColor = MyApp.greyDark;
                      _intervalLabelColor = MyApp.greyDark;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'Select your Category',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide:  BorderSide(color: MyApp.blueMain),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                    labelStyle: TextStyle(
                      color: _categoryFocus.hasFocus ? MyApp.blueMain : _categoryLabelColor,
                    ),
                  ),
                ),
                if (showAdditionalFields)
                   Column(
                    children: [
                      const SizedBox(height: 12.0),
                      Column(
                        children: [
                          const Divider(
                            color: Colors.black12,
                            height: 20,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12.0),
                          DropdownButtonFormField<String>(
                            value: rrule != null ? capitalizeFirstLetter(rrule?.frequency.toString() ?? '' ) : selectedFrequency,
                            items: frequencies.map((frequency) {
                              return DropdownMenuItem<String>(
                                value: frequency,
                                child: Text(frequency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedFrequency = value;
                              });
                            },
                            onTap: () {
                              setState(() {
                                _nameLabelColor = MyApp.greyDark;
                                _descriptionlColor = MyApp.greyDark;
                                _addressLabelColor = MyApp.greyDark;
                                _startDateLabelColor = MyApp.greyDark;
                                _startTimeLabelColor = MyApp.greyDark;
                                _secondDateLabelColor = MyApp.greyDark;
                                _secondTimeLabelColor = MyApp.greyDark;
                                _thirdDateLabelColor = MyApp.greyDark;
                                _thirdTimeLabelColor = MyApp.greyDark;
                                _categoryLabelColor = MyApp.greyDark;
                                _weeklyLabelColor = MyApp.blueMain;
                                _endMonthLabelColor = MyApp.greyDark;
                                _intervalLabelColor = MyApp.greyDark;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Weekly',
                              hintText: 'Select your Interval',
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:  BorderSide(color: MyApp.blueMain),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 10.0),
                              labelStyle: TextStyle(
                                color: _weeklyFocus.hasFocus
                                    ? MyApp.blueMain
                                    : _weeklyLabelColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          DropdownButtonFormField<String>(
                            value: rrule != null ? capitalizeFirstLetter(_getMonthNames(rrule?.byMonths)) : selectedTillMonth,
                            items: tillMonth.map((month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedTillMonth = value;
                              });
                            },
                            onTap: () {
                              setState(() {
                                _nameLabelColor = MyApp.greyDark;
                                _descriptionlColor = MyApp.greyDark;
                                _addressLabelColor = MyApp.greyDark;
                                _startDateLabelColor = MyApp.greyDark;
                                _startTimeLabelColor = MyApp.greyDark;
                                _secondDateLabelColor = MyApp.greyDark;
                                _secondTimeLabelColor = MyApp.greyDark;
                                _thirdDateLabelColor = MyApp.greyDark;
                                _thirdTimeLabelColor = MyApp.greyDark;
                                _categoryLabelColor = MyApp.greyDark;
                                _weeklyLabelColor = MyApp.greyDark;
                                _endMonthLabelColor = MyApp.blueMain;
                                _intervalLabelColor = MyApp.greyDark;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Till which Months',
                              hintText: 'Select till Month',
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:  BorderSide(color: MyApp.blueMain),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 10.0),
                              labelStyle: TextStyle(
                                color: _endMonthFocus.hasFocus
                                    ? MyApp.blueMain
                                    : _endMonthLabelColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          TextField(
                            controller: _intervallController,
                            focusNode: _intervallFocus,
                            onTap: () {
                              setState(() {
                                _nameLabelColor = MyApp.greyDark;
                                _descriptionlColor = MyApp.greyDark;
                                _addressLabelColor = MyApp.greyDark;
                                _startDateLabelColor = MyApp.greyDark;
                                _startTimeLabelColor = MyApp.greyDark;
                                _secondDateLabelColor = MyApp.greyDark;
                                _secondTimeLabelColor = MyApp.greyDark;
                                _thirdDateLabelColor = MyApp.greyDark;
                                _thirdTimeLabelColor = MyApp.greyDark;
                                _categoryLabelColor = MyApp.greyDark;
                                _weeklyLabelColor = MyApp.greyDark;
                                _endMonthLabelColor = MyApp.greyDark;
                                _intervalLabelColor = MyApp.blueMain;
                              });
                            },
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              selectedInterval = int.tryParse(value);
                            },
                            decoration:  InputDecoration(
                              labelText: 'Repeat every e.g. 2 Weeks',
                              labelStyle: TextStyle(
                                color: _intervallFocus.hasFocus ? MyApp.blueMain : _intervalLabelColor,
                              ),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:  BorderSide(color: MyApp.blueMain),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 10.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 22.0),
                    SizedBox(
                      width: 540,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showAdditionalFields = !showAdditionalFields;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: MyApp.greyDark,
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        child: Text(showAdditionalFields ? 'Not Repeat' : 'Repeat' ,style: TextStyle(color: Colors.white,),
                          ),
                        ),
                    ),
                      const SizedBox(height: 22.0),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).height -50,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => savePictureToFirestore(context),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: MyApp.blueMain,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 3.0,
                          ),
                          child: const Text(
                            'Edit Activity',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                        width: MediaQuery.sizeOf(context).height -50,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => deleteEvent(context),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Color(0xff831d1d),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 3.0,
                          ),
                          child: const Text(
                            'Delete Event',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3 - 75,
                  left: MediaQuery.of(context).size.width * 0.5 - 100,
                  child: GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: Container(
                      width: 200,
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
                      ):
                        ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                    child: Image.network(
                      widget.imageURL,
                      width: 150,
                      height: 150,
                      fit: BoxFit.fitHeight,
                    ),
                  )
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

  bool isWithinTolerance(DateTime dateTime1, DateTime dateTime2, Duration tolerance) {
    Duration difference = dateTime1.difference(dateTime2).abs();

    return difference <= tolerance;
  }

  void deleteEvent(context)async{
    CollectionReference creativCollection = FirebaseFirestore.instance.collection('activities');

    await creativCollection.doc(widget.category).update({
      widget.activityName: FieldValue.delete(),
    });

    deleteGroupsFromUser(widget.activityName);

    Navigator.push(context,
      MaterialPageRoute(
          builder: (context) => BottomNavigationBarExample()
      ),
    );
  }

  Future _cropImage(File? imageFile) async {
    if (imageFile != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
          sourcePath: imageFile!.path,
          maxHeight: 400,
          maxWidth: 500,
          aspectRatio: const CropAspectRatio(ratioX: 4.0, ratioY: 3.0),
          aspectRatioPresets:
          [
            //CropAspectRatioPreset.square,
            //CropAspectRatioPreset.ratio3x2,
            //CropAspectRatioPreset.original,
            //CropAspectRatioPreset.ratio16x9
            CropAspectRatioPreset.ratio4x3,
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

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
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
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
      List<Location> locations = await locationFromAddress(_addressController.text);

      if (locations.isNotEmpty) {
        Location first = locations.first;
        setState(() {
          _result = 'Latitude: ${first.latitude}, Longitude: ${first.longitude}';
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

  Future<String?> getCatergoryActivities() async {
    try {
      final activitiesCollectionRef =
      FirebaseFirestore.instance.collection("categoriesActivities");
      final data = await activitiesCollectionRef.doc("category").get();
      if (data.exists) {
        setState(() {
          data.data()!.forEach((key, value) {
            categories = value;
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

  void savePictureToFirestore(context) async {
    try {
      String nameActivity = activityNameController.text;
      User? user = FirebaseAuth.instance.currentUser;

      if (nameActivity.isNotEmpty) {
        if (_photo != null) {
          final path = 'events/${user?.uid}/${basename("${nameActivity}_${basename(_photo!.path)}")}';
          final ref = firebase_storage.FirebaseStorage.instance.ref().child(path);
          var uploadTask = ref.putFile(_photo!);
          final snapshot = await uploadTask!.whenComplete(() {});
          var urlDownload = await snapshot.ref.getDownloadURL();
          await addCreativActivity(urlDownload, context);
        } else {
          await addCreativActivity(widget.imageURL, context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a name activity.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not be saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String> getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    var userID = user?.uid;
    var course = "No Course Available";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userCourse = data["username"];

        if (userCourse != null) {
          course = userCourse;
        }
      }
    }
    return course;
  }

  Future<Map<String, dynamic>> getUser(String eventName, String eventCategory) async {
    List<dynamic> eventList = [];
    Map<String, dynamic> users = {};
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection("activities").doc(eventCategory).get();

    if (snapshot.exists) {
      eventList = snapshot.data()?[eventName] ?? [];
      if (eventList.isNotEmpty) {
        users = eventList[7];
        users.forEach((userName, value) {
          if (value == true) {
            users.addEntries([MapEntry(userName, value)]);
          }
        });
      }
    } else {
      print("Document does not exist");
    }
    return users;
  }

  Set<ByWeekDayEntry> _buildByWeekDays(List<DateTime> dates) {
    Set<ByWeekDayEntry> byWeekDays = {};
    for (DateTime date in dates) {
      for (int i = DateTime.monday; i <= DateTime.sunday; i++) {
        if (date.weekday == i) {
          byWeekDays.add(ByWeekDayEntry(i));
          break;
        }
      }
    }
    return byWeekDays;
  }

  Set<int> _buildByMonths(String? selectedTillMonth) {
    Set<int> byMonths = {};
    Map<String, int> monthIndexMap = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };

    if (selectedTillMonth != null && monthIndexMap.containsKey(selectedTillMonth)) {
      byMonths.add(monthIndexMap[selectedTillMonth]!);
    }
    return byMonths;
  }

  void deleteGroupsFromUser(String groupsToDelete) async {
    if(widget.activityName.toString()==activityNameController.text){
      print("He net austragen");
      return;
    }
    User? user = FirebaseAuth.instance.currentUser;
    var userID = user?.uid;
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(userID);
      List delete = await getGroups(groupsToDelete);
      await userDocRef.update({
        'groups': FieldValue.arrayRemove(delete),
      });
      print('Groups removed successfully from the user.');
    } catch (e) {
      print('Error removing groups: $e');
    }
  }

  Future<List> getGroups(String search) async {
    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    var userID = user?.uid;
    List<dynamic> groups = [];

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userCourse = data["groups"];

        for (var group in userCourse) {
          if(group.toString().split("_")[1].contains(search)){
            groups.add(group);
          }
        }

      }
    }
    return groups;
  }

  Future<void> addCreativActivity(String urlDownload, context) async {
    try {
      if (activityNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a name for the activity.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a description for the activity.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select start date for the activity.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category for the activity.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      await _convertAddressToCoordinates();

      if (_result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter an address for the activity.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (urlDownload == null || urlDownload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Image URL is null or empty.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if(showAdditionalFields ){
        if(selectedTillMonth == null || selectedInterval == null|| selectedFrequency== null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please fill out all repeat information (interval, till and repeat) or press not repeat'),
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      CollectionReference creativCollection = FirebaseFirestore.instance.collection('activities');

      String newActivity = widget.activityName;
      _user = FirebaseAuth.instance.currentUser;

      final firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;

      var userData = await firestore.collection('users').doc(user?.uid).get();
      var myUserName = await userData["username"];

      if (newActivity != null && _user != null) {
        if(newActivity != activityNameController.text) {
          await HelperFunctions.getUserNameSharedPreference().then((val) {
            DatabaseService(uid: _user!.uid).createGroup(
                myUserName!, activityNameController.text, selectedCategory!);
          });
        }
      } else {
        print("Error: _groupName or _user is null");
      }

      Map<String, dynamic> users = {};
      users.addEntries([MapEntry(await getUsername(), true)]);
      users.addAll(await getUser(widget.activityName,widget.category));

      Frequency frequency = Frequency.weekly;
      switch (selectedFrequency) {
        case 'Daily':
          frequency = Frequency.daily;
          break;
        case 'Weekly':
          frequency = Frequency.weekly;
          break;
        case 'Monthly':
          frequency = Frequency.monthly;
          break;
        case 'Yearly':
          frequency = Frequency.yearly;
          break;
      }

      List<DateTime> dates = [];
      dates.add(startDate!);

      Map<String, dynamic> events = {};
      if(showSecondDate){
        dates.add(secondStartDate!);
        dates.add(thirdStartDate != null ? thirdStartDate! : secondStartDate!);
        events['1'] = Timestamp.fromDate(secondStartDate!);
        events['2'] = Timestamp.fromDate(thirdStartDate != null ? thirdStartDate! : secondStartDate!);
      }
      else{
        events['noMoreDates'] = "noMore";
      }

      var rrule;
      if(selectedInterval != null && startDate != null && selectedTillMonth != null){
        rrule = RecurrenceRule(
          frequency: frequency,
          interval: selectedInterval!,
          byWeekDays: _buildByWeekDays(dates!),
          byMonths: _buildByMonths(selectedTillMonth),
        );
      }

      var addRRule = rrule != null ? rrule.toString() : "No Regular Event";

      try {
        final Map<String, dynamic> activityData = {
          newActivity != activityNameController.text ? activityNameController.text : newActivity: [
            activityNameController.text,
            descriptionController.text,
            Timestamp.fromDate(startDate!),
            events,
            GeoPoint(
              double.parse(extractNumbers(_result.split(',')[0].trim())),
              double.parse(extractNumbers(_result.split(',')[1].trim())),
            ),
            urlDownload,
            selectedCategory,
            users,
            addRRule,
          ],
        };

        final Map<String, dynamic> activityDataWithourRules = {
          newActivity != activityNameController.text ? activityNameController.text : newActivity: [
            activityNameController.text,
            descriptionController.text,
            Timestamp.fromDate(startDate!),
            events,
            GeoPoint(
              double.parse(extractNumbers(_result.split(',')[0].trim())),
              double.parse(extractNumbers(_result.split(',')[1].trim())),
            ),
            urlDownload,
            selectedCategory,
            users,
          ],
        };

        if (addRRule != "No Regular Event" && showAdditionalFields) {
          if(widget.activityName != activityNameController){
            await creativCollection.doc(widget.category).update({
              widget.activityName: FieldValue.delete(),
            });
            deleteGroupsFromUser(widget.activityName);
          }
          await creativCollection.doc(selectedCategory).update(activityData);
        } else {
          if(widget.activityName != activityNameController){
            await creativCollection.doc(widget.category).update({
              widget.activityName: FieldValue.delete(),
            });
            deleteGroupsFromUser(widget.activityName);
          }
          await creativCollection.doc(selectedCategory).update(activityDataWithourRules);
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Event(
              eventName: activityNameController.text,
              eventCategory: selectedCategory.toString(),
            ),
          ),
        );
        if (mounted) {
          setState(() {
            activityNameController.clear();
            descriptionController.clear();
            _addressController.clear();
            startDate = null;
            secondStartDate = null;
            selectedCategory = null;
            _photo = null;
          });
        }
      } catch (e) {
        print('Error updating Firestore in addCreativActivity: $e');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a second start date or press no additional date'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  }
}