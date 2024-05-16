class DeleteModel {
  late final String installationUUID;

  DeleteModel({required this.installationUUID});

  Map<String, String> toJson() {
    return {
      'installationUUID': installationUUID,
    };
  }
}