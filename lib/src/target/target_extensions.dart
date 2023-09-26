abstract class PreActionTarget {
  Future<void> Function()? pre;
}

abstract class PostActionTarget {
  Future<void> Function()? post;
}
