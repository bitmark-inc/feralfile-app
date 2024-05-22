// import 'package:autonomy_flutter/model/play_control_model.dart';
// import 'package:autonomy_flutter/view/cast_button.dart';
// import 'package:feralfile_app_theme/feral_file_app_theme.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// class PlaylistControl extends StatelessWidget {
//   final PlayControlModel playControl;
//   final Function()? onPlayTap;
//   final Function()? onTimerTap;
//   final Function()? onShuffleTap;
//   final Function()? onCastTap;
//   final bool showPlay;
//   final bool isCasting;

//   const PlaylistControl({
//     required this.playControl,
//     required this.isCasting,
//     super.key,
//     this.onPlayTap,
//     this.onTimerTap,
//     this.onShuffleTap,
//     this.showPlay = true,
//     this.onCastTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       color: theme.colorScheme.primary,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 15),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ControlItem(
//               icon: SvgPicture.asset(
//                 'assets/images/time_off_icon.svg',
//                 width: 24,
//                 colorFilter:
//                     ColorFilter.mode(theme.disableColor, BlendMode.srcIn),
//               ),
//               iconFocus: Stack(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(0, 0, 4, 2),
//                     child: SvgPicture.asset(
//                       'assets/images/time_off_icon.svg',
//                       width: 24,
//                       colorFilter: ColorFilter.mode(
//                           theme.colorScheme.secondary, BlendMode.srcIn),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: Visibility(
//                       visible: playControl.timer != 0,
//                       child: Container(
//                         padding: const EdgeInsets.fromLTRB(3, 2, 3, 0),
//                         decoration: BoxDecoration(
//                           color: theme.colorScheme.secondary,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           playControl.timer.toString(),
//                           style: TextStyle(
//                             fontFamily: 'PPMori',
//                             color: theme.colorScheme.primary,
//                             fontSize: 8,
//                             height: 1,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//               isActive: playControl.timer != 0,
//               onTap: () {
//                 onTimerTap?.call();
//               },
//             ),
//             ControlItem(
//               icon: SvgPicture.asset(
//                 'assets/images/shuffle_icon.svg',
//                 width: 24,
//                 colorFilter:
//                     ColorFilter.mode(theme.disableColor, BlendMode.srcIn),
//               ),
//               iconFocus: SvgPicture.asset(
//                 'assets/images/shuffle_icon.svg',
//                 width: 24,
//                 colorFilter: ColorFilter.mode(
//                     theme.colorScheme.secondary, BlendMode.srcIn),
//               ),
//               isActive: playControl.isShuffle,
//               onTap: () {
//                 onShuffleTap?.call();
//               },
//             ),
//             if (showPlay) ...[
//               ControlItem(
//                 icon: SvgPicture.asset(
//                   'assets/images/play_icon.svg',
//                   width: 24,
//                   colorFilter: ColorFilter.mode(
//                       theme.colorScheme.secondary, BlendMode.srcIn),
//                 ),
//                 iconFocus: SvgPicture.asset(
//                   'assets/images/play_icon.svg',
//                   width: 24,
//                   colorFilter: ColorFilter.mode(
//                       theme.colorScheme.secondary, BlendMode.srcIn),
//                 ),
//                 onTap: () {
//                   onPlayTap?.call();
//                 },
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: FFCastButton(
//                   onDeviceSelected: (device) => {onCastTap?.call()},
//                   isCasting: isCasting,
//                 ),
//               )
//             ]
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ControlItem extends StatefulWidget {
//   final Widget icon;
//   final Widget iconFocus;
//   final bool isActive;
//   final Function()? onTap;

//   const ControlItem({
//     required this.icon,
//     required this.iconFocus,
//     super.key,
//     this.isActive = false,
//     this.onTap,
//   });

//   @override
//   State<ControlItem> createState() => _ControlItemState();
// }

// class _ControlItemState extends State<ControlItem> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: widget.isActive ? widget.iconFocus : widget.icon,
//           ),
//           Container(
//             width: 4,
//             height: 4,
//             decoration: widget.isActive
//                 ? BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: theme.colorScheme.secondary,
//                   )
//                 : null,
//           )
//         ],
//       ),
//     );
//   }
// }
