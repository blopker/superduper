import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:superduper/bike.dart';
import 'package:superduper/styles.dart';

show(BuildContext context, BikeState bike) {
  showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return BikeSettingsWidget(bike: bike);
      });
}

class BikeSettingsWidget extends ConsumerStatefulWidget {
  const BikeSettingsWidget({super.key, required this.bike});
  final BikeState bike;

  @override
  BikeSettingsWidgetState createState() => BikeSettingsWidgetState();
}

class BikeSettingsWidgetState extends ConsumerState<BikeSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white70,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            Text(
              'Edit Bike',
              style: Styles.header.copyWith(color: Colors.black),
            ),
            CompleteForm(bike: widget.bike),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class CompleteForm extends ConsumerStatefulWidget {
  const CompleteForm({Key? key, required this.bike}) : super(key: key);
  final BikeState bike;

  @override
  ConsumerState<CompleteForm> createState() {
    return _CompleteFormState();
  }
}

class _CompleteFormState extends ConsumerState<CompleteForm> {
  bool autoValidate = true;
  bool readOnly = false;
  bool showSegmentedControl = true;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _nameHasError = false;
  bool _modelHasError = false;

  var genderOptions = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    var bikeNotifier = ref.watch(bikeProvider(widget.bike.id).notifier);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          FormBuilder(
            key: _formKey,
            // enabled: false,
            onChanged: () {
              _formKey.currentState!.save();
              debugPrint(_formKey.currentState!.value.toString());
            },
            autovalidateMode: AutovalidateMode.disabled,
            initialValue: {
              'name': widget.bike.name,
              'region': widget.bike.region,
            },
            skipDisabled: true,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 15),
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.always,
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'Name',
                    suffixIcon: _nameHasError
                        ? const Icon(Icons.error, color: Colors.red)
                        : const Icon(Icons.check, color: Colors.green),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _nameHasError =
                          !(_formKey.currentState?.fields['name']?.validate() ??
                              false);
                    });
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  textInputAction: TextInputAction.next,
                ),
                FormBuilderDropdown<BikeRegion>(
                  name: 'region',
                  decoration: InputDecoration(
                    labelText: 'Region',
                    suffix: _modelHasError
                        ? const Icon(Icons.error)
                        : const Icon(Icons.check),
                    hintText: 'Region',
                  ),
                  validator: FormBuilderValidators.compose(
                      [FormBuilderValidators.required()]),
                  items: BikeRegion.values
                      .map((region) => DropdownMenuItem(
                            alignment: AlignmentDirectional.center,
                            value: region,
                            child: Text(region.value),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _modelHasError = !(_formKey.currentState?.fields['region']
                              ?.validate() ??
                          false);
                    });
                  },
                ),
              ],
            ),
          ),
          // Expanded(child: Container()),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      debugPrint(_formKey.currentState?.value.toString());
                      bikeNotifier.writeStateData(
                          widget.bike.copyWith(
                              name: _formKey.currentState?.value['name'],
                              region: _formKey.currentState?.value['region']),
                          saveToBike: false);
                      Navigator.pop(context);
                    } else {
                      debugPrint(_formKey.currentState?.value.toString());
                      debugPrint('validation failed');
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    Navigator.pop(context);
                  },
                  // color: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    'Reset',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
