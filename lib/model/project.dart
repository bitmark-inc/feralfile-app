class ProjectInfo {
  final String title;
  final String route;
  final dynamic delegate;
  final dynamic arguments;

  ProjectInfo({
    required this.title,
    required this.route,
    required this.delegate,
    this.arguments,
  });
}
