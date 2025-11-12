import 'package:el_race/core/constants/app_images.dart';
import 'package:el_race/ui/presentation/call_screen/call_screen.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/screens/home_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/visibilty_icon.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> screens = [
    CallScreen(),
    HomeScreenPage(),
    SizedBox(),
  ];

  @override
  Widget build(BuildContext context) {
    final bloc = HomeBloc.get(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, 
      extendBodyBehindAppBar: true,
      bottomNavigationBar:  const CustomBottomNavBar(),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => screens[bloc.currentIndex],
      ),
      // bottomNavigationBar: ,
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final bool isMain;
  const CustomBottomNavBar({this.isMain=true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(builder: (ctx, state) {
      var bloc = HomeBloc.get(ctx);
      if (bloc.enableBottomNav == false) return const SizedBox.shrink();
      return  Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        // margin: EdgeInsets.only(right: 20.w,left: 20.w,),
        decoration: const BoxDecoration(
          // borderRadius: BorderRadius.circular(50.r),
          image: DecorationImage(image: AssetImage("assets/newapp/bottom_nav_background.png")),
          // gradient: const LinearGradient(
          //   colors: [Colors.white, Color.fromARGB(255, 172, 169, 169)],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
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
              isMain: isMain,
              icon: AppImages.callIcon,
            ),
            _buildNavItem(
              context,
              isMain: isMain,
              index: 1,
              icon: AppImages.homeIcon,
            ),
            _buildNavItem(
              context,
              index: 2,
              isMain: isMain,
              icon: AppImages.chatIcon,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNavItem(BuildContext context, {required int index, required String icon, required bool isMain }) {
    final bloc = HomeBloc.get(context);
    return IconButton(
      onPressed: () {
        if(isMain){
          if (index == 2) {
            Util.showComingSoonToast();
            return;
          }
          bloc.add(ChangeCurrentIndex(index: index));
        }
        else{
          bloc.add(ChangeCurrentIndex(index: index));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
                (route) => true,
          );
        }

      },
      icon: Image.asset(
        icon,
        width: 30.w,
      ),
    );
  }
}
