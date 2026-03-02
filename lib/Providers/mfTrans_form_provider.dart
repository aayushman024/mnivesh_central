import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum MfTransFormType { purchaseRedemption, switchTrans, systematic }

class MfTransFormState {
  final MfTransFormType activeForm;
  final List<String> mockAmcList;
  final List<String> mockSchemeList;

  MfTransFormState({
    this.activeForm = MfTransFormType.purchaseRedemption,
    this.mockAmcList = const ['HDFC Mutual Fund', 'SBI Mutual Fund', 'ICICI Prudential'],
    this.mockSchemeList = const ['Small Cap Fund', 'Bluechip Fund', 'Liquid Fund'],
  });

  MfTransFormState copyWith({MfTransFormType? activeForm}) {
    return MfTransFormState(
      activeForm: activeForm ?? this.activeForm,
      mockAmcList: mockAmcList,
      mockSchemeList: mockSchemeList,
    );
  }
}

class MfTransFormNotifier extends StateNotifier<MfTransFormState> {
  MfTransFormNotifier() : super(MfTransFormState());

  void setFormType(MfTransFormType type) {
    state = state.copyWith(activeForm: type);
  }
}

final mfTransFormProvider = StateNotifierProvider<MfTransFormNotifier, MfTransFormState>((ref) {
  return MfTransFormNotifier();
});