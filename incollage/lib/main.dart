import 'package:Incollage/views/start.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'states/star_pro_icons.dart';
import 'views/lists.dart';

import 'package:firebase_core/firebase_core.dart';
import 'views/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'views/main_editor_fotos.dart';
import 'views/main_editor_collage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solo en Android / iOS. En Web no se usa el plugin google_sign_in.
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: incollage,
      home: const AuthGate(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: AppPadding.paddingMd,

        // Botón PRO izquierdo
        title: Container(
          height: AppSpacing.spacing9,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing5),
          decoration: BoxDecoration(
            color: AppColors.info300,
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(StarPro.vector, color: AppColors.neutral900, size: 16),
              const SizedBox(width: AppSpacing.spacing2),
              Text('Prueba la versión pro 7 días', style: text.bodySmall),
            ],
          ),
        ),

        // actions
        actions: [
          // Tienda
          CircleAvatar(
            radius: AppSpacing.spacing5,
            backgroundColor: colors.surface,
            child: const Icon(Icons.storefront_outlined, size: 24),
          ),

          // Perfil
          const SizedBox(width: AppSpacing.spacing2),
          CircleAvatar(
            radius: AppSpacing.spacing5,
            backgroundColor: colors.primary,
            child: Icon(
              Icons.person_outline_outlined,
              color: colors.onPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: AppSpacing.spacing4),
        ],

        // Título Incollage
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing6,
              0,
              AppSpacing.spacing4,
              AppSpacing.spacing4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('InCollage', style: text.headlineLarge),
            ),
          ),
        ),
      ),

      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.spacing40),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
            ),

            // boton nueva composición
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StartView()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('NUEVA COMPOSICIÓN'),
              iconAlignment: IconAlignment.start,
            ),
          ),

          const SizedBox(height: AppSpacing.spacing40),

          // container gris
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: AppSpacing.spacing6,
              top: AppSpacing.spacing6,
              right: AppSpacing.spacing6,
              bottom: AppSpacing.spacing8,
            ),
            decoration: BoxDecoration(color: colors.primaryContainer),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // proyectos recientes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Proyectos recientes', style: text.bodyLarge),

                    // ver todos
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListsView(),
                          ),
                        );
                      },
                      child: Text(
                        'Ver todos',
                        style: text.labelSmall?.copyWith(
                          decoration: TextDecoration.underline,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.spacing6),

                // carrusel de imagenes
                SizedBox(
                  height: 100,
                  child: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, authSnapshot) {
                      if (authSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final usuarioLogueado = authSnapshot.data;

                      if (usuarioLogueado == null ||
                          usuarioLogueado.email == null) {
                        return Center(
                          child: Text(
                            'Cargando usuario...',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                        );
                      }

                      final correoUsuario = usuarioLogueado.email;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('imagenes')
                            .where('usuario', isEqualTo: correoUsuario)
                            .orderBy('fecha', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(
                                  color: AppColors.error500,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Aún no hay proyectos',
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.neutral700,
                                ),
                              ),
                            );
                          }

                          final documentos = snapshot.data!.docs;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: documentos.length,
                            itemBuilder: (context, index) {
                              final doc = documentos[index];
                              final data =
                                  doc.data() as Map<String, dynamic>;

                              final nombreArchivo =
                                  data['nombreArchivo'] ?? 'Sin nombre';
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

                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.spacing2,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    if (tipo == 'collage') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditorCollageScreen(
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
                                          builder: (context) =>
                                              EditorImagenScreen(
                                            urlInicial: urlImagen.isNotEmpty
                                                ? urlImagen
                                                : null,
                                            docId: doc.id,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 100,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: AppColors.neutral300,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.radiusLg,
                                      ),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        urlImagen.isNotEmpty
                                            ? Image.network(
                                                urlImagen,
                                                fit: BoxFit.cover,
                                                webHtmlElementStrategy:
                                                    WebHtmlElementStrategy.prefer,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: AppColors.neutral600,
                                                    ),
                                                  );
                                                },
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                color: AppColors.neutral600,
                                              ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  const Color.fromARGB(
                                                    150,
                                                    0,
                                                    0,
                                                    0,
                                                  ),
                                                ],
                                                stops: const [0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: AppSpacing.spacing2,
                                          left: AppSpacing.spacing2,
                                          right: AppSpacing.spacing2,
                                          child: Row(
                                            children: [
                                              Icon(
                                                tipo == 'collage'
                                                    ? Icons.grid_on
                                                    : Icons.image_outlined,
                                                size: 12,
                                                color: AppColors.neutral100,
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  nombreArchivo,
                                                  style: AppTypography.overline
                                                      .copyWith(
                                                        color:
                                                            AppColors.neutral100,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }
}