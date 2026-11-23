import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../theme/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: incollage,
      home: const EditorCollageScreen(),
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
  pomegranate,
  yellow,
}

enum TipoFormaMarco {
  cuadrado,
  circulo,
  corazon,
  estrella,
}

String _nombreFormaMarco(TipoFormaMarco forma) {
  switch (forma) {
    case TipoFormaMarco.cuadrado:
      return 'Cuadrado';
    case TipoFormaMarco.circulo:
      return 'Círculo';
    case TipoFormaMarco.corazon:
      return 'Corazón';
    case TipoFormaMarco.estrella:
      return 'Estrella';
  }
}

Path _crearPathForma(TipoFormaMarco forma, Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  switch (forma) {
    case TipoFormaMarco.cuadrado:
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(16),
        ),
      );
      break;

    case TipoFormaMarco.circulo:
      path.addOval(Rect.fromLTWH(0, 0, w, h));
      break;

    case TipoFormaMarco.corazon:
      path.moveTo(w * 0.5, h * 0.88);
      path.cubicTo(w * 0.1, h * 0.62, 0, h * 0.32, w * 0.25, h * 0.16);
      path.cubicTo(w * 0.38, h * 0.08, w * 0.47, h * 0.18, w * 0.5, h * 0.28);
      path.cubicTo(w * 0.53, h * 0.18, w * 0.62, h * 0.08, w * 0.75, h * 0.16);
      path.cubicTo(w, h * 0.32, w * 0.9, h * 0.62, w * 0.5, h * 0.88);
      path.close();
      break;

    case TipoFormaMarco.estrella:
      const int puntas = 5;
      final cx = w * 0.5;
      final cy = h * 0.52;
      final radioExterno = (w < h ? w : h) * 0.48;
      final radioInterno = radioExterno * 0.45;

      for (int i = 0; i < puntas * 2; i++) {
        final r = i.isEven ? radioExterno : radioInterno;
        final angulo = (i * pi / puntas) - (pi / 2);
        final x = cx + r * cos(angulo);
        final y = cy + r * sin(angulo);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      break;
  }

  return path;
}

