import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/domain/identity.dart';
import 'package:uuid/uuid.dart';

class IdentityFormScreen extends StatefulWidget {
  const IdentityFormScreen({super.key, this.identityId});

  final String? identityId;

  @override
  State<IdentityFormScreen> createState() => _IdentityFormScreenState();
}

class _IdentityFormScreenState extends State<IdentityFormScreen> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  IdentityType _type = IdentityType.custom;
  late int _colorValue;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.identityId != null;

  @override
  void initState() {
    super.initState();
    _colorValue = AppColors.identityCustom.toARGB32();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    if (!_isEdit) return;
    final identities = context.read<IdentitiesBloc>().state.identities;
    final existing =
        identities.where((e) => e.id == widget.identityId).firstOrNull;
    if (existing == null) return;
    _name.text = existing.name;
    _tagline.text = existing.tagline;
    setState(() {
      _type = existing.type;
      _colorValue = existing.colorValue;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit identity' : 'New identity'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: () {
                context
                    .read<IdentitiesBloc>()
                    .add(IdentitiesDeleteRequested(widget.identityId!));
                context.pop();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagline,
              decoration: const InputDecoration(hintText: 'Tagline (optional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<IdentityType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: IdentityType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _type = v;
                  _colorValue = v.color.toARGB32();
                });
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final now = DateTime.now().toUtc();
                if (_isEdit) {
                  final existing = context
                      .read<IdentitiesBloc>()
                      .state
                      .identities
                      .where((e) => e.id == widget.identityId)
                      .firstOrNull;
                  if (existing == null) return;
                  context.read<IdentitiesBloc>().add(
                        IdentitiesUpdateRequested(
                          existing.copyWith(
                            name: _name.text.trim(),
                            tagline: _tagline.text.trim(),
                            type: _type,
                            colorValue: _colorValue,
                            updatedAt: now,
                          ),
                        ),
                      );
                } else {
                  context.read<IdentitiesBloc>().add(
                        IdentitiesCreateRequested(
                          Identity(
                            id: const Uuid().v4(),
                            name: _name.text.trim(),
                            type: _type,
                            colorValue: _colorValue,
                            tagline: _tagline.text.trim(),
                            createdAt: now,
                            updatedAt: now,
                          ),
                        ),
                      );
                }
                context.pop();
              },
              child: Text(_isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
