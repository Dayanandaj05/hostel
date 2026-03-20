abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const unauthorized = '/unauthorized';

  static const studentHome = '/student';
  static const studentRoom = '/student/room';
  static const studentLeave = '/student/leave';
  static const studentComplaints = '/student/complaints';
  static const studentTokens = '/student/tokens';
  static const studentMyTokens  = '/student/tokens/my';
  static const studentTShirt = '/student/tshirt';
  static const studentMyTShirts = '/student/tshirt/my';
  static const studentDayEntry = '/student/dayentry';
  static const studentNotices = '/student/notices';
  static const studentProfile = '/student/profile';
  static const studentMess = '/student/mess';
  static const studentFees = '/student/fees';
  static const studentContact = '/student/contact';

  static const wardenHome = '/warden';
  static const wardenLeaveRequests = '/warden/leave-requests';
  static const wardenComplaints = '/warden/complaints';
  static const wardenNotices = '/warden/notices';

  static const adminHome = '/admin';
  static const adminUsers = '/admin/users';
  static const adminRoles = '/admin/roles';
  static const adminRooms = '/admin/rooms';
  static const adminNotices = '/admin/notices';
  static const adminDashboard = '/admin/dashboard';
}
