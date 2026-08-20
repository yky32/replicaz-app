import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/contacts/bloc/contacts_bloc.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:uuid/uuid.dart';

class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key, this.contactId, this.initialName});

  final String? contactId;
  final String? initialName;

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _notes = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.contactId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isEdit) {
        final seed = widget.initialName?.trim();
        if (seed != null && seed.isNotEmpty && mounted) {
          _name.text = seed;
        }
        return;
      }
      final contact =
          await AppBootstrap.contactService.getById(widget.contactId!);
      if (contact == null || !mounted) return;
      _name.text = contact.name;
      _email.text = contact.email;
      _phone.text = contact.phone;
      _company.text = contact.company;
      _notes.text = contact.notes;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit contact' : 'New contact'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: () {
                context
                    .read<ContactsBloc>()
                    .add(ContactsDeleteRequested(widget.contactId!));
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
              controller: _company,
              decoration: const InputDecoration(hintText: 'Company'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(hintText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Context notes'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final activeId =
                    context.read<IdentitiesBloc>().state.activeIdentityId;
                final contactsBloc = context.read<ContactsBloc>();
                final now = DateTime.now().toUtc();
                final existing = _isEdit
                    ? await AppBootstrap.contactService.getById(widget.contactId!)
                    : null;
                if (!context.mounted) return;
                // Edits stay on the original identity — never reassign on switch.
                final identityId =
                    existing?.identityId ?? activeId;
                if (identityId == null) return;
                contactsBloc.add(
                  ContactsSaveRequested(
                    Contact(
                      id: existing?.id ?? const Uuid().v4(),
                      identityId: identityId,
                      name: _name.text.trim(),
                      email: _email.text.trim(),
                      phone: _phone.text.trim(),
                      company: _company.text.trim(),
                      notes: _notes.text.trim(),
                      createdAt: existing?.createdAt ?? now,
                      updatedAt: now,
                      dirty: true,
                    ),
                  ),
                );
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
