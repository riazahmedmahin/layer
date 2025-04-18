import 'package:flutter/material.dart';
import 'package:layer/app.dart';
import 'package:layer/core/theme/app_theme.dart';
import 'package:layer/presentation/screens/auth/LogInScreen.dart';
import 'package:layer/presentation/screens/auth/OtpVerification.dart';
import 'package:layer/presentation/screens/auth/registationScreen.dart';
import 'package:layer/presentation/screens/balance%20&%20payment/buyingschhet.dart';
import 'package:layer/presentation/screens/balance%20&%20payment/payment.dart';
import 'package:layer/presentation/screens/home/homescreen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

// Initialize the notification plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize timezone data
  tz_data.initializeTimeZones();
  //final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  //tz.setLocalLocation(tz.getLocation(timeZoneName));
  
  // Initialize timezone data for scheduled notifications
  // tz_data.initializeTimeZones();
  
  // // Initialize notifications
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('@mipmap/ic_launcher');
  
  // const InitializationSettings initializationSettings = InitializationSettings(
  //   android: initializationSettingsAndroid,
  // );
  
  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
  //     // Handle notification tap
  //   },
  // );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LawyerProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const LayerAdvisor(),
    ),
  );
}


// Main app container with all features
class LegalAdvisorApp extends StatefulWidget {
  const LegalAdvisorApp({Key? key}) : super(key: key);

  @override
  _LegalAdvisorAppState createState() => _LegalAdvisorAppState();
}

class _LegalAdvisorAppState extends State<LegalAdvisorApp> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Check for upcoming appointments and schedule notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      //notificationProvider.checkAndScheduleAppointmentNotifications(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          LawyerListSection(),
          AppointmentSection(),
          ChatSection(),
          ProfileSection(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 20,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Lawyers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            },
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          // Quick search or filter action
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => BuyingSheet(),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.paypal_rounded,color: Colors.white),
      ) : null,
    );
  }
}




// Lawyer Detail Screen
class LawyerDetailScreen extends StatefulWidget {
  final Lawyer lawyer;

  const LawyerDetailScreen({Key? key, required this.lawyer}) : super(key: key);

  @override
  _LawyerDetailScreenState createState() => _LawyerDetailScreenState();
}

