import 'package:flutter/material.dart';
import 'package:omi/pages/settings/device_settings.dart';
import 'package:omi/pages/home/page.dart';
import 'package:omi/pages/onboarding/find_device/page.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:omi/utils/styles.dart';
import 'package:omi/widgets/device_widget.dart';
import 'package:omi/providers/onboarding_provider.dart';
import 'package:provider/provider.dart';

class ConnectDevicePage extends StatefulWidget {
  const ConnectDevicePage({super.key});

  @override
  State<ConnectDevicePage> createState() => _ConnectDevicePageState();
}

class _ConnectDevicePageState extends State<ConnectDevicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Connect',
            style: TextStyle(color: TayaColors.secondaryTextColor),
          ),
          elevation: 0,
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: TayaColors.secondaryTextColor,
              )),
          backgroundColor: Colors.white,
          actions: [
            // IconButton(
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => const DeviceSettings(),
            //       ),
            //     );
            //   },
            //   icon: Icon(
            //     Icons.settings,
            //     color: TayaColors.secondaryTextColor,
            //   ),
            // )
          ],
        ),
        backgroundColor: Colors.white,
        body: ListView(
          children: [
            Consumer<OnboardingProvider>(
              builder: (context, onboardingProvider, child) {
                return DeviceAnimationWidget(
                  isConnected: onboardingProvider.isConnected,
                  deviceName: onboardingProvider.deviceName,
                  animatedBackground: onboardingProvider.isConnected,
                );
              },
            ),
            FindDevicesPage(
              isFromOnboarding: false,
              goNext: () {
                debugPrint('onConnected from FindDevicesPage');
                routeToPage(context, const HomePageWrapper(), replace: true);
              },
              includeSkip: false,
            )
          ],
        ));
  }
}
