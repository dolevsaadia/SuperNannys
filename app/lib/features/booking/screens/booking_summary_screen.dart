import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class BookingSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  const BookingSummaryScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Booking Summary'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(child: Text('Summary: $bookingData')),
      );
}
