// import 'package:anshed/widgets/text_styles.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:logger/logger.dart';
//
// import '../controllers/PlayerController.dart';
// import '../models/song.dart';
//
// class MusicTile extends StatelessWidget {
//   final Song song;
//   final int index;
//   final VoidCallback onTap;
//
//   const MusicTile({
//     Key? key,
//     required this.song,
//     required this.index,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final PlayerController c = Get.find<PlayerController>();
//
//     return Obx(() {
//       final isCurrent = c.currentIndex == index;
//       final isPlaying = isCurrent && c.playerState.playing;
//       final isCached = c.isSongCached(song.url);
//
//       return Container(
//         color: isPlaying
//             // ? const Color.fromRGBO(1, 72, 31, 1)
//             ? Colors.green.shade900
//             : Colors.black,
//         child: ListTile(
//           leading: _buildArtwork(context),
//           title: _buildTitle(context, isPlaying),
//           trailing: _buildTrailing(c, isCached),
//           onTap: onTap,
//         ),
//       );
//     });
//   }
//
//   // ... keep _buildArtwork and _buildTitle the same ...
//   Widget _buildArtwork(BuildContext context) {
//     return SizedBox(
//       width: 50,
//       height: 50,
//       child: CachedNetworkImage(
//         imageUrl: song.artworkUrl ?? '',
//         placeholder: (ctx, url) => Image.asset('assets/s.png'),
//         errorWidget: (ctx, url, err) => Image.asset('assets/s.png'),
//         fit: BoxFit.cover,
//       ),
//     );
//   }
//
//   Widget _buildTitle(BuildContext context, bool isPlaying) {
//     return Text(
//       song.name,
//       overflow: TextOverflow.ellipsis,
//       style: mediumTextStyle(context, bold: isPlaying),
//     );
//   }
//
//   Widget _buildTrailing(PlayerController c, bool isCached) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (isCached) const Icon(Icons.download_done, color: Colors.orange),
//         if (!isCached)
//           IconButton(
//             icon: const Icon(Icons.download_for_offline, color: Colors.white),
//             onPressed: () => _handleDownload(c),
//           ),
//       ],
//     );
//   }
//
//   void _handleDownload(PlayerController c) {
//     Logger().i('Downloading song at index $index');
//     c.downloadSong(index); // Changed to public method
//     Get.snackbar(
//       'بدأ التحميل',
//       'جاري تحميل "${song.name}"',
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
// }
