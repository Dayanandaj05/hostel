import 'package:hostel_app/features/auth/domain/entities/user_model.dart';
import 'package:hostel_app/features/complaints/domain/entities/complaint_model.dart';
import 'package:hostel_app/features/dayentry/domain/entities/day_entry_model.dart';
import 'package:hostel_app/features/leave/domain/entities/leave_request_model.dart';
import 'package:hostel_app/features/tokens/domain/entities/food_token_model.dart';
import 'package:hostel_app/features/tshirt/domain/entities/tshirt_order_model.dart';

class MockData {
  static final List<UserModel> users = [
    UserModel(
      uid: 'student-1',
      name: 'Arun Kumar',
      email: '25mx308@psgtech.ac.in',
      role: UserRole.student,
      roomId: 'A-402',
      createdAt: DateTime(2025, 6, 1),
    ),
    UserModel(
      uid: 'warden-1',
      name: 'Warden Selvam',
      email: 'warden@psgtech.ac.in',
      role: UserRole.warden,
      roomId: null,
      createdAt: DateTime(2025, 6, 1),
    ),
    UserModel(
      uid: 'admin-1',
      name: 'Admin Office',
      email: 'admin@psgtech.ac.in',
      role: UserRole.admin,
      roomId: null,
      createdAt: DateTime(2025, 6, 1),
    ),
  ];

  static final Map<String, String> passwords = {
    '25mx308@psgtech.ac.in': '123456',
    'warden@psgtech.ac.in': '123456',
    'admin@psgtech.ac.in': '123456',
  };

  static final Map<String, Map<String, dynamic>> studentProfiles = {
    'student-1': {
      'name': 'Arun Kumar',
      'rollNumber': '25MX308',
      'email': '25mx308@psgtech.ac.in',
      'programme': 'MCA',
      'yearOfStudy': '1',
      'hostelName': 'PSG Men Hostel',
      'blockName': 'A Block',
      'roomNumber': '402',
      'roomType': 'Double',
      'floor': '4',
      'joiningDate': '2025-06-10',
      'roomId': 'A-402',
      'messName': 'Main Mess',
      'messType': 'South Indian',
      'messSupervisors': ['Mr. Rajan', 'Ms. Priya'],
      'balance': 1200,
      'contactPhone': '+91 9876543210',
      'fatherName': 'Kumaravel',
      'address': 'Coimbatore',
      'primaryMobile': '+91 9876543210',
      'secondaryMobile': '+91 9123456780',
      'bloodGroup': 'O+',
    },
  };

  static final List<Map<String, dynamic>> students = [
    {'name': 'Arun Kumar', 'roomId': 'A-402', 'status': 'active'},
    {'name': 'Naveen Raj', 'roomId': 'B-112', 'status': 'active'},
    {'name': 'Pradeep S', 'roomId': 'C-301', 'status': 'leave'},
  ];

  static final Map<String, List<Map<String, dynamic>>> messMenuBySlot = {
    'Breakfast': [
      {
        'itemName': 'Idli',
        'price': 25.0,
        'maxQty': 4,
        'availableFrom': '07:00',
        'availableTo': '09:30',
        'durationMinutes': 150,
        'bookingCutoffTime': '09:00',
      },
      {
        'itemName': 'Dosa',
        'price': 35.0,
        'maxQty': 3,
        'availableFrom': '07:30',
        'availableTo': '10:00',
        'durationMinutes': 150,
        'bookingCutoffTime': '09:15',
      },
      {
        'itemName': 'Pongal',
        'price': 30.0,
        'maxQty': 2,
        'availableFrom': '07:00',
        'availableTo': '09:00',
        'durationMinutes': 120,
        'bookingCutoffTime': '08:45',
      },
    ],
    'Lunch': [
      {
        'itemName': 'Meals',
        'price': 70.0,
        'maxQty': 2,
        'availableFrom': '12:00',
        'availableTo': '14:30',
        'durationMinutes': 150,
        'bookingCutoffTime': '13:30',
      },
      {
        'itemName': 'Variety Rice',
        'price': 55.0,
        'maxQty': 3,
        'availableFrom': '12:00',
        'availableTo': '14:00',
        'durationMinutes': 120,
        'bookingCutoffTime': '13:15',
      },
    ],
    'Dinner': [
      {
        'itemName': 'Chapathi',
        'price': 40.0,
        'maxQty': 4,
        'availableFrom': '19:00',
        'availableTo': '21:30',
        'durationMinutes': 150,
        'bookingCutoffTime': '20:45',
      },
      {
        'itemName': 'Parotta',
        'price': 45.0,
        'maxQty': 3,
        'availableFrom': '19:30',
        'availableTo': '22:00',
        'durationMinutes': 150,
        'bookingCutoffTime': '21:00',
      },
    ],
  };

  static final List<Map<String, dynamic>> notices = [
    {
      'id': 'notice-1',
      'title': 'Hostel Day Registration Open',
      'body': 'Register your family visitors before Friday.',
      'createdBy': 'admin-1',
      'isActive': true,
      'audienceRoles': ['student', 'warden', 'admin'],
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'updatedAt': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  static final List<LeaveRequestModel> leaveRequests = [];
  static final List<FoodTokenModel> foodTokens = [];
  static final List<ComplaintModel> complaints = [];
  static final List<DayEntryModel> dayEntries = [];
  static final List<TShirtOrderModel> tshirtOrders = [];

  static final List<Map<String, dynamic>> messApplications = [];

  static Map<String, dynamic> hostelDaySettings = {
    'eventName': 'PSG Hostel Day',
    'venue': 'Main Ground',
    'notes': 'Please carry ID cards.',
    'eventDate': DateTime.now().add(const Duration(days: 10)),
    'registrationOpen': true,
    'maxVisitorsPerStudent': 2,
    'updatedAt': DateTime.now(),
  };
}
