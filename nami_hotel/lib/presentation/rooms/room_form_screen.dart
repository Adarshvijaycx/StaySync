import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../core/providers/room_providers.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/room_status.dart';
import '../../domain/entities/room_type.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  final String hotelId;
  final String? roomId;

  const RoomFormScreen({super.key, required this.hotelId, this.roomId});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  late final FormGroup _form;
  Room? _existingRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'room_number': FormControl<String>(validators: [Validators.required]),
      'type': FormControl<RoomType>(value: RoomType.standard, validators: [Validators.required]),
      'rate': FormControl<double>(validators: [Validators.required, Validators.min(0)]),
      'status': FormControl<RoomStatus>(value: RoomStatus.available, validators: [Validators.required]),
    });

    _loadRoomData();
  }

  Future<void> _loadRoomData() async {
    if (widget.roomId != null && widget.roomId != 'new') {
      _existingRoom = ref.read(roomProvider((hotelId: widget.hotelId, roomId: widget.roomId!)));
      if (_existingRoom != null) {
        _form.updateValue({
          'room_number': _existingRoom!.roomNumber,
          'type': _existingRoom!.type,
          'rate': _existingRoom!.rate,
          'status': _existingRoom!.status,
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }

    final value = _form.value;
    final isNew = _existingRoom == null;

    final roomToSave = isNew
        ? Room.empty(hotelId: widget.hotelId).copyWith(
            roomNumber: value['room_number'] as String,
            type: value['type'] as RoomType,
            rate: value['rate'] as double,
            status: value['status'] as RoomStatus,
          )
        : _existingRoom!.copyWith(
            roomNumber: value['room_number'] as String,
            type: value['type'] as RoomType,
            rate: value['rate'] as double,
            status: value['status'] as RoomStatus,
          );

    setState(() => _isLoading = true);

    try {
      if (isNew) {
        await ref.read(roomsProvider(widget.hotelId).notifier).createRoom(roomToSave);
      } else {
        await ref.read(roomsProvider(widget.hotelId).notifier).updateRoom(roomToSave);
      }
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/hotels/${widget.hotelId}/rooms');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving room: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isNew = _existingRoom == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Room' : 'Edit Room'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ReactiveForm(
          formGroup: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReactiveTextField<String>(
                formControlName: 'room_number',
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validationMessages: {'required': (_) => 'Room number is required'},
              ),
              const SizedBox(height: 16),
              
              ReactiveDropdownField<RoomType>(
                formControlName: 'type',
                decoration: const InputDecoration(
                  labelText: 'Room Type',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: RoomType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ReactiveTextField<double>(
                formControlName: 'rate',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Nightly Rate (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validationMessages: {
                  'required': (_) => 'Rate is required',
                  'min': (_) => 'Rate cannot be negative',
                },
              ),
              const SizedBox(height: 16),

              ReactiveDropdownField<RoomStatus>(
                formControlName: 'status',
                decoration: const InputDecoration(
                  labelText: 'Current Status',
                  prefixIcon: Icon(Icons.info_outline_rounded),
                ),
                items: RoomStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              FilledButton(
                onPressed: _saveRoom,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
