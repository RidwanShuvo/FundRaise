import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import at the top

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Declare Firestore instance here
  String selectedCategory = "All";

  final List<Map<String, dynamic>> fundraisers = [
    {"name": "Medical Aid for John", "category": "Medical", "raised": 700, "goal": 2000},
    {"name": "Help for Education", "category": "Education", "raised": 1200, "goal": 3000},
    {"name": "Sports Club Fund", "category": "Sports", "raised": 800, "goal": 1500},
    {"name": "Local School Support", "category": "Education", "raised": 3000, "goal": 5000},
    {"name": "Heart Surgery Support", "category": "Medical", "raised": 1500, "goal": 5000},
  ];

  List<String> categories = ["All", "Medical", "Education", "Emergency", "Clubs", "Sports"];
  List<Map<String, String>> recentDonationsList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HSTU DigiFund"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("User Name"),
              accountEmail: Text(_auth.currentUser?.email ?? "No Email"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.teal),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Log Out"),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          carouselSlider(),
          SizedBox(height: 20),
          Text("Featured Emergency Fundraiser", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          featuredEmergencyFundraiser(),
          SizedBox(height: 20),
          Text("Fundraiser Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          categorySelector(),
          SizedBox(height: 20),
          Text("Ongoing Fundraisers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ongoingFundraisers(),
          SizedBox(height: 20),
          Text("Recent Donations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          recentDonations(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal,
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.home, color: Colors.white), onPressed: () {}),
            IconButton(icon: Icon(Icons.list, color: Colors.white), onPressed: () {}),
            IconButton(icon: Icon(Icons.person, color: Colors.white), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget carouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true),
      items: fundraisers.map((fundraiser) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Text(fundraiser["name"], style: TextStyle(color: Colors.white, fontSize: 16.0)),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget featuredEmergencyFundraiser() {
    return Card(
      color: Colors.redAccent,
      child: ListTile(
        title: Text("Emergency: Help for Flood Victims", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("Raised: \$5000 / Goal: \$10000", style: TextStyle(color: Colors.white70)),
        trailing: ElevatedButton(
          onPressed: () {
            showDonationDialog({"name": "Help for Flood Victims", "raised": 5000, "goal": 10000});
          },
          child: Text("Donate"),
        ),
      ),
    );
  }

  Widget categorySelector() {
    return Wrap(
      spacing: 8.0,
      children: categories.map((category) {
        return ChoiceChip(
          label: Text(category),
          selected: selectedCategory == category,
          onSelected: (selected) {
            setState(() {
              selectedCategory = category;
            });
          },
        );
      }).toList(),
    );
  }

  Widget ongoingFundraisers() {
    return Column(
      children: fundraisers.where((fundraiser) => selectedCategory == "All" || fundraiser["category"] == selectedCategory).map((fundraiser) {
        return Card(
          child: ListTile(
            title: Text(fundraiser["name"]),
            subtitle: Text("Raised: \$${fundraiser["raised"]} / Goal: \$${fundraiser["goal"]}"),
            trailing: ElevatedButton(
              onPressed: () {
                showDonationDialog(fundraiser);
              },
              child: Text("Donate"),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget recentDonations() {
    return Column(
      children: recentDonationsList.isEmpty
          ? [Text("No recent donations yet", style: TextStyle(color: Colors.grey))]
          : recentDonationsList.map((donation) {
        return ListTile(
          leading: Icon(Icons.person, color: Colors.teal),
          title: Text("${donation["name"]} donated \$${donation["amount"]}"),
          subtitle: Text(donation["date"] ?? ""),
        );
      }).toList(),
    );
  }

  void showDonationDialog(Map<String, dynamic> fundraiser) {
    TextEditingController amountController = TextEditingController();
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Donate to ${fundraiser["name"]}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Raised: \$${fundraiser["raised"]} / Goal: \$${fundraiser["goal"]}"),
              SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Enter your name", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter donation amount", border: OutlineInputBorder()),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Simulate bKash payment process
                  _processBkashPayment(amountController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, // bKash brand color
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Pay with bKash", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String amount = amountController.text.trim();
                String donorName = nameController.text.trim();
                if (amount.isNotEmpty && donorName.isNotEmpty) {
                  // Save to Firestore
                  await _firestore.collection('donations').add({
                    'name': donorName,
                    'amount': amount,
                    'date': DateTime.now(),
                    'fundraiser': fundraiser["name"],
                    'paymentMethod': 'bKash', // Add payment method
                  });

                  // Update the local state
                  setState(() {
                    recentDonationsList.insert(0, {
                      "name": donorName,
                      "amount": amount,
                      "date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                    });
                  });

                  Navigator.pop(context);
                }
              },
              child: Text("Donate"),
            ),
          ],
        );
      },
    );
  }

// Simulate bKash payment process
  // Simulate bKash payment process
  void _processBkashPayment(String amount) async {
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter an amount to proceed with bKash payment.")),
      );
      return;
    }

    // Official bKash payment link
    final String bkashPaymentUrl = "https://bka.sh/next";

    try {
      // Use url_launcher to open the bKash payment URL
      if (await canLaunch(bkashPaymentUrl)) {
        await launch(bkashPaymentUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open bKash. Please make sure the app is installed or try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: ${e.toString()}")),
      );
    }
  }


}