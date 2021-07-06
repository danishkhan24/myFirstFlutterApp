import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flashlight/flutter_flashlight.dart';
import 'package:flutter/cupertino.dart';

class PicturePage extends StatefulWidget {
  @override
  _PicturePageState createState() {
    return _PicturePageState();
  }
}

class _PicturePageState extends State {
  bool _hasFlashlight = false;
  bool _flashOn = false;
  CameraController controller;
  List cameras;
  int selectedCameraIdx;
  Icon _flashIcon = Icon(Icons.flash_off);

  @override
  initState() {
    super.initState();

    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIdx = 1;
        });

        _initCameraController(cameras[selectedCameraIdx]).then((void v) {});
      } else {
        print("No camera available");
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });

    initFlashlight();
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final xScale = controller.value.aspectRatio / deviceRatio;
// Modify the yScale if you are in Landscape
    final yScale = 1.0;
    return Container(
      child: AspectRatio(
        aspectRatio: deviceRatio,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(xScale, yScale, 1),
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  initFlashlight() async {
    bool hasFlash = await Flashlight.hasFlashlight;
    print("Device has flash ? $hasFlash");
    setState(() {
      _hasFlashlight = hasFlash;
    });
  }

  void _flashLightController() {
    print(_hasFlashlight);
    if (_hasFlashlight) {
      if (_flashOn) {
        controller.setFlashMode(FlashMode.off);
        // Flashlight.lightOff();
        _flashOn = false;
        setState(() {
          _flashIcon = Icon(Icons.flash_off);
        });
      } else {
        controller.setFlashMode(FlashMode.torch);
        // Flashlight.lightOn();
        _flashOn = true;
        setState(() {
          _flashIcon = Icon(Icons.flash_on);
        });
      }
    }
  }

  Widget _flashLightButton(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Align(
          alignment: Alignment.bottomCenter,
          child: FloatingActionButton(
            onPressed: () {
              _flashLightController();
              if (!_hasFlashlight) {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Hardware Error'),
                    content: const Text('Flashlight not Detected!'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Okay'),
                      ),
                    ],
                  ),
                );
              }
            },
            backgroundColor: Colors.white.withOpacity(0.5),
            child: _flashIcon,
          )),
      SizedBox(
        height: 30,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        _cameraPreviewWidget(),
        Align(
            alignment: Alignment.bottomCenter,
            child: _flashLightButton(context)),
      ],
    ));
  }
}
