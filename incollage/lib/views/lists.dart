import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../theme/theme.dart';
import 'main_editor_fotos.dart';
import 'main_editor_collage.dart';

class ListsView extends StatefulWidget {
  const ListsView({super.key});

  @override
  State<ListsView> createState() => _ListsViewState();
}

class _ListsViewState extends State<ListsView> {
  final TextEditingController _busquedaController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _renombrarProyecto(
    BuildContext context,
    DocumentReference docRef,
    String nombreActual,
  ) async {
    final controller = TextEditingController(text: nombreActual);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
          ),
          onSubmitted: (valor) => Navigator.pop(dialogContext, valor.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (nuevoNombre == null ||
        nuevoNombre.isEmpty ||
        nuevoNombre == nombreActual) {
      return;
    }

    try {
      await docRef.update({'nombreArchivo': nuevoNombre});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Error al cambiar nombre: $e')));
    }
  }

  Future<void> _borrarProyecto(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String nombreArchivo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar proyecto'),
        content: Text('¿Seguro que quieres borrar "$nombreArchivo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final data = doc.data() as Map<String, dynamic>?;
    final rutaStorage = data?['rutaStorage'] as String?;

    try {
      if (rutaStorage != null && rutaStorage.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(rutaStorage).delete();
        } catch (_) {}
      }

      await doc.reference.delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Proyecto eliminado')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Error al borrar proyecto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // app bar
      appBar: AppBar(
        backgroundColor: colors.primary,
        iconTheme: IconThemeData(
          color: colors.onPrimary,
        ),
        title: Text(
          'Proyectos recientes',
          style: text.bodyLarge?.copyWith(
            color: colors.onPrimary,
          ),
        ),
        actions: [
          CircleAvatar(
            radius: AppSpacing.spacing5,
            backgroundColor: colors.primary,
            child: Icon(
              Icons.account_circle_outlined,
              color: colors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
        ],
      ),

      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.paddingSm,
              vertical: AppSpacing.spacing3,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                    child: TextField(
                      controller: _busquedaController,
                      onChanged: (valor) {
                        setState(() {
                          _textoBusqueda = valor.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar proyecto...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.neutral800,
                          size: 20,
                        ),
                        suffixIcon: _textoBusqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.neutral800,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _busquedaController.clear();
                                  setState(() {
                                    _textoBusqueda = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing2),

                // Icono de ajustes
                IconButton(
                  icon: const Icon(
                    Icons.tune,
                    color: AppColors.neutral900,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

         
          Expanded(
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarioLogueado = authSnapshot.data;
                if (usuarioLogueado == null || usuarioLogueado.email == null) {
                  return Center(
                    child: Text(
                      'Cargando usuario...',
                      style: text.bodyMedium?.copyWith(color: AppColors.neutral700),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('imagenes')
                      .where('usuario', isEqualTo: usuarioLogueado.email)
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error500, fontSize: 10),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay proyectos guardados.',
                          style: text.bodyMedium?.copyWith(color: AppColors.neutral700),
                        ),
                      );
                    }

                    final documentos = snapshot.data!.docs.where((doc) {
                      if (_textoBusqueda.isEmpty) return true;
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = (data['nombreArchivo'] ?? '')
                          .toString()
                          .toLowerCase();
                      return nombre.contains(_textoBusqueda);
                    }).toList();

                    if (documentos.isEmpty) {
                      return Center(
                        child: Text(
                          'No se encontraron proyectos con "$_textoBusqueda".',
                          style: text.bodyMedium?.copyWith(color: AppColors.neutral700),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.spacing2,
                      ),
                      itemCount: documentos.length,
                      itemBuilder: (context, index) {
                        final doc = documentos[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final nombreArchivo = data['nombreArchivo'] ?? 'Sin nombre';
                        final urlImagen = data['urlImagen'] ?? '';
                        final tipo = data['tipo'] ?? 'imagen';

                        final urlsGuardadas =
                            (data['urlsImagenes'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .where((u) => u.isNotEmpty)
                                    .toList() ??
                                (urlImagen.isNotEmpty
                                    ? [urlImagen]
                                    : <String>[]);

                        String fechaTexto = '';
                        if (data['fecha'] != null) {
                          final fecha = (data['fecha'] as Timestamp).toDate();
                          final dia = fecha.day.toString().padLeft(2, '0');
                          final mes = fecha.month.toString().padLeft(2, '0');
                          final hora = fecha.hour.toString().padLeft(2, '0');
                          final minuto = fecha.minute.toString().padLeft(2, '0');
                          fechaTexto = '$dia/$mes/${fecha.year} $hora:$minuto';
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacing4,
                            vertical: AppSpacing.spacing2,
                          ),
                          onTap: () {
                            if (tipo == 'collage') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditorCollageScreen(
                                    urlsIniciales: urlsGuardadas.isNotEmpty
                                        ? urlsGuardadas
                                        : null,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditorImagenScreen(
                                    urlInicial: urlImagen.isNotEmpty
                                        ? urlImagen
                                        : null,
                                    docId: doc.id,
                                  ),
                                ),
                              );
                            }
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                            child: SizedBox(
                              width: AppSpacing.spacing12,
                              height: AppSpacing.spacing12,
                              child: urlImagen.isNotEmpty
                                  ? Image.network(
                                      urlImagen,
                                      fit: BoxFit.cover,
                                      webHtmlElementStrategy:
                                          WebHtmlElementStrategy.prefer,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        Icons.broken_image_outlined,
                                        color: AppColors.neutral700,
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/PREV.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nombreArchivo,
                                  style: text.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.spacing2),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _renombrarProyecto(
                                  context,
                                  doc.reference,
                                  nombreArchivo.toString(),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.border_color_outlined,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            fechaTexto,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (opcion) {
                              if (opcion == 'renombrar') {
                                _renombrarProyecto(
                                  context,
                                  doc.reference,
                                  nombreArchivo.toString(),
                                );
                              } else if (opcion == 'borrar') {
                                _borrarProyecto(
                                  context,
                                  doc,
                                  nombreArchivo.toString(),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'renombrar',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Cambiar nombre'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'borrar',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Borrar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}