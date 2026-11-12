import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/profile_store.dart';

class PhotoStore {
  static const bucket = 'garage-photos';
  static Future<String?> pick(ProfileStore store) async {
    final owner = store.remote ? store.api.auth.currentUser!.id : null;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Scegli una foto inferiore a 5 MB.');
    }
    final type = contentType(bytes);
    if (!store.remote) return 'data:$type;base64,${base64Encode(bytes)}';
    if (store.api.auth.currentUser?.id != owner) {
      throw StateError('Session changed');
    }
    final path =
        '$owner/${DateTime.now().microsecondsSinceEpoch}.${type.split('/').last}';
    await store.api.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
    return 'storage:$path';
  }

  static String contentType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    throw const FormatException('Scegli una foto JPEG, PNG o WebP.');
  }
}

class UserPhoto extends StatefulWidget {
  final String? value;
  final ProfileStore store;
  final Widget fallback;
  const UserPhoto({
    super.key,
    required this.value,
    required this.store,
    required this.fallback,
  });
  @override
  State<UserPhoto> createState() => _UserPhotoState();
}

class _UserPhotoState extends State<UserPhoto> with WidgetsBindingObserver {
  Future<String>? url;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    resolve();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.value?.startsWith('storage:') == true) {
      setState(resolve);
    }
  }

  @override
  void didUpdateWidget(UserPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) resolve();
  }

  void resolve() {
    final value = widget.value;
    url = value != null && value.startsWith('storage:')
        ? widget.store.api.storage
              .from(PhotoStore.bucket)
              .createSignedUrl(value.substring(8), 3600)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value == null) return widget.fallback;
    if (value.startsWith('data:')) {
      try {
        return Image.memory(
          Uri.parse(value).data!.contentAsBytes(),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      } catch (_) {
        return widget.fallback;
      }
    }
    return FutureBuilder<String>(
      future: url,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return widget.fallback;
        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}

class PhotoEditor extends StatefulWidget {
  final String? value;
  final ProfileStore store;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool>? onBusy;
  final String label;
  final bool preview;
  final bool enabled;
  const PhotoEditor({
    super.key,
    required this.value,
    required this.store,
    required this.onChanged,
    required this.label,
    this.preview = true,
    this.enabled = true,
    this.onBusy,
  });
  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  bool busy = false;
  Future<void> choose() async {
    setState(() => busy = true);
    widget.onBusy?.call(true);
    try {
      final value = await PhotoStore.pick(widget.store);
      if (mounted && value != null) widget.onChanged(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FormatException ? e.message : 'Foto non caricata. Controlla permessi, connessione e riprova.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        widget.onBusy?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.preview && widget.value != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            child: UserPhoto(
              value: widget.value,
              store: widget.store,
              fallback: const Icon(Icons.photo_outlined, size: 48),
            ),
          ),
        ),
      TextButton.icon(
        onPressed: busy || !widget.enabled ? null : choose,
        icon: Icon(
          busy ? Icons.hourglass_top : Icons.add_photo_alternate_outlined,
        ),
        label: Text(busy ? 'Caricamento foto…' : widget.label),
      ),
    ],
  );
}
