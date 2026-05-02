import 'package:flutter/widgets.dart';

import 'profile_image_provider_stub.dart'
    if (dart.library.io) 'profile_image_provider_io.dart';

ImageProvider? profileImageProvider(String? photoUri) {
  return platformProfileImageProvider(photoUri);
}
