import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/room_providers.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/id_proof_type.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/payment_mode.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/room_status.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../data/repositories/customer_repository.dart';
class BookingFormScreen extends ConsumerStatefulWidget {
  final String hotelId;
  final String? bookingId;

  const BookingFormScreen({super.key, required this.hotelId, this.bookingId});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  late final FormGroup _form;
  Booking? _existingBooking;
  Customer? _existingCustomer;
  bool _isLoading = true;
  
  List<Room> _allRooms = [];
  List<Booking> _allBookings = [];
  List<Room> _availableRooms = [];

  final ImagePicker _picker = ImagePicker();
  File? _idProofImage;
  File? _guestPhoto;

  @override
  void initState() {
    super.initState();
    _initForm();
    _setupListeners();
    _loadData();
  }

  void _initForm() {
    final now = DateTime.now();
    final today12PM = DateTime(now.year, now.month, now.day, 12, 0);
    final tomorrow11AM = DateTime(now.year, now.month, now.day + 1, 11, 0);

    _form = FormGroup({
      // Customer Info
      'guest_name': FormControl<String>(validators: [Validators.required]),
      'dob': FormControl<DateTime>(validators: [Validators.required]),
      'phone': FormControl<String>(validators: [Validators.required, Validators.pattern(r'^\d{10}$')]),
      'email': FormControl<String>(validators: [Validators.email]),
      'parent_name': FormControl<String>(),
      'address': FormControl<String>(validators: [Validators.required]),
      'pincode': FormControl<String>(validators: [Validators.required, Validators.pattern(r'^\d{6}$')]),
      'id_proof_type': FormControl<IdProofType>(value: IdProofType.aadhaar, validators: [Validators.required]),
      'id_proof_number': FormControl<String>(validators: [Validators.required]),

      // Booking Info
      'room_id': FormControl<String>(validators: [Validators.required]),
      'room_rate': FormControl<double>(value: 0.0, validators: [Validators.required, Validators.min(0)]),
      'guests_count': FormControl<int>(value: 1, validators: [Validators.required, Validators.min(1)]),
      'check_in': FormControl<DateTime>(value: today12PM, validators: [Validators.required]),
      'check_out': FormControl<DateTime>(value: tomorrow11AM, validators: [Validators.required]),
      'payment_mode': FormControl<PaymentMode>(value: PaymentMode.cash, validators: [Validators.required]),
      'total_amount': FormControl<double>(value: 0.0, validators: [Validators.required, Validators.min(0)]),
    });
  }

  void _setupListeners() {
    _form.control('room_id').valueChanges.listen((roomId) {
      if (roomId != null && roomId is String) {
        final room = _availableRooms.cast<Room?>().firstWhere((r) => r?.id == roomId, orElse: () => null);
        if (room != null) {
          _form.control('room_rate').value = room.rate;
        }
      }
    });

    _form.control('room_rate').valueChanges.listen((_) => _calculateTotal());
    
    _form.control('check_in').valueChanges.listen((_) {
      _calculateTotal();
      _updateAvailableRooms();
    });
    
    _form.control('check_out').valueChanges.listen((_) {
      _calculateTotal();
      _updateAvailableRooms();
    });
  }

  void _updateAvailableRooms() {
    final checkIn = _form.control('check_in').value as DateTime?;
    final checkOut = _form.control('check_out').value as DateTime?;
    if (checkIn == null || checkOut == null) return;

    final overlappingBookingRoomIds = _allBookings.where((b) {
      // Ignore completed or cancelled bookings
      if (b.status == BookingStatus.checkedOut || b.status == BookingStatus.cancelled) return false;
      
      // Ignore the current booking being edited
      if (_existingBooking != null && b.id == _existingBooking!.id) return false;

      // Check date overlap
      return b.checkIn.isBefore(checkOut) && b.checkOut.isAfter(checkIn);
    }).map((b) => b.roomId).toSet();

    setState(() {
      _availableRooms = _allRooms.where((room) {
        if (overlappingBookingRoomIds.contains(room.id)) return false;
        // Optionally: if check-in is today, we could enforce room.status == RoomStatus.available
        // But to allow booking a room that's just "cleaning", we allow all rooms without overlaps.
        return true;
      }).toList();

      // Clear selected room if it's no longer available for the new dates
      final currentSelectedRoom = _form.control('room_id').value as String?;
      if (currentSelectedRoom != null && !_availableRooms.any((r) => r.id == currentSelectedRoom)) {
        _form.control('room_id').value = null;
        _form.control('room_rate').value = 0.0;
      }
    });
  }

