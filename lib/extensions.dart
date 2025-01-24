
extension MopeString on String {
  String truncate(int maxCharacters) {
    return length > maxCharacters ? "${substring(0,maxCharacters-3)}..." : this;
  }
}
