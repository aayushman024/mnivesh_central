import 'package:flutter/material.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../Utils/Dimensions.dart';

class TeamAttendanceSection extends StatelessWidget {
  const TeamAttendanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.sdp, horizontal: 24.sdp),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16.sdp),
        boxShadow: isDark
            ? [
              BoxShadow(
                color: Colors.blue.withAlpha(25),
                blurRadius: 16,
                offset: const Offset(0, 6)
              )
        ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
        border: Border.all(
          color: Colors.blue,
          width: 0.5
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.sdp,),
          Row(
            children: [
              Icon(PhosphorIconsRegular.briefcase, color: Colors.blue.shade700,),
              SizedBox(width: 14.sdp,),
              Text("Team Attendance",
              style: AppTextStyle.bold.custom(18.ssp),),
            ],
          ),
          SizedBox(height: 25.sdp,),
         EmployeeStatus(employeeName: "Himanshu Singh Dhanik", status: "Checked-In", accentColor: Colors.green.shade700, locationIcon: PhosphorIconsRegular.houseLine,),
         EmployeeStatus(employeeName: "Aayushman Ranjan", status: "Out", accentColor: Colors.red.shade700, locationIcon: null,),
         EmployeeStatus(employeeName: "Aryan Chauhan", status: "Checked-In", accentColor: Colors.green.shade700, locationIcon: PhosphorIconsRegular.buildingOffice,),
         EmployeeStatus(employeeName: "Kishan Kumar", status: "Checked-In", accentColor: Colors.green.shade700,  locationIcon: PhosphorIconsRegular.buildingOffice),
         EmployeeStatus(employeeName: "Sunny Chaudhary", status: "On Leave", accentColor: Colors.orange.shade700),
         EmployeeStatus(employeeName: "Parikshit Saini", status: "Out", accentColor: Colors.red.shade700),
         EmployeeStatus(employeeName: "Mayank Belwal", status: "Checked-In", accentColor: Colors.green.shade700, locationIcon: PhosphorIconsRegular.houseLine,),
         EmployeeStatus(employeeName: "Abhishek Bansal", status: "Out", accentColor: Colors.red.shade700),
        ]
      ),
    );
  }
}


class EmployeeStatus extends StatelessWidget {
  final String employeeName;
  final String status;
  final Color accentColor;
  final PhosphorIconData? locationIcon;

  const EmployeeStatus({
    required this.employeeName,
    required this.status,
    required this.accentColor,
    this.locationIcon,
    super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                SizedBox(width: 10.sdp,),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.5,
                  ),
                  child: Text(employeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.normal.custom(15.ssp),),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 5.sdp),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10.sdp),
                      ),
                      child: Text(status,
                        style: AppTextStyle.normal.custom(13.ssp, accentColor),),
                    ),
                    if(locationIcon != null)...[
                      SizedBox(width: 5.sdp,),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 5.sdp),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(10.sdp),
                        ),
                        child: Icon(locationIcon!, color: accentColor, size: 19.ssp,),
                      ),
                    ]
                  ],
                ),
              ],
            );
          },
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 15.sdp),
          height: 1.sdp,
          color: isDark
              ? Colors.white.withAlpha(10)
              : Colors.black.withAlpha(10),
        ),
      ],
    );
  }
}
