import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/dio_exception_ext.dart';
import 'package:dio/dio.dart';

class GiftHandler {
  static Future<void> handleGiftMembership(String? giftCode) async {
    final isSubscribe = await injector<IAPService>().isSubscribed();
    if (isSubscribe) {
      await injector<NavigationService>().showPremiumUserCanNotClaim();
      return;
    }
    final navigationService = injector<NavigationService>();
    if (giftCode == null) {
      await navigationService.showMembershipGiftCodeEmpty();
      return;
    } else {
      final authService = injector<AuthService>();
      try {
        final isSuccess = await authService.redeemGiftCode(giftCode);
        if (isSuccess) {
          await authService.getAuthToken(forceRefresh: true);
          injector<SubscriptionBloc>().add(GetSubscriptionEvent());
          await navigationService.showRedeemMembershipSuccess();
          return;
        }
      } on DioException catch (e) {
        final ferErrorCode = e.ffErrorCode;
        switch (ferErrorCode) {
          case 3000:
            await navigationService.showRedeemMembershipCodeUsed();
            return;
          case 3001:
            await navigationService.showPremiumUserCanNotClaim();
            return;
          default:
            break;
        }
      }
      await navigationService.showFailToRedeemMembership();
    }
  }
}
