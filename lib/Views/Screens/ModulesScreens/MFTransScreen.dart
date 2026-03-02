import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../Models/mftrans_models.dart';
import '../../../ViewModels/mfTransaction_viewModel.dart';

class MfTransactionScreen extends ConsumerStatefulWidget {
  const MfTransactionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MfTransactionScreen> createState() => _MfTransactionScreenState();
}

class _MfTransactionScreenState extends ConsumerState<MfTransactionScreen> {
  // capturing Autocomplete controllers to sync them on selection
  TextEditingController? _invCtrl;
  TextEditingController? _panCtrl;
  TextEditingController? _headCtrl;

  final Map<String, GlobalKey> _cardKeys = {};

  Future<void> _pickDateTime(BuildContext context, WidgetRef ref) async {
    final state = ref.read(mfTransactionProvider);
    final now = DateTime.now();
    final defaultDateTime = state.selectedDate ?? DateTime(now.year, now.month, now.day, 10, 0);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: defaultDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blue),
          //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(defaultDateTime),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        final finalDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        ref.read(mfTransactionProvider.notifier).setDate(finalDateTime);
      }
    }
  }

  void _onUccSelected(String id) {
    ref.read(mfTransactionProvider.notifier).selectUcc(id);

    // allow layout cycle to finish before animating scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _cardKeys[id];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mfTransactionProvider);
    final viewModel = ref.read(mfTransactionProvider.notifier);

    // sync all fields when one updates the global state
    ref.listen(mfTransactionProvider, (previous, next) {
      if (previous?.selectedInvestor != next.selectedInvestor && next.selectedInvestor != null) {
        if (_invCtrl?.text != next.selectedInvestor!.name) _invCtrl?.text = next.selectedInvestor!.name;
        if (_panCtrl?.text != next.selectedInvestor!.pan) _panCtrl?.text = next.selectedInvestor!.pan;
        if (_headCtrl?.text != next.selectedInvestor!.familyHead) _headCtrl?.text = next.selectedInvestor!.familyHead;
      }
    });

    final dateStr = state.selectedDate != null
        ? DateFormat('dd-MM-yyyy  hh:mm a').format(state.selectedDate!)
        : "dd-mm-yyyy  --:--";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("MF Transaction", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2)))),
                            const SizedBox(width: 8),
                            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(2)))),
                            const SizedBox(width: 8),
                            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(2)))),
                          ],
                        ),
                        const SizedBox(height: 28),

                        const Text("Transaction Preference", style: TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPrefButton(
                                  title: "ASAP",
                                  isSelected: state.preference == TransPref.asap,
                                  onTap: () => viewModel.setPreference(TransPref.asap)
                              ),
                              const SizedBox(width: 8),
                              _buildPrefButton(
                                  title: "Next Working Day",
                                  isSelected: state.preference == TransPref.nextWorkingDay,
                                  onTap: () => viewModel.setPreference(TransPref.nextWorkingDay)
                              ),
                              const SizedBox(width: 8),
                              _buildPrefButton(
                                  title: "Select Date & Time",
                                  isSelected: state.preference == TransPref.custom,
                                  onTap: () => viewModel.setPreference(TransPref.custom)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // date picker visible only for last two options
                        if (state.preference != TransPref.asap) ...[
                          const Text("Date & Time", style: TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickDateTime(context, ref),
                            child: AbsorbPointer(
                              child: _buildInputField(hint: dateStr, suffixIcon: Icons.calendar_today_rounded, isBold: state.selectedDate != null),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Investor Name", style: TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24, width: 24,
                                  child: Checkbox(
                                    value: true,
                                    onChanged: (v) {},
                                    activeColor: Colors.blue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text("Search All", style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildSearchableDropdown(
                          viewModel: viewModel,
                          hint: "Search by Name...",
                          displayString: (option) => option.name,
                          onInitController: (ctrl) => _invCtrl = ctrl,
                          searchFunction: viewModel.searchByName,
                        ),

                        const SizedBox(height: 20),
                        const Text("PAN Number", style: TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),

                        _buildSearchableDropdown(
                          viewModel: viewModel,
                          hint: "Search by PAN...",
                          displayString: (option) => option.pan,
                          onInitController: (ctrl) => _panCtrl = ctrl,
                          searchFunction: viewModel.searchByPan,
                        ),

                        const SizedBox(height: 20),
                        const Text("Family Head", style: TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),

                        _buildSearchableDropdown(
                          viewModel: viewModel,
                          hint: "Search by Family Head...",
                          displayString: (option) => option.familyHead,
                          onInitController: (ctrl) => _headCtrl = ctrl,
                          searchFunction: viewModel.searchByFamilyHead,
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: state.isSearchingUcc ? null : viewModel.fetchUccData,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                            ),
                            child: state.isSearchingUcc
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Search UCC", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),

                        if (state.showUcc) ...[
                          const SizedBox(height: 32),
                          const Text("Select UCC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 16),
                          ...state.uccData.map((data) => _buildUccCard(data, state.selectedUccId)).toList(),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (state.selectedUccId != null)
            Positioned(
              bottom: 24, left: 32, right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: viewModel.deselectUcc,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                        ),
                        child: const Text("Deselect", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                        ),
                        child: const Text("Proceed", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown({
    required MfTransactionViewModel viewModel,
    required String hint,
    required String Function(InvestorModel) displayString,
    required void Function(TextEditingController) onInitController,
    required Future<List<InvestorModel>> Function(String) searchFunction,
  }) {
    return Autocomplete<InvestorModel>(
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const Iterable<InvestorModel>.empty();
        return await searchFunction(textEditingValue.text);
      },
      displayStringForOption: displayString,
      onSelected: viewModel.selectInvestor,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        onInitController(controller);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black12,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 48),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text("PAN: ${option.pan}  •  Head: ${option.familyHead}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({required String hint, IconData? suffixIcon, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: isBold ? Colors.black87 : Colors.grey.shade600, fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
          if (suffixIcon != null) Icon(suffixIcon, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildPrefButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUccCard(UccModel data, String? selectedUccId) {
    _cardKeys.putIfAbsent(data.id, () => GlobalKey());
    final isSelected = data.id == selectedUccId;

    return GestureDetector(
      onTap: () => _onUccSelected(data.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        key: _cardKeys[data.id],
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50.withOpacity(0.4) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, spreadRadius: 1)]
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: Colors.blue, size: 20)
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                            const SizedBox(height: 2),
                            Text(data.id, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (data.isValidated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                          child: const Text("Validated", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600)),
                        )
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dashCount = (constraints.constrainWidth() / 8).floor();
                      return Flex(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        direction: Axis.horizontal,
                        children: List.generate(dashCount, (_) => SizedBox(width: 4, height: 1, child: ColoredBox(color: Colors.grey.shade300))),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn("Joint 1", "--"),
                      _buildInfoColumn("Joint 2", "--"),
                      _buildInfoColumn("Tax Holding", "IND / SI"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn("BSE Status", data.bseStatus, valueColor: data.bseStatus == "Active" ? const Color(0xFF2E7D32) : Colors.red),
                      _buildInfoColumn("Bank Detail", data.bank),
                      _buildInfoColumn("Nominee", data.nominee),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(topRight: Radius.circular(18), bottomLeft: Radius.circular(18))
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? Colors.black87)),
      ],
    );
  }
}