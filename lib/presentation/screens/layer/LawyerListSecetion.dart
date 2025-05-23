import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:layer/data/model/model.dart';
import 'package:layer/main.dart';
import 'package:layer/presentation/screens/balance%20&%20payment/balance.dart';
import 'package:layer/presentation/screens/layer/LawyerDetails.dart';
import 'package:layer/presentation/widgets/LayerCard.dart';
import 'package:provider/provider.dart';

class LawyerListSection extends StatefulWidget {
  const LawyerListSection({Key? key}) : super(key: key);

  @override
  _LawyerListSectionState createState() => _LawyerListSectionState();
}

class _LawyerListSectionState extends State<LawyerListSection>
    with SingleTickerProviderStateMixin {
  final List<String> _specializations = [
    'All',
    'Family Law',
    'Corporate Law',
    'Criminal Defense',
    'Real Estate Law',
    'Immigration Law',
  ];

  String _selectedSpecialization = 'All';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _balance = '৳ 1,500'; // Example balance

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final lawyerProvider = Provider.of<LawyerProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150.0,
              floating: true,
              pinned: true,
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        //mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                //radius: 30, // You can change this to control the size
                                backgroundImage: NetworkImage(
                                  "https://plus.unsplash.com/premium_photo-1689977968861-9c91dbb16049?w=800&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cHJvZmlsZSUyMHBpY3R1cmV8ZW58MHx8MHx8fDA%3D",
                                ),
                                backgroundColor: Colors.transparent, // Optional
                              ),

                              SizedBox(width: 12),
                              Text(
                                'Welcome, ${user?.name ?? 'User'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Spacer(),
                              Column(
                                children: [
                                  Icon(
                                    Icons.payment_sharp,
                                    color: Colors.white,
                                    size: 27,
                                  ),
                                  Text(
                                    "Recharge",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          BalanceDisplay(balance: _balance),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search lawyers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ];
        },
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Top Lawyers Section
              Heardersection(text: 'Top Lawyer'),
              const SizedBox(height: 8),

              _horizontalTopLawyersList(context),
              SizedBox(height: 8),
              Heardersection(text: 'Category'),
              // Specialization filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  itemCount: _specializations.length,
                  itemBuilder: (context, index) {
                    final specialization = _specializations[index];
                    final isSelected =
                        specialization == _selectedSpecialization;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(specialization),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSpecialization = specialization;
                            });
                          }
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Lawyers list
              Expanded(
                child: FutureBuilder<List<Lawyer>>(
                  future:
                      _searchController.text.isNotEmpty
                          ? lawyerProvider.searchLawyers(_searchController.text)
                          : Future.value(lawyerProvider.lawyers),
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

                    final lawyers = snapshot.data ?? [];

                    final filteredLawyers =
                        _selectedSpecialization == 'All'
                            ? lawyers
                            : lawyers
                                .where(
                                  (lawyer) =>
                                      lawyer.specialization ==
                                      _selectedSpecialization,
                                )
                                .toList();

                    if (filteredLawyers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No lawyers found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try adjusting your search criteria',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredLawyers.length,
                          itemBuilder: (context, index) {
                            final lawyer = filteredLawyers[index];

                            final itemAnimation = Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.1 * index,
                                  0.1 * index + 0.2,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            );

                            return FadeTransition(
                              opacity: itemAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.5, 0),
                                  end: Offset.zero,
                                ).animate(itemAnimation),
                                child: LawyerCard(
                                  lawyer: lawyer,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => LawyerDetailScreen(
                                              lawyer: lawyer,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Heardersection extends StatelessWidget {
  const Heardersection({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

Widget _horizontalTopLawyersList(BuildContext context) {
  final lawyerProvider = Provider.of<LawyerProvider>(context);
  final lawyers =
      lawyerProvider.lawyers; // Get the actual lawyer data from provider

  return SizedBox(
    height: 230,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: lawyers.length,
      itemBuilder: (context, index) {
        final lawyer = lawyers[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LawyerDetailScreen(lawyer: lawyer),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 175,
                margin: EdgeInsets.only(right: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 1),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          child: Image.network(
                            lawyer.photoUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey[500],
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: 9,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  lawyer.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lawyer.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),

                          //SizedBox(height: 5,),
                          Text(
                            lawyer.specialization,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Row(
                            children: [
                              Text(
                                "Experience: ${lawyer.experience}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            "৳${lawyer.consultationFee.toStringAsFixed(0)} / hour",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
