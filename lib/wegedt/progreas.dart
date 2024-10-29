import 'package:flutter/material.dart';

circularProgress() {
  return Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.only(top: 10.0),
    child: const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Color.fromRGBO(126, 187, 57, 1)),
    ),
  );
}

linerPrograes() {
  return const LinearProgressIndicator(
    valueColor: AlwaysStoppedAnimation(Color.fromRGBO(126, 187, 57, 1)),
  );
}
