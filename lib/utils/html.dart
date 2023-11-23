abstract class IFrameElement {
  IFrameElement()
      : src = '',
        style = CssStyleDeclaration();

  String src;
  CssStyleDeclaration style;
  String? allow;
  ElementStream<Event> get onLoad;
  ElementStream<Event> get onLoadedData;
  ElementStream<Event> get onLoadedMetadata;
}

class Event {}

abstract class ElementStream<T extends Event> implements Stream<T> {}

class CssStyleDeclaration {
  String border;
  String width;
  String height;
  CssStyleDeclaration({
    this.border = '',
    this.width = '',
    this.height = '',
  });
}

class PlatformViewRegistry {
  void registerViewFactory(
    String id,
    IFrameElement Function(int id) callBack,
  ) {}
}

final platformViewRegistry = PlatformViewRegistry();
