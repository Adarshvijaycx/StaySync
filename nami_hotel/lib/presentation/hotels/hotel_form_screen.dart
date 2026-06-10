import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../core/providers/hotel_providers.dart';
import '../../domain/entities/hotel.dart';

class HotelFormScreen extends ConsumerStatefulWidget {
  final String? hotelId;

  const HotelFormScreen({super.key, this.hotelId});

  @override
  ConsumerState<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends ConsumerState<HotelFormScreen> {
  late final FormGroup _form;
  Hotel? _existingHotel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'name': FormControl<String>(validators: [Validators.required]),
      'address': FormControl<String>(validators: [Validators.required]),
      'contact_number': FormControl<String>(validators: [Validators.required]),
      'email': FormControl<String>(validators: [Validators.required, Validators.email]),
      'is_active': FormControl<bool>(value: true),
    });

    _loadHotelData();
  }

  Future<void> _loadHotelData() async {
    if (widget.hotelId != null && widget.hotelId != 'new') {
      _existingHotel = ref.read(hotelProvider(widget.hotelId!));
      if (_existingHotel != null) {
        _form.updateValue({
          'name': _existingHotel!.name,
          'address': _existingHotel!.address,
          'contact_number': _existingHotel!.contactNumber,
          'email': _existingHotel!.email,
          'is_active': _existingHotel!.isActive,
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

  Future<void> _saveHotel() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }

    final value = _form.value;
    final isNew = _existingHotel == null;

    final hotelToSave = isNew
        ? Hotel.empty().copyWith(
            name: value['name'] as String,
            address: value['address'] as String,
            contactNumber: value['contact_number'] as String,
            email: value['email'] as String,
            isActive: value['is_active'] as bool,
          )
        : _existingHotel!.copyWith(
            name: value['name'] as String,
            address: value['address'] as String,
            contactNumber: value['contact_number'] as String,
            email: value['email'] as String,
            isActive: value['is_active'] as bool,
          );

    setState(() => _isLoading = true);

    try {
      if (isNew) {
        await ref.read(hotelsProvider.notifier).createHotel(hotelToSave);
      } else {
        await ref.read(hotelsProvider.notifier).updateHotel(hotelToSave);
      }
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/hotels');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving hotel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isNew = _existingHotel == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Hotel' : 'Edit Hotel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ReactiveForm(
          formGroup: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReactiveTextField<String>(
                formControlName: 'name',
                decoration: const InputDecoration(
                  labelText: 'Hotel Name',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
                validationMessages: {'required': (_) => 'Name is required'},
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'address',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
                validationMessages: {'required': (_) => 'Address is required'},
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'contact_number',
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validationMessages: {'required': (_) => 'Contact number is required'},
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'email',
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                validationMessages: {
                  'required': (_) => 'Email is required',
                  'email': (_) => 'Enter a valid email'
                },
              ),
              const SizedBox(height: 24),
              ReactiveSwitchListTile(
                formControlName: 'is_active',
                title: const Text('Active Status'),
                subtitle: const Text('Is this hotel currently operating?'),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saveHotel,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
