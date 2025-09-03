import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_state.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/widgets/attachment_widget.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AttachmentListScreen extends StatelessWidget {
  final ProjectListBloc bloc;

  const AttachmentListScreen({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(width: double.infinity, child: HeaderWidget()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/newapp/attachment.png',
                      height: 30.w,
                      width: 30.w,
                    ),
                    const Text(
                      ' Attachments',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: appFontColor),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
              ],
            ),
            BlocProvider.value(
              value: bloc,
              child: BlocBuilder<ProjectListBloc, ProjectListState>(
                builder: (ctx, state) {
                  if (state is ProjectAttachmentsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProjectAttachmentsLoaded) {
                    var list = bloc.projectAttacmentList;
                    return RefreshIndicator(
                      onRefresh: () async => {},
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          return AttachmentWidget(item: list[index]);
                        },
                      ),
                    );
                  } else if (state is ProjectAttachmentsError) {
                    return Center(child: Text(state.message));
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
