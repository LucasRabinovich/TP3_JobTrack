import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  static const int chunkSize = 180 * 1024;
  static const int maxFileSize = 3 * 1024 * 1024;

  bool _busy = false;
  double _progress = 0;

  CollectionReference<Map<String, dynamic>> get _documents =>
      FirebaseFirestore.instance.collection('documents');

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _uploadCv() async {
    final uid = _userId;

    if (uid == null || _busy) return;

    DocumentReference<Map<String, dynamic>>? documentRef;
    bool documentCreated = false;

    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final Uint8List bytes = await file.xFile.readAsBytes();

      if (!file.name.toLowerCase().endsWith('.pdf')) {
        throw Exception('Seleccioná un archivo PDF.');
      }

      if (bytes.isEmpty || bytes.length > maxFileSize) {
        throw Exception(
          'El PDF debe tener un tamaño máximo de 3 MB.',
        );
      }

      if (bytes.length < 5 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw Exception('El archivo no es un PDF válido.');
      }

      if (!mounted) return;

      setState(() {
        _busy = true;
        _progress = 0;
      });

      final existing = await _documents
          .where('userId', isEqualTo: uid)
          .get();

      documentRef = _documents.doc();

      final totalChunks = (bytes.length / chunkSize).ceil();

      // PASO 1: crear el documento principal.
      await documentRef.set({
        'userId': uid,
        'name': file.name,
        'size': bytes.length,
        'chunkCount': totalChunks,
        'isPrimary': existing.docs.isEmpty,
        'createdAt': FieldValue.serverTimestamp(),
        'storageType': 'firestore',
        'type': 'cv',
      });

      documentCreated = true;

      // PASO 2: guardar los fragmentos.
      // Se usa un batch por fragmento para evitar
      // superar los límites de evaluación de reglas.
      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = min(start + chunkSize, bytes.length);

        final chunkBytes = Uint8List.fromList(
          bytes.sublist(start, end),
        );

        final chunkId = i.toString().padLeft(4, '0');

        await documentRef.collection('chunks').doc(chunkId).set({
          'data': Blob(chunkBytes),
          'index': i,
        });

        if (mounted) {
          setState(() {
            _progress = (i + 1) / totalChunks;
          });
        }
      }

      _showMessage('CV cargado correctamente.');
    } catch (e) {
      // Si falla la carga, intentar limpiar los
      // fragmentos y el documento incompleto.
      if (documentCreated && documentRef != null) {
        try {
          final chunks = await documentRef.collection('chunks').get();

          for (final chunk in chunks.docs) {
            await chunk.reference.delete();
          }

          await documentRef.delete();
        } catch (_) {
          // La limpieza puede fallar por permisos o red.
        }
      }

      _showMessage('Error al cargar CV: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _openCv(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final uid = _userId;

    if (uid == null || _busy) return;

    setState(() => _busy = true);

    try {
      final documentRef = _documents.doc(documentId);
      final document = await documentRef.get();

      if (!document.exists || document.data()?['userId'] != uid) {
        throw Exception('Documento no autorizado.');
      }

      final chunkCount =
          (document.data()?['chunkCount'] as num?)?.toInt() ?? 0;

      if (chunkCount <= 0 || chunkCount > 18) {
        throw Exception('Cantidad de fragmentos inválida.');
      }

      final builder = BytesBuilder(copy: false);

      for (int i = 0; i < chunkCount; i++) {
        final chunkId = i.toString().padLeft(4, '0');

        final snapshot = await documentRef
            .collection('chunks')
            .doc(chunkId)
            .get();

        if (!snapshot.exists) {
          throw Exception('Falta una parte del archivo PDF.');
        }

        final blob = snapshot.data()?['data'];

        if (blob is! Blob) {
          throw Exception(
            'No se pudo recuperar el contenido del PDF.',
          );
        }

        builder.add(blob.bytes);
      }

      final bytes = builder.takeBytes();

      final expectedSize =
          (document.data()?['size'] as num?)?.toInt();

      if (expectedSize != null && bytes.length != expectedSize) {
        throw Exception('El archivo descargado está incompleto.');
      }

      final directory = await getTemporaryDirectory();

      final pdfFile = File(
        '${directory.path}/jobtrack_cv_$documentId.pdf',
      );

      await pdfFile.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(pdfFile.path);

      if (result.type != ResultType.done) {
        throw Exception(
          'No se pudo abrir el PDF: ${result.message}',
        );
      }
    } catch (e) {
      _showMessage('Error al abrir CV: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setPrimary(String documentId) async {
    final uid = _userId;

    if (uid == null || _busy) return;

    setState(() => _busy = true);

    try {
      final documents = await _documents
          .where('userId', isEqualTo: uid)
          .get();

      if (!documents.docs.any((doc) => doc.id == documentId)) {
        throw Exception('El CV no pertenece a tu cuenta.');
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final document in documents.docs) {
        batch.update(document.reference, {
          'isPrimary': document.id == documentId,
        });
      }

      await batch.commit();

      _showMessage('CV principal actualizado.');
    } catch (e) {
      _showMessage('Error al cambiar CV principal: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteCv(String documentId) async {
    final uid = _userId;

    if (uid == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ELIMINAR CV'),
        content: const Text(
          '¿Querés eliminar este CV? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final documentRef = _documents.doc(documentId);
      final document = await documentRef.get();

      if (!document.exists || document.data()?['userId'] != uid) {
        throw Exception('Documento no autorizado.');
      }

      final wasPrimary = document.data()?['isPrimary'] == true;

      final chunks = await documentRef.collection('chunks').get();

      // Eliminar primero los fragmentos.
      for (final chunk in chunks.docs) {
        await chunk.reference.delete();
      }

      // Eliminar después el documento principal.
      await documentRef.delete();

      if (wasPrimary) {
        final remaining = await _documents
            .where('userId', isEqualTo: uid)
            .get();

        if (remaining.docs.isNotEmpty) {
          final primaryBatch = FirebaseFirestore.instance.batch();

          for (int i = 0; i < remaining.docs.length; i++) {
            primaryBatch.update(
              remaining.docs[i].reference,
              {'isPrimary': i == 0},
            );
          }

          await primaryBatch.commit();
        }
      }

      _showMessage('CV eliminado correctamente.');
    } catch (e) {
      _showMessage('Error al eliminar CV: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _buildDocumentCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final name = data['name']?.toString() ?? 'Documento PDF';
    final size = (data['size'] as num?)?.toInt() ?? 0;
    final isPrimary = data['isPrimary'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatSize(size)),
                  ],
                ),
              ),
            ],
          ),
          if (isPrimary) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              color: lime,
              child: const Text(
                'CV PRINCIPAL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _openCv(document.id, data),
                icon: const Icon(Icons.open_in_new),
                label: const Text('ABRIR'),
              ),
              if (!isPrimary)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _setPrimary(document.id),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('HACER PRINCIPAL'),
                ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _deleteCv(document.id),
                icon: const Icon(Icons.delete_outline),
                label: const Text('ELIMINAR'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _userId;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: lime,
        foregroundColor: Colors.black,
        title: const Text(
          'MIS DOCUMENTOS Y CV',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text('Iniciá sesión.'),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'MIS CURRÍCULUMS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cargá tus CV en PDF y elegí '
                    'cuál querés usar como principal. '
                    'Tamaño máximo: 3 MB.',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _uploadCv,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _busy
                          ? 'PROCESANDO...'
                          : '+ CARGAR NUEVO CV',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: Colors.black,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: _documents
                          .where('userId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error al cargar documentos:\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final documents = snapshot.data!.docs.toList();

                        documents.sort((a, b) {
                          final aDate =
                              a.data()['createdAt'] as Timestamp?;
                          final bDate =
                              b.data()['createdAt'] as Timestamp?;

                          return (bDate?.toDate() ?? DateTime(1970))
                              .compareTo(
                            aDate?.toDate() ?? DateTime(1970),
                          );
                        });

                        if (documents.isEmpty) {
                          return const Center(
                            child: Text(
                              'TODAVÍA NO CARGASTE NINGÚN CV',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            return _buildDocumentCard(
                              documents[index],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