  void _calculateTotal() {
    final checkIn = _form.control('check_in').value as DateTime?;
    final checkOut = _form.control('check_out').value as DateTime?;
    final roomRate = _form.control('room_rate').value as double?;

    if (checkIn != null && checkOut != null && roomRate != null) {
      final inDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
      final outDate = DateTime(checkOut.year, checkOut.month, checkOut.day);
      
      // Base nights difference
      int calculatedDays = outDate.difference(inDate).inDays;
      
      // If check-in is before 12:00 PM, charge an extra day (early check-in)
      if (checkIn.hour < 12) {
        calculatedDays += 1;
      }
      
      // If check-out is after 11:00 AM, charge an extra day (late check-out)
      // We check if it's strictly > 11:00. (So 11:00 is fine, 11:01 is late).
      if (checkOut.hour > 11 || (checkOut.hour == 11 && checkOut.minute > 0)) {
        calculatedDays += 1;
      }
      
      if (calculatedDays < 1) calculatedDays = 1; // Minimum 1 day charge
      
      _form.control('total_amount').value = calculatedDays * roomRate;
    }
  }

  Future<void> _loadData() async {
    // Load Rooms and Bookings
    _allRooms = await ref.read(roomsProvider(widget.hotelId).future);
    _allBookings = await ref.read(bookingsProvider(widget.hotelId).future);

    if (widget.bookingId != null && widget.bookingId != 'new') {
      _existingBooking = ref.read(bookingProvider((hotelId: widget.hotelId, bookingId: widget.bookingId!)));
      if (_existingBooking != null) {
        _existingCustomer = ref.read(customerProvider(_existingBooking!.customerId));
        
        // If editing, we also want to allow selecting the currently booked room
        final currentRoom = _allRooms.firstWhere((r) => r.id == _existingBooking!.roomId);
        if (!_availableRooms.any((r) => r.id == currentRoom.id)) {
          _availableRooms.add(currentRoom);
        }

        if (_existingCustomer != null) {
          final inDate = DateTime(_existingBooking!.checkIn.year, _existingBooking!.checkIn.month, _existingBooking!.checkIn.day);
          final outDate = DateTime(_existingBooking!.checkOut.year, _existingBooking!.checkOut.month, _existingBooking!.checkOut.day);
          int nights = outDate.difference(inDate).inDays;
          if (nights < 1) nights = 1;
          final calculatedRate = _existingBooking!.totalAmount / nights;

          _form.updateValue({
            'guest_name': _existingCustomer!.name,
            'dob': _existingCustomer!.dob,
            'phone': _existingCustomer!.phone,
            'email': _existingCustomer!.email,
            'parent_name': _existingCustomer!.parentName,
            'address': _existingCustomer!.address,
            'pincode': _existingCustomer!.pincode,
            'id_proof_type': _existingCustomer!.idProofType,
            'id_proof_number': _existingCustomer!.idProofNumber,
            'room_id': _existingBooking!.roomId,
            'room_rate': calculatedRate,
            'guests_count': _existingBooking!.guestsCount,
            'check_in': _existingBooking!.checkIn,
            'check_out': _existingBooking!.checkOut,
            'payment_mode': _existingBooking!.paymentMode,
            'total_amount': _existingBooking!.totalAmount,
          });
        }
      }
    }

    _updateAvailableRooms();
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(bool isIdProof) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (isIdProof) {
          _idProofImage = File(image.path);
        } else {
          _guestPhoto = File(image.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final value = _form.value;
      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) throw Exception("Not logged in");
      final currentUser = authState.user;

      // 1. Upload Images (if new)
      String? idUrl = _existingCustomer?.idProofUrl;
      String? photoUrl = _existingCustomer?.photoUrl;

      final customerRepo = ref.read(customerRepositoryProvider);

      if (_idProofImage != null) {
        final fileId = await customerRepo.uploadFile(
          AppwriteConstants.idProofsBucket, 
          _idProofImage!.path,
        );
        idUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.idProofsBucket}/files/$fileId/view?project=${AppwriteConstants.projectId}';
      }
      
      if (_guestPhoto != null) {
        final fileId = await customerRepo.uploadFile(
          AppwriteConstants.guestPhotosBucket, 
          _guestPhoto!.path,
        );
        photoUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.guestPhotosBucket}/files/$fileId/view?project=${AppwriteConstants.projectId}';
      }

