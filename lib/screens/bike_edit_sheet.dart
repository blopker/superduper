import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:superduper/colors.dart';
import 'package:superduper/models/bike_model.dart';
import 'package:superduper/models/bike_region.dart';
import 'package:superduper/services/bike_repository.dart';

/// A bottom sheet for editing bike settings.
/// 
/// This presents a form that allows users to edit bike properties like name, 
/// region, color, and auto-connect status.
class BikeEditBottomSheet extends ConsumerStatefulWidget {
  final BikeModel bike;

  const BikeEditBottomSheet({super.key, required this.bike});

  /// Shows the bike edit bottom sheet.
  static Future<BikeModel?> show(BuildContext context, BikeModel bike) async {
    return await showModalBottomSheet<BikeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BikeEditBottomSheet(bike: bike),
    );
  }

  @override
  BikeEditBottomSheetState createState() => BikeEditBottomSheetState();
}

class BikeEditBottomSheetState extends ConsumerState<BikeEditBottomSheet> {
  @override
  Widget build(BuildContext context) {
    // Get the keyboard inset to adjust for keyboard appearance
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      // Use the height constraint to make the modal fill only part of the screen
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Padding(
          // Add bottom padding equal to keyboard height when keyboard is visible
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Modal draggable indicator
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      'Edit Bike',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Make the form scrollable when keyboard appears
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        _BikeEditForm(bike: widget.bike),
                        // Add bottom spacing for better scrolling
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BikeEditForm extends ConsumerStatefulWidget {
  const _BikeEditForm({required this.bike});
  final BikeModel bike;

  @override
  ConsumerState<_BikeEditForm> createState() => _BikeEditFormState();
}

class _BikeEditFormState extends ConsumerState<_BikeEditForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late int _selectedColorIndex;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _selectedColorIndex = widget.bike.color;
    _isActive = widget.bike.isActive;
  }

  Future<bool?> _showDeleteConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Delete Bike'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'This will delete ${widget.bike.name} from your list.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text('Continue?',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = getColorList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FormBuilder(
            key: _formKey,
            onChanged: () {
              _formKey.currentState!.save();
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            initialValue: {
              'name': widget.bike.name,
              'region': widget.bike.region,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Name field
                FormBuilderTextField(
                  name: 'name',
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800]!.withAlpha(102),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 24),

                // Region dropdown
                FormBuilderDropdown<BikeRegion>(
                  name: 'region',
                  decoration: InputDecoration(
                    labelText: 'Region',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800]!.withAlpha(102),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  validator: FormBuilderValidators.compose(
                      [FormBuilderValidators.required()]),
                  items: BikeRegion.values
                      .map((region) => DropdownMenuItem(
                            value: region,
                            child: Text(region.name),
                          ))
                      .toList(),
                  dropdownColor: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  iconSize: 24,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                // Auto-connect switch
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[800]!.withAlpha(102),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Auto-Connect',
                      style: TextStyle(
                        color: Colors.grey[200],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Connect when app starts',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    value: _isActive,
                    activeColor: const Color(0xff441DFC),
                    onChanged: (bool value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Color section
                Text(
                  'Bike Color',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Colors.grey[400],
                      ),
                ),

                const SizedBox(height: 12),

                // Color picker button
                InkWell(
                  onTap: () async {
                    var colorIndex =
                        await _showColorPicker(context, _selectedColorIndex);
                    setState(() {
                      _selectedColorIndex = colorIndex;
                    });
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          colors[_selectedColorIndex].start,
                          colors[_selectedColorIndex].end,
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        colors[_selectedColorIndex].name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors[_selectedColorIndex].fontColor(),
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delete button
              ElevatedButton.icon(
                onPressed: () async {
                  if (await _showDeleteConfirmation() ?? false) {
                    await ref.read(bikeRepositoryProvider).deleteBike(widget.bike.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              // Save button
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final updatedBike = widget.bike.copyWith(
                      name: _formKey.currentState?.value['name'],
                      color: _selectedColorIndex,
                      region: _formKey.currentState?.value['region'],
                      isActive: _isActive,
                    );
                    Navigator.pop(context, updatedBike);
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff441DFC).withOpacity(0.2),
                  foregroundColor: const Color(0xff441DFC),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<int> _showColorPicker(BuildContext context, int currentIndex) async {
  final colors = getColorList();
  final answer = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modal draggable indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Select Bike Color',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Color grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: colors.length,
                itemBuilder: (BuildContext context, int index) {
                  final color = colors[index];
                  final textColor = color.fontColor();
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context, index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              color.start,
                              color.end,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          boxShadow: [
                            if (index == currentIndex)
                              BoxShadow(
                                color: Colors.white.withAlpha(51),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            if (index == currentIndex)
                              Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: textColor,
                                  size: 28,
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Text(
                                colors[index].name,
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
  );
  if (answer != null) {
    return answer;
  }
  return currentIndex;
}