import 'package:flutter/material.dart';

class NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  bool isRead;

  NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _customerNotifications = [
    NotificationItem(icon: Icons.local_offer_rounded, title: 'New Promotion Available', subtitle: '20% off at Iron Core Gym this weekend!', time: '2h ago'),
    NotificationItem(icon: Icons.event_rounded, title: 'Upcoming Event', subtitle: 'HIIT Challenge starts tomorrow at 6 AM', time: '5h ago'),
    NotificationItem(icon: Icons.star_rounded, title: 'Rate Your Visit', subtitle: 'How was your experience at Dstar Gym?', time: '1d ago', isRead: true),
    NotificationItem(icon: Icons.card_membership_rounded, title: 'Membership Reminder', subtitle: 'Your monthly plan expires in 5 days.', time: '2d ago', isRead: true),
    NotificationItem(icon: Icons.fitness_center_rounded, title: 'New Gym Nearby', subtitle: 'A new gym just opened near your location!', time: '3d ago', isRead: true),
  ];

  final List<NotificationItem> _ownerNotifications = [
    NotificationItem(icon: Icons.star_rounded, title: 'New Review', subtitle: '5 stars from John D.', time: '3h ago'),
    NotificationItem(icon: Icons.person_add_rounded, title: 'New Follower', subtitle: 'Sarah M. started following you', time: '5h ago'),
    NotificationItem(icon: Icons.event_available_rounded, title: 'Event Registration', subtitle: '12 new registrations for HIIT Challenge', time: '1d ago', isRead: true),
    NotificationItem(icon: Icons.local_offer_rounded, title: 'Promotion Redemption', subtitle: '8 members redeemed 20% Off promo', time: '1d ago', isRead: true),
  ];

  List<NotificationItem> get customerNotifications => _customerNotifications;
  List<NotificationItem> get ownerNotifications => _ownerNotifications;

  void markAllCustomerRead() {
    for (var n in _customerNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markAllOwnerRead() {
    for (var n in _ownerNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markCustomerAsRead(int index) {
    _customerNotifications[index].isRead = true;
    notifyListeners();
  }

  void markOwnerAsRead(int index) {
    _ownerNotifications[index].isRead = true;
    notifyListeners();
  }

  void addNotification(NotificationItem item) {
    _customerNotifications.insert(0, item);
    
    // Add to owner notifications as well
    _ownerNotifications.insert(0, NotificationItem(
      icon: item.icon,
      title: 'You created: ${item.title}',
      subtitle: item.subtitle,
      time: item.time,
    ));
    
    notifyListeners();
  }
}
