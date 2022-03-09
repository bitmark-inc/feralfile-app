class BackupVersions {
  BackupVersions({
    required this.versions,
  });

  List<dynamic> versions;

  factory BackupVersions.fromJson(Map<String, dynamic> json) => BackupVersions(
        versions: json["result"],
      );

  Map<String, dynamic> toJson() => {"result": versions};
}
