import 'package:flutter/material.dart';
import 'package:giftle/pages/castumpost.dart';
import 'package:giftle/pages/pagepost.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final VoidCallback onTapCallback; // callback لتنفيذ العملية عند النقر

  PostTile({required this.post, required this.onTapCallback});

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // تنفيذ الcallback عند النقر على الـ PostTile
        widget.onTapCallback();
      },
      child: cachedNetworkImage(widget.post.mediaUrl),
    );
  }
}
