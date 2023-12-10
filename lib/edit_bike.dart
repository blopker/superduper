import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:superduper/bike.dart';

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
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                Text(
                  'Edit Bike',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                    ))
              ],
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
  const CompleteForm({super.key, required this.bike});
  final BikeState bike;

  @override
  ConsumerState<CompleteForm> createState() {
    return _CompleteFormState();
  }
}

class _CompleteFormState extends ConsumerState<CompleteForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  var genderOptions = ['Male', 'Female', 'Other'];

  Future<bool?> _showMyDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
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
              child: const Text('Delete'),
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
    var bikeNotifier = ref.watch(bikeProvider(widget.bike.id).notifier);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          FormBuilder(
            key: _formKey,
            onChanged: () {
              _formKey.currentState!.save();
              debugPrint(_formKey.currentState!.value.toString());
            },
            autovalidateMode: AutovalidateMode.disabled,
            initialValue: {
              'name': widget.bike.name,
              'region': widget.bike.region,
            },
            child: Column(
              children: <Widget>[
                const SizedBox(height: 15),
                FormBuilderTextField(
                  name: 'name',
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 15),
                FormBuilderDropdown<BikeRegion>(
                  name: 'region',
                  decoration: const InputDecoration(
                    labelText: 'Region',
                  ),
                  validator: FormBuilderValidators.compose(
                      [FormBuilderValidators.required()]),
                  items: BikeRegion.values
                      .map((region) => DropdownMenuItem(
                            value: region,
                            child: Text(region.value),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  child: Text(
                    'Delete',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Colors.red),
                  ),
                  onTap: () async {
                    if (await _showMyDialog() ?? false) {
                      bikeNotifier.deleteStateData(widget.bike);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
              InkWell(
                child: Text(
                  'Save',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () {
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