/// Función separada que aplica recorte de forma y borde al widget del collage.
Widget construirMarcoConForma({
  required Widget child,
  required TipoFormaMarco forma,
  required Color colorBorde,
  required double grosorBorde,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final path = _crearPathForma(forma, size);

      return Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _FormaClipper(path),
            child: child,
          ),
          if (grosorBorde > 0)
            IgnorePointer(
              child: CustomPaint(
                painter: _BordeFormaPainter(
                  path: path,
                  color: colorBorde,
                  grosor: grosorBorde,
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _FormaClipper extends CustomClipper<Path> {
  final Path path;
  _FormaClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _FormaClipper oldClipper) => oldClipper.path != path;
}

class _BordeFormaPainter extends CustomPainter {
  final Path path;
  final Color color;
  final double grosor;

  _BordeFormaPainter({
    required this.path,
    required this.color,
    required this.grosor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BordeFormaPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.color != color ||
        oldDelegate.grosor != grosor;
  }
}

class EditorCollageScreen extends StatefulWidget {
  final List<String>? urlsIniciales;

  const EditorCollageScreen({
    super.key,
    this.urlsIniciales,
  });

  @override
  State<EditorCollageScreen> createState() => _EditorCollageScreenState();
}

class _EditorCollageScreenState extends State<EditorCollageScreen> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _imagenKey = GlobalKey();

  String _textoAgregado = '';
  Offset _posicionTexto = const Offset(50, 50);

  List<Uint8List> _imagenesBytes = [];
  List<String> _urlsImagenes = [];
  FiltroImagen _filtro = FiltroImagen.original;
  double _intensidad = 1;
  bool _guardando = false;
  String? _herramientaActiva;
  int _indiceSeleccionado = 0;

  TipoFormaMarco _formaMarco = TipoFormaMarco.cuadrado;
  Color _colorBordeMarco = Colors.white;
  double _grosorBordeMarco = 4.0;

  int get _totalElementos =>
      _imagenesBytes.isNotEmpty ? _imagenesBytes.length : _urlsImagenes.length;

  bool get _tieneCollageCargado => _totalElementos > 0;

  @override
  void initState() {
    super.initState();

    if (widget.urlsIniciales != null && widget.urlsIniciales!.isNotEmpty) {
      _urlsImagenes = List<String>.from(widget.urlsIniciales!);
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

  Widget _buildElementoPorIndice(int index) {
    if (_imagenesBytes.isNotEmpty) {
      return Image.memory(_imagenesBytes[index], fit: BoxFit.cover);
    }
    return Image.network(
      _urlsImagenes[index],
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }

  Widget _buildMiniaturaFiltro() {
    if (_imagenesBytes.isNotEmpty) {
      return Image.memory(_imagenesBytes.first, fit: BoxFit.cover);
    }
    return Image.network(
      _urlsImagenes.first,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }

  Future<void> _abrirImagen() async {
    try {
      final selecciones = await _picker.pickMultiImage(imageQuality: 95);

      if (selecciones.isEmpty) {
        if (mounted && !_tieneCollageCargado) {
          Navigator.pop(context);
        }
        return;
      }

      final listaBytes = <Uint8List>[];
      for (final xfile in selecciones) {
        listaBytes.add(await xfile.readAsBytes());
      }

      if (!mounted) return;

      setState(() {
        _imagenesBytes = listaBytes;
        _urlsImagenes = [];
        _filtro = FiltroImagen.original;
        _intensidad = 1;
      });
    } catch (e) {
      _mensaje('No se pudo abrir la imagen: $e');
    }
  }

  Future<List<String>> _obtenerUrlsIndividuales(
    int timestamp,
    String nombre,
  ) async {
    if (_imagenesBytes.isEmpty) {
      return List<String>.from(_urlsImagenes);
    }

    final urlsSubidas = <String>[];
    for (int i = 0; i < _imagenesBytes.length; i++) {
      final rutaItem = 'imagenes_collage/${timestamp}_${nombre}_$i.jpg';
      final refItem = FirebaseStorage.instance.ref(rutaItem);
      await refItem.putData(
        _imagenesBytes[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final urlItem = await refItem.getDownloadURL();
      urlsSubidas.add(urlItem);
    }
    return urlsSubidas;
  }

  Future<void> _guardarImagen() async {
    if (!_tieneCollageCargado || _guardando) return;

    final usuarioActual = FirebaseAuth.instance.currentUser;
    final correoUsuario = usuarioActual?.email ?? 'Correo no encontrado';
    final avatarUsuario = usuarioActual?.photoURL ?? '';

    final nombreController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Collage'),
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
            child: const Text('Guardar Collage'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final nombreIngresado = nombreController.text.trim();
    final nombre = nombreIngresado.isEmpty ? 'collage' : nombreIngresado;

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
      final urlsIndividuales =
          await _obtenerUrlsIndividuales(timestamp, nombre);

      await FirebaseFirestore.instance.collection('imagenes').add({
        'nombreArchivo': nombre,
        'usuario': correoUsuario,
        'avatarUsuario': avatarUsuario,
        'urlImagen': urlDescarga,
        'urlsImagenes': urlsIndividuales,
        'rutaStorage': rutaStorage,
        'fecha': FieldValue.serverTimestamp(),
        'tipo': 'collage',
      });

      _mensaje('Collage guardado y subido exitosamente');
    } catch (e) {
      _mensaje('Error al subir la imagen: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
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

  Future<void> _seleccionarMarco() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forma del marco',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: TipoFormaMarco.values.map((forma) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_nombreFormaMarco(forma)),
                            selected: _formaMarco == forma,
                            onSelected: (_) {
                              setState(() => _formaMarco = forma);
                              setModalState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Grosor',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _grosorBordeMarco,
                          min: 0,
                          max: 24,
                          divisions: 24,
                          label: '${_grosorBordeMarco.round()} px',
                          onChanged: (valor) {
                            setState(() => _grosorBordeMarco = valor);
                            setModalState(() {});
                          },
                        ),
                      ),
                      ...const [
                        Colors.white,
                        Colors.black,
                        Colors.pinkAccent,
                        Colors.cyan,
                      ].map(
                        (color) => GestureDetector(
                          onTap: () {
                            setState(() => _colorBordeMarco = color);
                            setModalState(() {});
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorBordeMarco == color
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                width: _colorBordeMarco == color ? 2.5 : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
        title: const Text('Crear Collage'),
        actions: [
          if (_tieneCollageCargado)
            IconButton(
              tooltip: 'Restablecer filtros y marco',
              onPressed: () => setState(() {
                _filtro = FiltroImagen.original;
                _intensidad = 1;
                _formaMarco = TipoFormaMarco.cuadrado;
                _colorBordeMarco = Colors.white;
                _grosorBordeMarco = 4.0;
              }),
              icon: const Icon(Icons.restart_alt),
            ),
          if (_tieneCollageCargado)
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
              child: !_tieneCollageCargado
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
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
                            construirMarcoConForma(
                              forma: _formaMarco,
                              colorBorde: _colorBordeMarco,
                              grosorBorde: _grosorBordeMarco,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.matrix(_matrizActual()),
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              _totalElementos > 4 ? 3 : 2,
                                          crossAxisSpacing: 4,
                                          mainAxisSpacing: 4,
                                        ),
                                    itemCount: _totalElementos,
                                    itemBuilder: (context, index) =>
                                        _buildElementoPorIndice(index),
                                  ),
                                ),
                              ),
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                !_tieneCollageCargado ? 'Abrir imagen' : 'Cambiar imagen',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !_tieneCollageCargado
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_herramientaActiva != null)
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                                                    child: _buildMiniaturaFiltro(),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _nombreFiltro(filtro),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimaryContainer,
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
                                        selectedColor: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        side: BorderSide(
                                          color: _filtro == filtro
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer,
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
      _escribirTexto();
    } else if (index == 2) {
      _seleccionarMarco();
    }
  },




                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.filter_vintage),
                      label: 'Filtro',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.text_fields),
                      label: 'Texto',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.rectangle_outlined),
                      label: 'Marcos',
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: !_tieneCollageCargado
          ? null
          : FloatingActionButton(
              onPressed: _abrirImagen,
              tooltip: 'Abrir otra imagen',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusLg),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined),
            ),
    );
  }
}