class _LawyerDetailScreenState extends State<LawyerDetailScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';
  String _selectedConsultationType = 'video';
  String _issue = '';
  bool _isBooking = false;
  late TabController _tabController;

  final List<String> _availableTimes = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isBooking = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final lawyerProvider = Provider.of<LawyerProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not found');
      }

      // Parse time string to create a DateTime
      final timeParts = _selectedTime.split(':');
      final hourPart = timeParts[0];
      final minutePart = "00"; // Assuming all times are on the hour
      final isPM = _selectedTime.contains('PM');
      final hour = int.parse(hourPart);
      final adjustedHour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
      
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        adjustedHour,
        int.parse(minutePart),
      );

      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lawyerId: widget.lawyer.id,
        userId: user.id,
        lawyerName: widget.lawyer.name,
        userEmail: user.email,
        dateTime: appointmentDateTime,
        status: 'confirmed',
        consultationType: _selectedConsultationType,
        issue: _issue,
      );

      final success = await lawyerProvider.bookAppointment(appointment);

      if (success && mounted) {
        // Schedule notification for 5 minutes before appointment
       // notificationProvider.scheduleAppointmentNotification(appointment);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Appointment Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your appointment with ${widget.lawyer.name} has been confirmed.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                ),
                Text(
                  'Time: $_selectedTime',
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will receive a notification 5 minutes before your appointment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isBooking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  innerBoxIsScrolled ? widget.lawyer.name : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'lawyer-avatar-${widget.lawyer.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.lawyer.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lawyer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.lawyer.specialization,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.message_rounded,color: Colors.white,),
                  onPressed: () {
                    // Navigate to chat with this lawyer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(lawyer: widget.lawyer),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share,color: Colors.white,),
                  onPressed: () {
                    // Share lawyer profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing lawyer profile...'),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'Book'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // About tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and experience
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.lawyer.rating} (${widget.lawyer.reviewCount} reviews)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.lawyer.experience,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About section
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lawyer.about,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Languages section
                  const Text(
                    'Languages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.lawyer.languages.map((language) {
                      return Chip(
                        label: Text(language),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Availability section
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.lawyer.availableDays.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Consultation fee
                  const Text(
                    'Consultation Fee',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hourly Rate',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${widget.lawyer.consultationFee.toStringAsFixed(0)}/hour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Book appointment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _tabController.animateTo(2);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'BOOK APPOINTMENT',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Reviews tab
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 5, // Mock reviews
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                'https://randomuser.me/api/portraits/${index % 2 == 0 ? 'women' : 'men'}/${index + 10}.jpg',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ['Emma Wilson', 'James Smith', 'Olivia Johnson', 'Noah Williams', 'Sophia Brown'][index],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(
                                      DateTime.now().subtract(Duration(days: (index + 1) * 7)),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RatingBarIndicator(
                              rating: [4.5, 5.0, 4.0, 4.5, 5.0][index],
                              itemBuilder: (context, index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          [
                            'Excellent lawyer! Very knowledgeable and professional. Helped me resolve my case quickly.',
                            'I highly recommend this lawyer. They were responsive and provided great advice for my situation.',
                            'Good experience overall. The consultation was helpful and informative.',
                            'Very satisfied with the service. The lawyer was attentive and understood my needs.',
                            'Outstanding service! The lawyer was thorough and explained everything clearly. Will definitely use again if needed.',
                          ][index],
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Book appointment tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book an Appointment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date picker
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                        Text(
          DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
                            
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time selection
                    const Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableTimes.length,
                        itemBuilder: (context, index) {
                          final time = _availableTimes[index];
                          final isSelected = time == _selectedTime;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(time),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                }
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Consultation type
                    const Text(
                      'Consultation Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.videocam,
                                  color: _selectedConsultationType == 'video'
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text('Video'),
                              ],
                            ),
                            value: 'video',
                            groupValue: _selectedConsultationType,
                            onChanged: (value) {
                              setState(() {
                                _selectedConsultationType = value!;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: _selectedConsultationType == 'audio'
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                const Text('Audio'),
                              ],
                            ),
                            value: 'audio',
                            groupValue: _selectedConsultationType,
                            onChanged: (value) {
                              setState(() {
                                _selectedConsultationType = value!;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Issue description
                    const Text(
                      'Describe your legal issue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Briefly describe your legal issue...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe your issue';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _issue = value!;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: _isBooking
                          ? Center(
                              child: SpinKitFadingCircle(
                                color: Theme.of(context).primaryColor,
                                size: 50.0,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _bookAppointment,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'CONFIRM BOOKING',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Terms and conditions
                    Center(
                      child: Text(
                        'By booking, you agree to our Terms & Conditions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SliverAppBarDelegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// Appointment Section
class AppointmentSection extends StatefulWidget {
  const AppointmentSection({Key? key}) : super(key: key);

  @override
  _AppointmentSectionState createState() => _AppointmentSectionState();
}

class _AppointmentSectionState extends State<AppointmentSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final lawyerProvider = Provider.of<LawyerProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login to view appointments'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('My Appointments',),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: FutureBuilder<List<Appointment>>(
        future: lawyerProvider.getUserAppointments(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 50.0,
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final appointments = snapshot.data ?? [];
          
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No appointments found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book a consultation with a lawyer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to lawyer list
                      final pageController = PageController();
                      pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find a Lawyer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final upcomingAppointments = appointments.where(
            (appointment) => appointment.status == 'pending' || appointment.status == 'confirmed'
          ).toList();
          
          final completedAppointments = appointments.where(
            (appointment) => appointment.status == 'completed'
          ).toList();
          
          final cancelledAppointments = appointments.where(
            (appointment) => appointment.status == 'cancelled'
          ).toList();
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming appointments
              _buildAppointmentList(
                upcomingAppointments,
                lawyerProvider,
                canCancel: true,
              ),
              
              // Completed appointments
              _buildAppointmentList(
                completedAppointments,
                lawyerProvider,
                canCancel: false,
              ),
              
              // Cancelled appointments
              _buildAppointmentList(
                cancelledAppointments,
                lawyerProvider,
                canCancel: false,
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildAppointmentList(
    List<Appointment> appointments,
    LawyerProvider lawyerProvider, {
    required bool canCancel,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments in this category',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final lawyer = lawyerProvider.lawyers.firstWhere(
          (lawyer) => lawyer.id == appointment.lawyerId,
          orElse: () => Lawyer(
            id: '',
            name: 'Unknown',
            photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
            specialization: '',
            rating: 0,
            reviewCount: 0,
            experience: '',
            about: '',
            consultationFee: 0,
            languages: [],
            availableDays: [],
          ),
        );
        
        // Calculate if appointment is today
        final isToday = appointment.dateTime.year == DateTime.now().year &&
                        appointment.dateTime.month == DateTime.now().month &&
                        appointment.dateTime.day == DateTime.now().day;
        
        // Calculate time remaining until appointment
        final timeUntil = appointment.dateTime.difference(DateTime.now());
        final isUpcoming = timeUntil.isNegative == false;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (isToday && isUpcoming)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'TODAY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: CachedNetworkImageProvider(lawyer.photoUrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lawyer.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lawyer.specialization,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(appointment.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('EEEE, MMM dd, yyyy').format(appointment.dateTime)),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.access_time, 'Time', DateFormat('h:mm a').format(appointment.dateTime)),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            appointment.consultationType == 'video' ? Icons.videocam : Icons.phone,
                            'Type',
                            appointment.consultationType.capitalize(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Issue:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.issue,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    if (canCancel) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (appointment.status == 'confirmed' && isToday) ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                // Join call logic would go here
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoCallScreen(appointment: appointment, lawyer: lawyer),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.video_call),
                              label: const Text('Join Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          OutlinedButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Cancel Appointment'),
                                  content: const Text('Are you sure you want to cancel this appointment?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true) {
                                final success = await lawyerProvider.cancelAppointment(appointment.id);
                                
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Appointment cancelled successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  setState(() {});
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to cancel appointment'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'confirmed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.capitalize(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Video Call Screen
class VideoCallScreen extends StatefulWidget {
  final Appointment appointment;
  final Lawyer lawyer;

  const VideoCallScreen({
    Key? key,
    required this.appointment,
    required this.lawyer,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video (lawyer)
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: CachedNetworkImageProvider(widget.lawyer.photoUrl),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.lawyer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connecting...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Self view
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Call controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCallButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.white,
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                      },
                      label: _isMuted ? 'Unmute' : 'Mute',
                    ),
                    const SizedBox(width: 16),
                    _buildCallButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: _isCameraOff ? Colors.red : Colors.white,
                      onPressed: () {
                        setState(() {
                          _isCameraOff = !_isCameraOff;
                        });
                      },
                      label: _isCameraOff ? 'Camera On' : 'Camera Off',
                    ),
                    const SizedBox(width: 16),
                    _buildCallButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeakerOn ? Colors.white : Colors.grey,
                      onPressed: () {
                        setState(() {
                          _isSpeakerOn = !_isSpeakerOn;
                        });
                      },
                      label: _isSpeakerOn ? 'Speaker' : 'Speaker Off',
                    ),
                    const SizedBox(width: 16),
                    _buildCallButton(
                      icon: Icons.call_end_outlined,
                      color: Colors.white,
                      backgroundColor: Colors.red,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      label: 'End',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            iconSize: 30,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Chat Section
class ChatSection extends StatefulWidget {
  const ChatSection({Key? key}) : super(key: key);

  @override
  _ChatSectionState createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final lawyerProvider = Provider.of<LawyerProvider>(context);
    final user = authProvider.currentUser;
    final lawyers = lawyerProvider.lawyers;

    if (user == null) {
      return const Center(child: Text('Please login to view messages'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: lawyers.length,
        itemBuilder: (context, index) {
          final lawyer = lawyers[index];
          
          // Mock last message
          final lastMessage = index % 3 == 0
              ? 'Thank you for your message. I\'ll review this and get back to you shortly.'
              : index % 3 == 1
                  ? 'Yes, I can help you with that legal matter.'
                  : 'When would be a good time to schedule a consultation?';
          
          // Mock time
          final messageTime = DateTime.now().subtract(Duration(minutes: index * 30));
          
          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(lawyer.photoUrl),
                ),
                if (index % 2 == 0)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              lawyer.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                if (index % 3 == 0)
                  const Icon(
                    Icons.done_all,
                    size: 16,
                    color: Colors.blue,
                  ),
                Expanded(
                  child: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm a').format(messageTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                if (index % 4 == 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(lawyer: lawyer),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Chat Detail Screen
class ChatDetailScreen extends StatefulWidget {
  final Lawyer lawyer;

  const ChatDetailScreen({
    Key? key,
    required this.lawyer,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Mock data for chats
  late List<ChatMessage> _messages;
  bool _isRecording = false;
  bool _isAttaching = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize mock messages
    _messages = [
      ChatMessage(
        senderId: 'lawyer',
        text: 'Hello! How can I help you with your legal matter today?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      ChatMessage(
        senderId: 'user',
        text: 'Hi, I need advice on a contract I received.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ),
      ChatMessage(
        senderId: 'lawyer',
        text: 'I\'d be happy to help. Could you provide more details about the contract?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        senderId: 'user',
        text: 'It\'s an employment contract. I\'m concerned about the non-compete clause.',
        timestamp: DateTime.now().subtract(const Duration(hours: 23)),
      ),
      ChatMessage(
        senderId: 'lawyer',
        text: 'Non-compete clauses can be tricky. Could you share the specific language you\'re concerned about?',
        timestamp: DateTime.now().subtract(const Duration(hours: 22)),
      ),
    ];
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(
        ChatMessage(
          senderId: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      
      // Simulate lawyer response after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                senderId: 'lawyer',
                text: 'Thank you for your message. I\'ll review this and get back to you shortly.',
                timestamp: DateTime.now(),
              ),
            );
          });
          _scrollToBottom();
        }
      });
    });
    
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.lawyer.photoUrl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lawyer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[100],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Video call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Audio call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                image: DecorationImage(
                  image: const AssetImage('assets/chat_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.1),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.senderId == 'user';
                  
                  // Check if we need to show date header
                  bool showDateHeader = false;
                  if (index == 0) {
                    showDateHeader = true;
                  } else {
                    final prevMessage = _messages[index - 1];
                    final prevDate = DateTime(
                      prevMessage.timestamp.year,
                      prevMessage.timestamp.month,
                      prevMessage.timestamp.day,
                    );
                    final currentDate = DateTime(
                      message.timestamp.year,
                      message.timestamp.month,
                      message.timestamp.day,
                    );
                    
                    if (prevDate != currentDate) {
                      showDateHeader = true;
                    }
                  }
                  
                  return Column(
                    children: [
                      if (showDateHeader)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _formatDateHeader(message.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: ChatBubble(
                            clipper: isUser
                                ? ChatBubbleClipper5(type: BubbleType.sendBubble)
                                : ChatBubbleClipper5(type: BubbleType.receiverBubble),
                            alignment: isUser ? Alignment.topRight : Alignment.topLeft,
                            margin: const EdgeInsets.only(top: 8),
                            backGroundColor: isUser
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('h:mm a').format(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isUser ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ),
                                      if (isUser) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.done_all,
                                          size: 14,
                                          color: index == _messages.length - 1 ? Colors.white70 : Colors.blue[100],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Attachment options
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isAttaching ? 160 : 0,
            color: Colors.grey[200],
            child: _isAttaching
                ? GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAttachmentOption(Icons.photo, 'Photos', Colors.purple),
                      _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.red),
                      _buildAttachmentOption(Icons.insert_drive_file, 'Document', Colors.blue),
                      _buildAttachmentOption(Icons.location_on, 'Location', Colors.green),
                      _buildAttachmentOption(Icons.person, 'Contact', Colors.orange),
                      _buildAttachmentOption(Icons.music_note, 'Audio', Colors.pink),
                      _buildAttachmentOption(Icons.payment, 'Payment', Colors.teal),
                      _buildAttachmentOption(Icons.poll, 'Poll', Colors.amber),
                    ],
                  )
                : null,
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isAttaching ? Icons.close : Icons.attach_file,
                    color: _isAttaching ? Colors.red : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isAttaching = !_isAttaching;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: Colors.grey[600],
                        onPressed: () {
                          // Camera functionality
                        },
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPress: () {
                    // Start voice recording
                    setState(() {
                      _isRecording = true;
                    });
                  },
                  onLongPressEnd: (_) {
                    // End voice recording
                    setState(() {
                      _isRecording = false;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice message sent'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _messageController.text.isEmpty
                          ? _isRecording ? Icons.mic_none : Icons.mic
                          : Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _formatDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(timestamp);
    }
  }
}

// Profile Section
class ProfileSection extends StatefulWidget {
  const ProfileSection({Key? key}) : super(key: key);

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _darkMode = false;
  bool _notifications = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phoneNumber;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateProfile(
        _nameController.text,
        _phoneController.text,
      );
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login to view your profile'));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit,color: Colors.white,),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Profile form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isEditing = false;
                                          // Reset form
                                          _nameController.text = user.name;
                                          _phoneController.text = user.phoneNumber;
                                        });
                                      },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Changes'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Settings section
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dark mode
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
                    secondary: const Icon(Icons.dark_mode),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() {
                        _darkMode = value;
                      });
                    },
                  ),
                  
                  // Notifications
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable push notifications'),
                    secondary: const Icon(Icons.notifications),
                    value: _notifications,
                    onChanged: (value) {
                      setState(() {
                        _notifications = value;
                      });
                    },
                  ),
                  
                  // Sound
                  SwitchListTile(
                    title: const Text('Sound'),
                    subtitle: const Text('Enable sound for notifications'),
                    secondary: const Icon(Icons.volume_up),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Other settings
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Privacy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to privacy settings
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to help & support
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to about
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>LogInScreen())),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          await authProvider.logout();
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Models
class User {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.phoneNumber,
  });
}

class Lawyer {
  final String id;
  final String name;
  final String photoUrl;
  final String specialization;
  final double rating;
  final int reviewCount;
  final String experience;
  final String about;
  final double consultationFee;
  final List<String> languages;
  final List<String> availableDays;

  Lawyer({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialization,
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.about,
    required this.consultationFee,
    required this.languages,
    required this.availableDays,
  });
}

class Appointment {
  final String id;
  final String lawyerId;
  final String userId;
  final String lawyerName;
  final String userEmail;
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String consultationType; // 'video', 'audio', 'in-person'
  final String issue;

  Appointment({
    required this.id,
    required this.lawyerId,
    required this.userId,
    required this.lawyerName,
    required this.userEmail,
    required this.dateTime,
    required this.status,
    required this.consultationType,
    required this.issue,
  });
}

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  
  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });
}

// Providers
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String phoneNumber, String password) async {
    // In a real app, this would make an API call to authenticate
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful login
      if (phoneNumber.contains('+1') && password == 'password') {
        _currentUser = User(
          id: '1',
          name: 'John Doe',
          email: 'john.doe@example.com',
          photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
          phoneNumber: phoneNumber,
        );
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // In a real app, this would clear tokens, etc.
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> register(String name, String phoneNumber, String password) async {
    // In a real app, this would make an API call to register
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful registration
      _currentUser = User(
        id: '1',
        name: name,
        email: '$name.user@example.com',
        photoUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        phoneNumber: phoneNumber,
      );
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> updateProfile(String name, String phoneNumber) async {
    // In a real app, this would make an API call to update profile
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: name,
        email: _currentUser!.email,
        photoUrl: _currentUser!.photoUrl,
        phoneNumber: phoneNumber,
      );
      notifyListeners();
    }
  }
}

class LawyerProvider with ChangeNotifier {
  List<Lawyer> _lawyers = [];
  List<Appointment> _appointments = [];
  
  List<Lawyer> get lawyers => _lawyers;
  List<Appointment> get appointments => _appointments;

  LawyerProvider() {
    _loadLawyers();
  }

  Future<void> _loadLawyers() async {
    // In a real app, this would fetch from an API
    await Future.delayed(const Duration(seconds: 1));
    
    _lawyers = [
      Lawyer(
        id: '1',
        name: 'Sarah Johnson',
        photoUrl: 'https://plus.unsplash.com/premium_photo-1690407617686-d449aa2aad3c?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fHByb2ZpbGUlMjBwaWN0dXJlfGVufDB8fDB8fHww',
        specialization: 'Family Law',
        rating: 4.8,
        reviewCount: 124,
        experience: '15 years',
        about: 'Specializing in divorce, child custody, and family matters with compassion and expertise. I have handled hundreds of cases and have a strong track record of successful outcomes for my clients.',
        consultationFee: 150.0,
        languages: ['English', 'Spanish'],
        availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Friday'],
      ),
      Lawyer(
        id: '2',
        name: 'Michael Chen',
        photoUrl: 'https://plus.unsplash.com/premium_photo-1689977807477-a579eda91fa2?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NDl8fHByb2ZpbGUlMjBwaWN0dXJlfGVufDB8fDB8fHww',
        specialization: 'Corporate Law',
        rating: 4.9,
        reviewCount: 89,
        experience: '12 years',
        about: 'Expert in business formation, contracts, and corporate compliance matters. I help businesses of all sizes navigate complex legal challenges and achieve their goals while minimizing legal risks.',
        consultationFee: 200.0,
        languages: ['English', 'Mandarin'],
        availableDays: ['Monday', 'Wednesday', 'Thursday', 'Friday'],
      ),
      Lawyer(
        id: '3',
        name: 'Jessica Rodriguez',
        photoUrl: 'https://plus.unsplash.com/premium_photo-1688350839154-1a131bccd78a?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NzN8fHByb2ZpbGUlMjBwaWN0dXJlfGVufDB8fDB8fHww',
        specialization: 'Criminal Defense',
        rating: 4.7,
        reviewCount: 156,
        experience: '10 years',
        about: 'Dedicated criminal defense attorney with experience in both state and federal courts. I am committed to protecting your rights and providing aggressive representation for all criminal matters.',
        consultationFee: 175.0,
        languages: ['English', 'Spanish'],
        availableDays: ['Tuesday', 'Wednesday', 'Thursday', 'Saturday'],
      ),
      Lawyer(
        id: '4',
        name: 'David Wilson',
        photoUrl: 'https://plus.unsplash.com/premium_photo-1661374927471-24a90ebd5737?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTI1fHxwcm9maWxlJTIwcGljdHVyZXxlbnwwfHwwfHx8MA%3D%3D',
        specialization: 'Real Estate Law',
        rating: 4.6,
        reviewCount: 78,
        experience: '8 years',
        about: 'Helping clients navigate property transactions, landlord-tenant issues, and real estate disputes. I provide comprehensive legal services for buyers, sellers, landlords, and tenants.',
        consultationFee: 160.0,
        languages: ['English'],
        availableDays: ['Monday', 'Tuesday', 'Thursday', 'Friday'],
      ),
      Lawyer(
        id: '5',
        name: 'Amanda Patel',
        photoUrl: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Njd8fHByb2ZpbGUlMjBwaWN0dXJlfGVufDB8fDB8fHww',
        specialization: 'Immigration Law',
        rating: 4.9,
        reviewCount: 112,
        experience: '9 years',
        about: 'Passionate about helping clients navigate the complex immigration system with confidence. I assist with visas, green cards, citizenship applications, and deportation defense.',
        consultationFee: 165.0,
        languages: ['English', 'Hindi', 'Gujarati'],
        availableDays: ['Monday', 'Wednesday', 'Friday', 'Saturday'],
      ),
    ];
    
    notifyListeners();
  }

  Future<List<Lawyer>> searchLawyers(String query) async {
    // In a real app, this would search from an API
    if (query.isEmpty) return _lawyers;
    
    return _lawyers.where((lawyer) => 
      lawyer.name.toLowerCase().contains(query.toLowerCase()) ||
      lawyer.specialization.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<bool> bookAppointment(Appointment appointment) async {
    // In a real app, this would make an API call
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _appointments.add(appointment);
      notifyListeners();
      return true;
    } catch (e) {
      print('Booking error: $e');
      return false;
    }
  }

  Future<List<Appointment>> getUserAppointments(String userId) async {
    // In a real app, this would fetch from an API
    return _appointments.where((appointment) => appointment.userId == userId).toList();
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    // In a real app, this would make an API call
    try {
      final index = _appointments.indexWhere((appointment) => appointment.id == appointmentId);
      if (index != -1) {
        final appointment = _appointments[index];
        final updatedAppointment = Appointment(
          id: appointment.id,
          lawyerId: appointment.lawyerId,
          userId: appointment.userId,
          lawyerName: appointment.lawyerName,
          userEmail: appointment.userEmail,
          dateTime: appointment.dateTime,
          status: 'cancelled',
          consultationType: appointment.consultationType,
          issue: appointment.issue,
        );
        
        _appointments[index] = updatedAppointment;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Cancellation error: $e');
      return false;
    }
  }
}

// Notification Provider
class NotificationProvider with ChangeNotifier {
  void scheduleInAppReminder(BuildContext context, Appointment appointment) {
    final scheduledTime = appointment.dateTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();
    final durationUntilReminder = scheduledTime.difference(now);

    // Check if the duration is positive
    if (durationUntilReminder.inSeconds > 0) {
      Timer(durationUntilReminder, () {
        _showReminderDialog(context, appointment);
      });

      print('In-app reminder scheduled for: $scheduledTime');
    }
  }

  void _showReminderDialog(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upcoming Appointment'),
        content: Text('You have an appointment with ${appointment.lawyerName} in 5 minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
  
  Future<void> checkAndScheduleAppointmentNotifications(BuildContext context) async {
    final lawyerProvider = Provider.of<LawyerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      final appointments = await lawyerProvider.getUserAppointments(user.id);
      
      for (final appointment in appointments) {
        if (appointment.status == 'confirmed') {
        }
      }
    }
  }
//}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}