      // 2. Save Customer
      final isNewCustomer = _existingCustomer == null;
      final customerData = isNewCustomer
          ? Customer.empty().copyWith(
              hotelId: widget.hotelId,
              name: value['guest_name'] as String,
              dob: value['dob'] as DateTime,
              phone: value['phone'] as String,
              email: value['email'] as String?,
              parentName: value['parent_name'] as String?,
              address: value['address'] as String,
              pincode: value['pincode'] as String,
              idProofType: value['id_proof_type'] as IdProofType,
              idProofNumber: value['id_proof_number'] as String,
              idProofUrl: idUrl,
              photoUrl: photoUrl,
            )
          : _existingCustomer!.copyWith(
              name: value['guest_name'] as String,
              dob: value['dob'] as DateTime,
              phone: value['phone'] as String,
              email: value['email'] as String?,
              parentName: value['parent_name'] as String?,
              address: value['address'] as String,
              pincode: value['pincode'] as String,
              idProofType: value['id_proof_type'] as IdProofType,
              idProofNumber: value['id_proof_number'] as String,
              idProofUrl: idUrl,
              photoUrl: photoUrl,
            );

      // Save customer to DB
      Customer savedCustomer;
      if (isNewCustomer) {
        savedCustomer = await ref.read(customersProvider.notifier).createCustomer(customerData);
      } else {
        await ref.read(customersProvider.notifier).updateCustomer(customerData);
        savedCustomer = customerData;
      }

      // 3. Save Booking
      final isNewBooking = _existingBooking == null;
      final bookingData = isNewBooking
          ? Booking.empty(hotelId: widget.hotelId).copyWith(
              roomId: value['room_id'] as String,
              customerId: savedCustomer.id,
              bookedByUserId: currentUser.userId,
              checkIn: value['check_in'] as DateTime,
              checkOut: value['check_out'] as DateTime,
              guestsCount: value['guests_count'] as int,
              paymentMode: value['payment_mode'] as PaymentMode,
              totalAmount: value['total_amount'] as double,
            )
          : _existingBooking!.copyWith(
              roomId: value['room_id'] as String,
              checkIn: value['check_in'] as DateTime,
              checkOut: value['check_out'] as DateTime,
              guestsCount: value['guests_count'] as int,
              paymentMode: value['payment_mode'] as PaymentMode,
              totalAmount: value['total_amount'] as double,
            );

