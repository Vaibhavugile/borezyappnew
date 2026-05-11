import 'package:flutter/material.dart';

import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFFBF9F8),

      body: SafeArea(

        child: Padding(

          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Spacer(),

              /* =====================================================
                 LOGO
              ===================================================== */

              Center(

                child: Container(

                  height: 90,
                  width: 90,

                  decoration: BoxDecoration(

                    gradient:
                        const LinearGradient(

                      colors: [

                        Color(0xFFD4AF37),

                        Color(0xFFF4D58D),
                      ],
                    ),

                    borderRadius:
                        BorderRadius.circular(
                            28),
                  ),

                  child: const Icon(

                    Icons.storefront_rounded,

                    color: Colors.white,

                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /* =====================================================
                 TITLE
              ===================================================== */

              const Center(

                child: Text(

                  "Borezy",

                  style: TextStyle(

                    fontSize: 36,

                    fontWeight:
                        FontWeight.bold,

                    color:
                        Color(0xFF1B1C1C),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(

                child: Text(

                  "Fashion Rental Business Platform",

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    fontSize: 15,

                    height: 1.5,

                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /* =====================================================
                 FEATURES
              ===================================================== */

              _featureTile(
                Icons.calendar_month_rounded,
                "Booking Management",
              ),

              _featureTile(
                Icons.people_alt_rounded,
                "Customer CRM",
              ),

              _featureTile(
                Icons.inventory_2_rounded,
                "Inventory Tracking",
              ),

              _featureTile(
                Icons.analytics_rounded,
                "Business Analytics",
              ),

              const Spacer(),

              /* =====================================================
                 LOGIN BUTTON
              ===================================================== */

              SizedBox(

                width: double.infinity,

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            LoginScreen(),
                      ),
                    );
                  },

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(
                            0xFF1B1C1C),

                    foregroundColor:
                        Colors.white,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                              22),
                    ),
                  ),

                  child: const Text(

                    "LOGIN",

                    style: TextStyle(

                      fontWeight:
                          FontWeight.bold,

                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /* =====================================================
                 BOOK DEMO
              ===================================================== */

              SizedBox(

                width: double.infinity,

                child: OutlinedButton(

                  onPressed: () {

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(

                      const SnackBar(

                        content: Text(
                          "Book Demo Coming Soon",
                        ),
                      ),
                    );
                  },

                  style:
                      OutlinedButton.styleFrom(

                    foregroundColor:
                        const Color(
                            0xFF1B1C1C),

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    side: BorderSide(
                      color:
                          Colors.grey.shade300,
                    ),

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                              22),
                    ),
                  ),

                  child: const Text(

                    "BOOK DEMO",

                    style: TextStyle(

                      fontWeight:
                          FontWeight.bold,

                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureTile(
    IconData icon,
    String title,
  ) {

    return Padding(

      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: Row(

        children: [

          Container(

            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color:
                  const Color(0xFFF6F3F2),

              borderRadius:
                  BorderRadius.circular(
                      16),
            ),

            child: Icon(

              icon,

              color:
                  const Color(0xFFD4AF37),
            ),
          ),

          const SizedBox(width: 14),

          Text(

            title,

            style: const TextStyle(

              fontSize: 15,

              fontWeight:
                  FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}