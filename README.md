# custom_image_crop

An Image cropper that is customizable

[![pub package](https://img.shields.io/pub/v/custom_image_crop.svg)](https://pub.dartlang.org/packages/custom_image_crop)
[![Build Status](https://app.travis-ci.com/icapps/flutter-custom-image-crop.svg?branch=main)](https://app.travis-ci.com/icapps/flutter-custom-image-crop)
[![Coverage Status](https://coveralls.io/repos/github/icapps/flutter-custom-image-crop/badge.svg?branch=main)](https://coveralls.io/github/icapps/flutter-custom-image-crop?branch=main)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

<img src="https://github.com/icapps/flutter-custom-image-crop/blob/main/example/screenshots/customimagecrop.gif?raw=true" alt="customcropcircle" height="320"/> <img src="https://github.com/icapps/flutter-custom-image-crop/blob/main/example/screenshots/customcropsquare.png?raw=true" alt="customcropsquare" height="320"/> <img src="https://github.com/icapps/flutter-custom-image-crop/blob/main/example/screenshots/customcropcircle.png?raw=true" alt="customcropcircle" height="320"/>

# CustomImageCrop

```
CustomImageCrop(
  cropController: controller,
  image: const AssetImage('assets/test.png'),
),
```

You can provide the image using any Imageprovider.

## Parameters

### required image
The image that needs to be cropped

### cropController
The controller used to adjust the image and crop it.

### overlayColor
The color above the image that will be cropped

### backgroundColor
The color behind the image. This color will also be used when there are gaps/empty space after the cropping

### shape
The shape of the cropping path.

### cropPercentage
How big the crop should be in regards to the width and height available to the cropping widget.

### drawPath
How the border of the crop should be painted. default DottedCropPathPainter.drawPath and SolidCropPathPainter.drawPath are provided, but you can create/provide any CustomPaint.

# Controller Methods

## addTransition

`void addTransition(CropImageData transition)`

Add the position, angle and scale to the current state. This can be used to adjust the image with sliders, buttons, etc.

## setData

`void setData(CropImageData data)`

Set the position, angle and scale to the specified values. This can be used to center the image by pressing a button for example.

## reset
`void reset()`

Reset the image to its default state

## onCropImage
`Future<MemoryImage> onCropImage()`

Crops the image in its current state, this will return a MemoryImage that contains the cropped image

# Example

See example/lib

```
class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CustomImageCropController controller;

  @override
  void initState() {
    super.initState();
    controller = CustomImageCropController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        brightness: Brightness.dark,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomImageCrop(
              cropController: controller,
              image: const AssetImage('assets/test.png'), // Any Imageprovider will work, try with a NetworkImage for example...
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: controller.reset),
              IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => controller.addTransition(CropImageData(scale: 1.33))),
              IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => controller.addTransition(CropImageData(scale: 0.75))),
              IconButton(icon: const Icon(Icons.rotate_left), onPressed: () => controller.addTransition(CropImageData(angle: -pi / 4))),
              IconButton(icon: const Icon(Icons.rotate_right), onPressed: () => controller.addTransition(CropImageData(angle: pi / 4))),
              IconButton(
                icon: const Icon(Icons.crop),
                onPressed: () async {
                  final image = await controller.onCropImage();
                  if (image != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ResultScreen(image: image)));
                  }
                },
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
```

<!-- deploy-notice:start v1 (from andhika-sudarman/infra gates/deploy-notice/section.md; change it there, not here) -->
## Before you deploy or release: Claude (F) deploys this repo too

People and the owner's Claude workers (F) both deploy and release `Sejutacita/flutter-custom-image-crop`. Before any staging or production
step (a release branch cut, a cherry-pick onto a release branch, a tag or GitHub release, an image tag change, a
production deploy, a migration, an Unleash flag switch), check what is already in flight, so neither side overwrites
the other:

1. **This repo:** the open PRs into `dev`, the staging build branches (`dev-*`, `dev_*`) and any release or hotfix branch, the newest merges and pushes there, and the newest tag or GitHub
   release.
2. **What runs now:** the newest Firebase App Distribution and TestFlight builds, and the store release in progress (Google Play Console, App Store Connect). Never upload a build number at or below one already uploaded.
3. **F's deploys:** the Board log (tab `Board log` of the CDA sheet, https://docs.google.com/spreadsheets/d/1rBHMmdFGxjw-hKN5PtktbhCMmO_OL8-rQ5tqHAQ5Pzw): the lines that start with
   `Deploy: Sejutacita/flutter-custom-image-crop` or `Release train: flutter-custom-image-crop` in the last 24 hours. No access to the sheet: ask in your PR,
   and a Claude session can read it for you.

Then:

- The commit you deploy must contain every change already live or queued for that environment: the commit live now,
  the commit of any deploy in flight and the head of the release branch it goes out from.
  `git merge-base --is-ancestor <that sha> <your sha>` must succeed for each; a newer build that lacks one of them
  drops that change. If it fails, merge that sha into yours (not a cherry-pick: a cherry-pick makes a new sha, so the
  check would still fail). A change that came in by cherry-pick or squash already passes when
  `git cherry <your sha> <that sha>` prints no `+` line; a squash of several commits, which `git cherry` cannot match:
  name in the PR each `+` commit and the commit of yours that holds its change. Two exceptions, each said in the PR:
  a planned rollback, and a hotfix. A hotfix contains the commit production runs, not a release in flight (it
  branches from that commit and carries only its fix); on staging it may go over a release line in flight, whose
  owner is told in the hotfix PR and deploys that line again after.
- Never skip or reorder a migration. If a release in flight adds one, yours goes after it, with it applied.
- Never switch an Unleash flag that another release in flight depends on.
- Another deploy of this repo in flight (started, not yet live and checked): start yours after it is live, or agree
  the order in its PR.
- Say in your PR who deploys it, with one line: `Deploys: <name, or F (Claude)> · <staging or production> · <tag or
  sha>`.

F writes one Board log line for each deploy it makes:
`Deploy: Sejutacita/flutter-custom-image-crop <env> <tag> sha <commit link> at <yyyy-mm-dd hh:mm> WIB`.
<!-- deploy-notice:end -->