      if (isNewBooking) {
        await ref.read(bookingsProvider(widget.hotelId).notifier).createBooking(bookingData);
        
        // Update Room Status
        final room = _availableRooms.firstWhere((r) => r.id == bookingData.roomId);
        await ref.read(roomsProvider(widget.hotelId).notifier).updateRoom(room.copyWith(status: RoomStatus.occupied));
      } else {
        await ref.read(bookingsProvider(widget.hotelId).notifier).updateBooking(bookingData);
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/hotels/${widget.hotelId}/bookings');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isNew = _existingBooking == null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Booking' : 'Edit Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ReactiveForm(
          formGroup: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Guest Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ReactiveTextField<String>(
                formControlName: 'guest_name',
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded)),
              ),
              const SizedBox(height: 16),
              
              ReactiveDateTimePicker(
                formControlName: 'dob',
                type: ReactiveDatePickerFieldType.date,
                decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake_rounded)),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ReactiveTextField<String>(
                      formControlName: 'phone',
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded)),
                      validationMessages: {
                        'required': (_) => 'Phone is required',
                        'pattern': (_) => 'Must be exactly 10 digits',
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReactiveTextField<String>(
                      formControlName: 'email',
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email (Optional)', prefixIcon: Icon(Icons.email_rounded)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ReactiveTextField<String>(
                formControlName: 'address',
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Full Address', prefixIcon: Icon(Icons.location_on_rounded)),
              ),
              const SizedBox(height: 16),

              ReactiveTextField<String>(
                formControlName: 'pincode',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop_rounded)),
                validationMessages: {
                  'required': (_) => 'Pincode is required',
                  'pattern': (_) => 'Must be exactly 6 digits',
                },
              ),
              const SizedBox(height: 24),

              Text('Documents', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ReactiveDropdownField<IdProofType>(
                formControlName: 'id_proof_type',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'ID Proof Type', prefixIcon: Icon(Icons.badge_rounded)),
                items: IdProofType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
              ),
              const SizedBox(height: 16),

              ReactiveTextField<String>(
                formControlName: 'id_proof_number',
                decoration: const InputDecoration(labelText: 'ID Proof Number', prefixIcon: Icon(Icons.numbers_rounded)),
                validationMessages: {
                  'required': (_) => 'ID proof number is required',
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(true),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(_idProofImage != null || _existingCustomer?.idProofUrl != null ? 'ID Proof Selected' : 'Upload ID Proof'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(_guestPhoto != null || _existingCustomer?.photoUrl != null ? 'Photo Selected' : 'Take Guest Photo'),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 48),

              Text('Stay Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              ReactiveDropdownField<String>(
                formControlName: 'room_id',
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Assign Room', 
                  prefixIcon: const Icon(Icons.meeting_room_rounded),
                  hintText: _availableRooms.isEmpty ? 'No available rooms. Please add a room first.' : null,
                ),
                items: _availableRooms.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.roomNumber} - ${r.type.displayName} (₹${r.rate})', overflow: TextOverflow.ellipsis))).toList(),
              ),
              const SizedBox(height: 16),

              ReactiveTextField<double>(
                formControlName: 'room_rate',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Room Rate (per night)', prefixIcon: Icon(Icons.price_change_rounded)),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ReactiveDateTimePicker(
                      formControlName: 'check_in',
                      type: ReactiveDatePickerFieldType.dateTime,
                      decoration: const InputDecoration(labelText: 'Check-in', prefixIcon: Icon(Icons.login_rounded)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReactiveDateTimePicker(
                      formControlName: 'check_out',
                      type: ReactiveDatePickerFieldType.dateTime,
                      decoration: const InputDecoration(labelText: 'Check-out', prefixIcon: Icon(Icons.logout_rounded)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ReactiveTextField<int>(
                      formControlName: 'guests_count',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Guests Count', prefixIcon: Icon(Icons.group_rounded)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReactiveDropdownField<PaymentMode>(
                      formControlName: 'payment_mode',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payment_rounded)),
                      items: PaymentMode.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ReactiveTextField<double>(
                formControlName: 'total_amount',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Total Amount (₹)', 
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  filled: true,
                ),
              ),

              const SizedBox(height: 32),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: Text(isNew ? 'Confirm Booking' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
