import 'dart:async';
import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/repositories/project_repository_impl.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_partner_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_by_partner_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/screens/project_list_screen.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MyProject extends StatefulWidget {
  const MyProject({super.key});

  @override
  State<MyProject> createState() => _MyProjectState();
}

class _MyProjectState extends State<MyProject> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = SharedPref.getLoginData().result?.token ?? '';
      final url = Uri.parse('https://test.elrace.com/api/clients/list');

      final request = http.Request("GET", url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.body = jsonEncode({"jsonrpc": "2.0", "params": {}});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['result'] != null) {
        setState(() {
          _clients = List<Map<String, dynamic>>.from(data['result']['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'Failed to load clients';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderWidget(),
      body: Column(
        children: [
          const SizedBox(height: 10),
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
                    "assets/newapp/my_projects.png",
                    height: 30.w,
                    width: 30.w,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    translate('home.projects'),
                    style: GoogleFonts.koulen(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w500,
                      color: appFontColor,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 48.w),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        itemCount: _clients.length,
                        itemBuilder: (context, index) {
                          final c = _clients[index];

                          final id = c['id'] ?? 0;
                          final name = c['name'] ?? '';
                          final totalProjects = c['total_projects'] ?? 0;
                          final totalAmount =
                              (c['total_projects_amount'] ?? 0).toDouble();
                          final photo = c['photo_url'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              final repo = ProjectRepositoryImpl(
                                  ProjectRemoteDataSource());
                              final bloc = ProjectListBloc(
                                getProjectsUseCase: GetProjectsUseCase(
                                  repository: repo,
                                ),
                                getProjectAttachmentsUseCase:
                                    GetProjectAttachmentsUseCase(
                                        repository: repo),
                                getProjectsByPartnerUseCase:
                                    GetProjectsByPartnerUseCase(
                                        repository: repo),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: bloc,
                                    child: ProjectListScreen(
                                      bloc: bloc,
                                      partnerId: id,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: buildProjectCard(
                              name: name,
                              photoUrl: photo,
                              wo: "#$totalProjects",
                              amount: _formatAmount(totalAmount),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

//
// ------------- CARD — EXACT MATCH TO REFERENCE ----------------
//

Widget buildProjectCard({
  required String name,
  required String photoUrl,
  required String wo,
  required String amount,
}) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22.r),
      gradient: const LinearGradient(
        colors: [Color(0xFF151544), Color(0xFF3535AA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Container(
      height: 150.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21.r),
        gradient: const LinearGradient(
          colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // avatar
          Container(
            width: 85.w,
            height: 85.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : 'C',
                    style: GoogleFonts.koulen(
                      fontSize: 28.sp,
                      color: appFontColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // divider
          Container(width: 2.5.w, height: 75.h, color: Colors.white),

          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF151544), Color(0xFF3535AA)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.7, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    name.toUpperCase(),
                    style: GoogleFonts.koulen(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _pillData("W.O", wo),
                    SizedBox(width: 12.w),
                    _pillData("AMOUNT", amount),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}

Widget _pillData(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.koulen(
            fontSize: 14.sp,
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.koulen(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    ),
  );
}
