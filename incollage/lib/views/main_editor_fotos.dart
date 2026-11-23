import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart' as crop_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';

import '../theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: incollage,
      home: const EditorImagenScreen(),
    );
  }
}

enum FiltroImagen {
  original,
  blancoNegro,
  sepia,
  calido,
  frio,
  vintage,
  nightcity,
  popSTAR,
  yellow,
  pomegranate,
}

class EditorImagenScreen extends StatefulWidget {
  final String? urlInicial;
  final String? docId;

  const EditorImagenScreen({
    super.key,
    this.urlInicial,
    this.docId,
  });

  @override
  State<EditorImagenScreen> createState() => _EditorImagenScreenState();
}

class _EditorImagenScreenState extends State<EditorImagenScreen> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _imagenKey = GlobalKey();

  String _textoAgregado = '';
  Offset _posicionTexto = const Offset(50, 50);

  Uint8List? _imagenBytes;
  String? _imagenPathLocal;
  String? _urlImagen;
  FiltroImagen _filtro = FiltroImagen.original;
  double _intensidad = 1;
  bool _guardando = false;
  String? _herramientaActiva;


 int _indiceSeleccionado = 0;


  bool get _tieneImagenCargada =>
      _imagenBytes != null || (_urlImagen != null && _urlImagen!.isNotEmpty);

  @override
  void initState() {
    super.initState();

    if (widget.urlInicial != null && widget.urlInicial!.isNotEmpty) {
      _urlImagen = widget.urlInicial;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirImagen();
      });
    }
  }

  static const _identidad = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  List<double> _matrizFiltro(FiltroImagen filtro) {
    switch (filtro) {
      case FiltroImagen.original:
        return _identidad;
      case FiltroImagen.blancoNegro:
        return [
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.sepia:
        return [
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.calido:
        return [
          1.12, 0, 0, 0, 8,
          0, 1.02, 0, 0, 0,
          0, 0, 0.88, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.frio:
        return [
          0.90, 0, 0, 0, 0,
          0, 1.02, 0, 0, 0,
          0, 0, 1.16, 0, 8,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.vintage:
        return [
          0.85, 0.18, 0.08, 0, 8,
          0.10, 0.86, 0.08, 0, 4,
          0.08, 0.14, 0.72, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.nightcity:
        return [
          0.8, 0.4, -0.6, 0, 30,
          -0.4, 0.8, 0.4, 0, 10,
          -0.6, -0.2, 1.6, 0, 80,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.popSTAR:
        return [
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          1, 0, 0, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.yellow:
        return [
          1.5, 0.3, 0, 0, 40,
          0.1, 1.2, 0.1, 0, 10,
          -0.2, -0.2, 1.3, 0, -20,
          0, 0, 0, 1, 0,
        ];
      case FiltroImagen.pomegranate:
        return [
          1.5, 0, 0, 0, 0,
          0, 0.3, 0, 0, 0,
          0, 0, 0.3, 0, 0,
          0, 0, 0, 1, 0,
        ];
    }
  }

  List<double> _matrizActual() {
    final destino = _matrizFiltro(_filtro);
    return List.generate(
      20,
      (i) => _identidad[i] + (destino[i] - _identidad[i]) * _intensidad,
    );
  }

  String _nombreFiltro(FiltroImagen filtro) {
    switch (filtro) {
      case FiltroImagen.original:
        return 'Original';
      case FiltroImagen.blancoNegro:
        return 'B/N';
      case FiltroImagen.sepia:
        return 'Sepia';
      case FiltroImagen.calido:
        return 'Cálido';
      case FiltroImagen.frio:
        return 'Frío';
      case FiltroImagen.vintage:
        return 'Vintage';
      case FiltroImagen.nightcity:
        return 'nightcity';
      case FiltroImagen.popSTAR:
        return 'popSTAR';
      case FiltroImagen.yellow:
        return 'yellow';
      case FiltroImagen.pomegranate:
        return 'pomegranate';
    }
  }

  Widget _buildImagenBase({BoxFit fit = BoxFit.contain}) {
    if (_imagenBytes != null) {
      return Image.memory(_imagenBytes!, fit: fit);
    }
    if (_urlImagen != null && _urlImagen!.isNotEmpty) {
      return Image.network(
        _urlImagen!,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _abrirImagen() async {
    try {
      final XFile? seleccion = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (seleccion == null) {
        if (mounted && !_tieneImagenCargada) {
          Navigator.pop(context);
        }
        return;
      }

      final bytes = await seleccion.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagenBytes = bytes;
        _imagenPathLocal = kIsWeb ? null : seleccion.path;
        _urlImagen = null;
        _filtro = FiltroImagen.original;
        _intensidad = 1;
      });
    } catch (e) {
      _mensaje('No se pudo abrir la imagen: $e');
    }
  }

  Future<void> _recortarEnChromeWeb() async {
    if (_imagenBytes == null) return;

    final cropController = crop_lib.CropController();
    bool recortando = false;

    final Uint8List? resultado = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Recortar imagen'),
              content: SizedBox(
                width: 420,
                height: 360,
                child: crop_lib.Crop(
                  controller: cropController,
                  image: _imagenBytes!,
                  onCropped: (croppedData) {
                    if (Navigator.of(dialogContext).canPop()) {
                      Navigator.of(dialogContext).pop(croppedData);
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: recortando
                      ? null
                      : () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: recortando
                      ? null
                      : () {
                          setModalState(() => recortando = true);
                          cropController.crop();
                        },
                  child: recortando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aplicar recorte'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != null && mounted) {
      setState(() {
        _imagenBytes = resultado;
        _urlImagen = null;
      });
      _mensaje('Imagen recortada');
    }
  }

  Future<void> _recortarImagen() async {
    if (_imagenBytes == null) {
      _mensaje('Selecciona una imagen desde galería para recortarla');
      return;
    }

    if (kIsWeb) {
      await _recortarEnChromeWeb();
      return;
    }

    if (_imagenPathLocal == null) {
      _mensaje('No se encontró la ruta local de la imagen');
      return;
    }

    final imagenRecortada = await ImageCropper().cropImage(
      sourcePath: _imagenPathLocal!,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar Imagen',
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
        ),
        IOSUiSettings(title: 'Recortar Imagen'),
      ],
    );

    if (imagenRecortada != null) {
      final bytesRecortados = await imagenRecortada.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imagenBytes = bytesRecortados;
        _imagenPathLocal = imagenRecortada.path;
        _urlImagen = null;
      });
    }
  }

  Future<void> _escribirTexto() async {
    String textoTemporal = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar texto'),
        content: TextField(
          autofocus: true,
          onChanged: (valor) => textoTemporal = valor,
          decoration: const InputDecoration(hintText: 'Escribe algo...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _textoAgregado = textoTemporal;
              });
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarImagen() async {
    if (!_tieneImagenCargada || _guardando) return;

    final usuarioActual = FirebaseAuth.instance.currentUser;
    final correoUsuario = usuarioActual?.email ?? 'Correo no encontrado';
    final avatarUsuario = usuarioActual?.photoURL ?? '';

    final nombreController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre de archivo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar Imagen'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final nombreIngresado = nombreController.text.trim();
    final nombre = nombreIngresado.isEmpty ? 'imagen_editada' : nombreIngresado;

    setState(() => _guardando = true);

    try {
      final boundary =
          _imagenKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Imagen no disponible');

      final ui.Image imagen = await boundary.toImage(pixelRatio: 2);
      final ByteData? datos = await imagen.toByteData(
        format: ui.ImageByteFormat.png,
      );
      imagen.dispose();

      if (datos == null) throw Exception('No se pudo generar el PNG');

      final bytes = datos.buffer.asUint8List();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rutaStorage = 'imagenes_editadas/${timestamp}_$nombre.png';
      final referencia = FirebaseStorage.instance.ref(rutaStorage);

      await referencia.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );

      final urlDescarga = await referencia.getDownloadURL();

      await FirebaseFirestore.instance.collection('imagenes').add({
        'nombreArchivo': nombre,
        'usuario': correoUsuario,
        'avatarUsuario': avatarUsuario,
        'urlImagen': urlDescarga,
        'rutaStorage': rutaStorage,
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'imagen',
      });

      _mensaje('Imagen guardada y subida exitosamente');
    } catch (e) {
      _mensaje('Error al subir la imagen: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Editar foto'),
        actions: [
          if (_tieneImagenCargada)
            IconButton(
              tooltip: 'Restablecer filtros',
              onPressed: () => setState(() {
                _filtro = FiltroImagen.original;
                _intensidad = 1;
              }),
              icon: const Icon(Icons.restart_alt),
            ),
          if (_tieneImagenCargada)
            IconButton(
              tooltip: 'Guardar imagen editada',
              onPressed: _guardando ? null : _guardarImagen,
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        children: [
          const SizedBox(height: AppSpacing.spacing16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 350,
              width: double.infinity,
              child: !_tieneImagenCargada
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 72,
                            color: colores.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.spacing16),
                        ],
                      ),
                    )
                  : Center(
                      child: RepaintBoundary(
                        key: _imagenKey,
                        child: Stack(
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.matrix(_matrizActual()),
                              child: _buildImagenBase(fit: BoxFit.contain),
                            ),
                            if (_textoAgregado.isNotEmpty)
                              Positioned(
                                left: _posicionTexto.dx,
                                top: _posicionTexto.dy,
                                child: GestureDetector(
                                  onPanUpdate: (detalles) {
                                    setState(() {
                                      _posicionTexto += detalles.delta;
                                    });
                                  },
                                  child: Text(
                                    _textoAgregado,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          offset: const Offset(2.0, 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _abrirImagen,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                !_tieneImagenCargada ? 'Abrir imagen' : 'Cambiar imagen',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !_tieneImagenCargada
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_herramientaActiva != null)
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    height: _herramientaActiva == 'filtros' ? 230 : 110,
                    child: _herramientaActiva == 'filtros'
                        ? Column(
                            children: [
                              SizedBox(
                                height: 125,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: FiltroImagen.values.map((filtro) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ChoiceChip(
                                        showCheckmark: false,
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                              vertical: 2.0,
                                            ),
                                        label: SizedBox(
                                          width: 60,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: ColorFiltered(
                                                    colorFilter:
                                                        ColorFilter.matrix(
                                                          _matrizFiltro(filtro),
                                                        ),
                                                    child: _buildImagenBase(
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _nombreFiltro(filtro),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontSize: 11,
                                                  fontWeight: _filtro == filtro
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        selected: _filtro == filtro,
                                        selectedColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        side: BorderSide(
                                          color: _filtro == filtro
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                        ),
                                        onSelected: (_) => setState(() {
                                          _filtro = filtro;
                                          _intensidad = 1;
                                        }),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (_filtro != FiltroImagen.original) ...[
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Intensidad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${(_intensidad * 100).round()} %',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _intensidad,
                                  min: 0,
                                  max: 1,
                                  divisions: 20,
                                  label: '${(_intensidad * 100).round()} %',
                                  onChanged: (valor) =>
                                      setState(() => _intensidad = valor),
                                ),
                              ],
                            ],
                          )
                        : Center(
                            child: Text(
                              'Panel de ${_herramientaActiva?.toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                
                
                
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  selectedIconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.primary,
                    ),

                  
                 currentIndex: _indiceSeleccionado,
                    onTap: (index) {
                         setState(() {
                        _indiceSeleccionado = index;
                        if (index == 0) {
                         _herramientaActiva =
                           _herramientaActiva == 'filtros' ? null : 'filtros';
                          } else if (index == 1) {
                            _herramientaActiva = null;
                              } else if (index == 2) {
                                 _herramientaActiva = null;
                                                       }
                                                         });

                                       if (index == 1) {
                                          _recortarImagen();
                                          } else if (index == 2) {
                                           _escribirTexto();
                                               }
                                             },


                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.filter_vintage),
                      label: 'Filtro',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.crop),
                      label: 'Recortar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.text_fields),
                      label: 'Texto',
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: !_tieneImagenCargada
          ? null
          : FloatingActionButton(
              onPressed: _abrirImagen,
              tooltip: 'Abrir otra imagen',
              child: const Icon(Icons.add_photo_alternate_outlined),
     
     
         ),
    );
  }
}