
import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';




class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> screens = [
    SizedBox(),
    HomeScreenPage(),
    SizedBox(),
  ];

  @override
  Widget build(BuildContext context) {
    final bloc = HomeBloc.get(context);
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: const CustomBottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => screens[bloc.currentIndex],
      ),
      // bottomNavigationBar: ,
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50.r),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFBEBEBE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: AppImages.callIcon,
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: AppImages.homeIcon,
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: AppImages.chatIcon,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context,
      {required int index, required String icon}) {
    final bloc = HomeBloc.get(context);
    return IconButton(
      onPressed: () {
        bloc.add(ChangeCurrentIndex(index: index));
      },
      icon: Image.asset(
        icon,
        width: 30.w,
      ),
    );
  }
}