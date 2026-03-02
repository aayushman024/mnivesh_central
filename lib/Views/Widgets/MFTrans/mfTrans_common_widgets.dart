// import 'package:flutter/material.dart';
//
// // --- COMMON HEADER --- //
// class MfTransHeaderWidget extends StatelessWidget {
//   const MfTransHeaderWidget({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Client Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             const SizedBox(height: 12),
//             TextFormField(
//               decoration: const InputDecoration(labelText: 'Investor Name / PAN', border: OutlineInputBorder()),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     decoration: const InputDecoration(labelText: 'ARN Code', border: OutlineInputBorder()),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: TextFormField(
//                     decoration: const InputDecoration(labelText: 'Folio Number', border: OutlineInputBorder()),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // --- PURCHASE / REDEMPTION FORM --- //
// class PurchRedempForm extends StatelessWidget {
//   final List<String> mockAmcList;
//   final List<String> mockSchemeList;
//
//   const PurchRedempForm({Key? key, required this.mockAmcList, required this.mockSchemeList}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       key: const ValueKey('PurchaseForm'),
//       children: [
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'Transaction Type', border: OutlineInputBorder()),
//           items: ['Purchase', 'Redemption'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'AMC', border: OutlineInputBorder()),
//           items: mockAmcList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'Scheme', border: OutlineInputBorder()),
//           items: mockSchemeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         TextFormField(
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
//         ),
//       ],
//     );
//   }
// }
//
// // --- SWITCH FORM --- //
// class SwitchForm extends StatelessWidget {
//   final List<String> mockSchemeList;
//
//   const SwitchForm({Key? key, required this.mockSchemeList}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       key: const ValueKey('SwitchForm'),
//       children: [
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'Switch From Scheme', border: OutlineInputBorder()),
//           items: mockSchemeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'Switch To Scheme', border: OutlineInputBorder()),
//           items: mockSchemeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(labelText: 'By', border: OutlineInputBorder()),
//                 items: ['Amount', 'Units', 'All Units'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//                 onChanged: (val) {},
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: TextFormField(
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
//               ),
//             )
//           ],
//         )
//       ],
//     );
//   }
// }
//
// // --- SYSTEMATIC FORM --- //
// class SystematicForm extends StatelessWidget {
//   final List<String> mockAmcList;
//   final List<String> mockSchemeList;
//
//   const SystematicForm({Key? key, required this.mockAmcList, required this.mockSchemeList}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       key: const ValueKey('SystematicForm'),
//       children: [
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'Systematic Type', border: OutlineInputBorder()),
//           items: ['SIP', 'STP', 'SWP'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'AMC', border: OutlineInputBorder()),
//           items: mockAmcList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         DropdownButtonFormField<String>(
//           decoration: const InputDecoration(labelText: 'Scheme', border: OutlineInputBorder()),
//           items: mockSchemeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (val) {},
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Installment Amount', border: OutlineInputBorder()),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
//                 items: ['Monthly', 'Quarterly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//                 onChanged: (val) {},
//               ),
//             ),
//           ],
//         )
//       ],
//     );
//   }
// }

// lib/Views/Widgets/MFTrans/mfTrans_common_widgets.dart
//
// SwitchForm, SystematicForm, and PurchRedempForm have been moved to:
//   lib/Views/MFTransaction/Widgets/switch_form.dart
//   lib/Views/MFTransaction/Widgets/systematic_form.dart
//   lib/Views/MFTransaction/Widgets/purch_redemp_form.dart
//
// Only the shared header widget is retained here.

import 'package:flutter/material.dart';

class MfTransHeaderWidget extends StatelessWidget {
  const MfTransHeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Investor Name / PAN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ARN Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Folio Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
