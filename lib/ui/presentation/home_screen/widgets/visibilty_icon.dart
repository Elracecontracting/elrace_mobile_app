import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArraowVisibalityBottomNav extends StatelessWidget {
  const ArraowVisibalityBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: BlocBuilder<HomeBloc, HomeState>(builder: (ctx, state) {
        var bloc = HomeBloc.get(ctx);
        return InkWell(
          onTap: () => bloc.add(const ChangeVisiablityIcon()),
          child: Container(
            alignment: Alignment.bottomRight,
            height: 50.w,
            margin:const EdgeInsets.symmetric(horizontal: 10),
            child: !bloc.enableBottomNav
                ? Image.asset(
                    "assets/newapp/arrow_appear.png",
                    width: 40.w,
                  )
                : Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      "assets/newapp/arrow.png",
                      width: 35.w,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
